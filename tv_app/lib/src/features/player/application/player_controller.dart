import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/storage_keys.dart';
import '../../device/data/device_api.dart';
import '../../playlist/data/playlist_api.dart';
import '../../playlist/data/playlist_cache_service.dart';
import '../../playlist/data/video_download_service.dart';
import '../../playlist/domain/playlist.dart';
import '../data/tv_socket_service.dart';

final playerControllerProvider =
    AsyncNotifierProvider<PlayerController, PlayerState>(PlayerController.new);

class PlayerState {
  const PlayerState({
    required this.baseUrl,
    this.deviceCode,
    this.deviceName,
    this.playlist,
    this.currentIndex = 0,
    this.message,
  });

  final String baseUrl;
  final String? deviceCode;
  final String? deviceName;
  final Playlist? playlist;
  final int currentIndex;
  final String? message;

  bool get isRegistered => deviceCode != null && deviceCode!.isNotEmpty;

  PlaylistItem? get currentItem {
    final items = playlist?.items ?? const [];
    if (items.isEmpty) {
      return null;
    }

    return items[currentIndex % items.length];
  }

  PlayerState copyWith({
    String? baseUrl,
    String? deviceCode,
    String? deviceName,
    Playlist? playlist,
    int? currentIndex,
    String? message,
    bool clearPlaylist = false,
  }) {
    return PlayerState(
      baseUrl: baseUrl ?? this.baseUrl,
      deviceCode: deviceCode ?? this.deviceCode,
      deviceName: deviceName ?? this.deviceName,
      playlist: clearPlaylist ? null : playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      message: message,
    );
  }
}

class PlayerController extends AsyncNotifier<PlayerState> {
  Timer? _heartbeatTimer;
  final TvSocketService _socketService = TvSocketService();

  @override
  Future<PlayerState> build() async {
    ref.onDispose(() {
      _heartbeatTimer?.cancel();
      _socketService.disconnect();
    });

    final storage = ref.read(storageProvider);
    final baseUrl = ref.read(baseUrlProvider);
    final deviceCode = storage.getString(StorageKeys.deviceCode);
    final deviceName = storage.getString(StorageKeys.deviceName);

    final initialState = PlayerState(
      baseUrl: baseUrl,
      deviceCode: deviceCode,
      deviceName: deviceName,
    );

    if (deviceCode == null || deviceCode.isEmpty) {
      return initialState;
    }

    _startHeartbeat(deviceCode);
    _connectSocket(baseUrl: baseUrl, deviceCode: deviceCode);

    try {
      final playlist = await _syncAndCachePlaylist(
        deviceCode: deviceCode,
        baseUrl: baseUrl,
      );

      return initialState.copyWith(
        playlist: playlist,
        message: playlist == null ? 'Chua gan playlist cho TV nay' : null,
      );
    } catch (_) {
      final cachedPlaylist = _getCachedPlaylist();

      return initialState.copyWith(
        playlist: cachedPlaylist,
        message: cachedPlaylist == null
            ? 'Khong ket noi duoc server. Chua co cache offline.'
            : 'Dang phat playlist cache offline.',
      );
    }
  }

  Future<void> register({
    required String baseUrl,
    required String deviceCode,
    required String deviceName,
  }) async {
    final cleanBaseUrl = baseUrl.trim().replaceAll(RegExp(r'/$'), '');
    final cleanDeviceCode = deviceCode.trim();
    final cleanDeviceName = deviceName.trim();

    state = const AsyncLoading();

    ref.read(baseUrlProvider.notifier).state = cleanBaseUrl;

    try {
      await DeviceApi(ref.read(dioProvider)).registerDevice(
        deviceCode: cleanDeviceCode,
        deviceName: cleanDeviceName,
      );

      final storage = ref.read(storageProvider);
      await storage.setString(StorageKeys.baseUrl, cleanBaseUrl);
      await storage.setString(StorageKeys.deviceCode, cleanDeviceCode);
      await storage.setString(StorageKeys.deviceName, cleanDeviceName);

      _startHeartbeat(cleanDeviceCode);
      _connectSocket(baseUrl: cleanBaseUrl, deviceCode: cleanDeviceCode);

      final playlist = await _syncAndCachePlaylist(
        deviceCode: cleanDeviceCode,
        baseUrl: cleanBaseUrl,
      );

      state = AsyncData(
        PlayerState(
          baseUrl: cleanBaseUrl,
          deviceCode: cleanDeviceCode,
          deviceName: cleanDeviceName,
          playlist: playlist,
          message:
              playlist == null ? 'Dang ky thanh cong. Chua co playlist.' : null,
        ),
      );
    } catch (_) {
      state = AsyncData(
        PlayerState(
          baseUrl: cleanBaseUrl,
          message: 'Dang ky that bai. Kiem tra server va ma thiet bi.',
        ),
      );
    }
  }

  Future<void> refreshPlaylist() async {
    final value = state.valueOrNull;
    final deviceCode = value?.deviceCode;

    if (value == null || deviceCode == null) {
      return;
    }

    state = const AsyncLoading();

    try {
      final playlist = await _syncAndCachePlaylist(
        deviceCode: deviceCode,
        baseUrl: value.baseUrl,
      );

      state = AsyncData(
        value.copyWith(
          playlist: playlist,
          currentIndex: 0,
          message: playlist == null ? 'Chua gan playlist cho TV nay' : null,
          clearPlaylist: playlist == null,
        ),
      );
    } catch (_) {
      final cachedPlaylist = _getCachedPlaylist();

      state = AsyncData(
        value.copyWith(
          playlist: cachedPlaylist,
          message: cachedPlaylist == null
              ? 'Khong dong bo duoc playlist va chua co cache.'
              : 'Mat ket noi server. Dang phat cache offline.',
          clearPlaylist: cachedPlaylist == null,
        ),
      );
    }
  }

  void playNext() {
    final value = state.valueOrNull;
    final items = value?.playlist?.items ?? const [];

    if (value == null || items.isEmpty) {
      return;
    }

    state = AsyncData(
      value.copyWith(
        currentIndex: (value.currentIndex + 1) % items.length,
        message: null,
      ),
    );
  }

  String resolveMediaUrl(String fileUrl) {
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }

    final value = state.valueOrNull;
    final baseUrl = value?.baseUrl ?? ref.read(baseUrlProvider);

    return '$baseUrl$fileUrl';
  }

  Future<Playlist?> _syncAndCachePlaylist({
    required String deviceCode,
    required String baseUrl,
  }) async {
    final playlist =
        await PlaylistApi(ref.read(dioProvider)).getAssignedPlaylist(deviceCode);

    if (playlist == null) {
      return null;
    }

    final downloadedPlaylist = await VideoDownloadService(ref.read(dioProvider))
        .downloadPlaylistVideos(
      playlist: playlist,
      baseUrl: baseUrl,
    );

    await PlaylistCacheService(ref.read(storageProvider))
        .savePlaylist(downloadedPlaylist);

    return downloadedPlaylist;
  }

  Playlist? _getCachedPlaylist() {
    return PlaylistCacheService(ref.read(storageProvider)).getCachedPlaylist();
  }

  void _startHeartbeat(String deviceCode) {
    _heartbeatTimer?.cancel();
    DeviceApi(ref.read(dioProvider)).sendHeartbeat(deviceCode).catchError(
          (_) {},
        );

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      DeviceApi(ref.read(dioProvider)).sendHeartbeat(deviceCode).catchError(
            (_) {},
          );
    });
  }

  void _connectSocket({
    required String baseUrl,
    required String deviceCode,
  }) {
    _socketService.connect(
      baseUrl: baseUrl,
      deviceCode: deviceCode,
      onPlaylistUpdated: () {
        refreshPlaylist();
      },
    );
  }
}
