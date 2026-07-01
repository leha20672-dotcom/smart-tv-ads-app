import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../device/application/device_provider.dart';
import '../../device/application/heartbeat_provider.dart';
import '../../schedule/application/schedule_provider.dart';
import '../../schedule/domain/playable_media.dart';
import '../application/playback_log_provider.dart';
import 'fullscreen_media_player.dart';
import 'idle_clock_screen.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  Timer? _scheduleRefreshTimer;
  Timer? _logRetryTimer;
  bool _heartbeatStarted = false;
  bool _isConfiguringScheduleRefresh = false;
  bool _isRetryingLogs = false;
  Duration? _scheduleRefreshInterval;
  Duration _lastServerClockOffset = Duration.zero;
  List<PlayableMedia>? _lastPlaylist;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startHeartbeat();
      _configureScheduleRefresh();
      _startLogRetryTimer();
      _retryPendingLogs();
    });
  }

  @override
  void dispose() {
    _scheduleRefreshTimer?.cancel();
    _logRetryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlistAsync = ref.watch(currentPlaylistProvider);
    final latestPlaylist = playlistAsync.valueOrNull;
    if (latestPlaylist != null) {
      _lastPlaylist = latestPlaylist;
    }

    final offsetAsync = ref.watch(serverClockOffsetProvider);
    final latestServerClockOffset = offsetAsync.valueOrNull;
    if (latestServerClockOffset != null) {
      _lastServerClockOffset = latestServerClockOffset;
    }

    final playlist = latestPlaylist ?? _lastPlaylist;

    return PopScope(
      canPop: false,
      child: _buildPlayerState(
        playlist: playlist,
        isInitialLoading: playlist == null && playlistAsync.isLoading,
        error: playlist == null ? playlistAsync.error : null,
      ),
    );
  }

  Widget _buildPlayerState({
    required List<PlayableMedia>? playlist,
    required bool isInitialLoading,
    required Object? error,
  }) {
    if (isInitialLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (playlist == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Lỗi load lịch phát\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      );
    }

    if (playlist.isEmpty) {
      return const IdleClockScreen();
    }

    return FullscreenMediaPlayer(
      playlist: playlist,
      serverClockOffset: _lastServerClockOffset,
    );
  }

  Future<void> _startHeartbeat() async {
    if (_heartbeatStarted) return;

    _heartbeatStarted = true;

    final deviceToken = await ref
        .read(deviceRepositoryProvider)
        .getDeviceToken();

    if (!mounted || deviceToken == null || deviceToken.isEmpty) return;

    ref
        .read(
          heartbeatTimerProvider(
            HeartbeatTimerParams(deviceToken: deviceToken),
          ),
        )
        .start();
  }

  Future<void> _configureScheduleRefresh() async {
    if (_isConfiguringScheduleRefresh) return;

    _isConfiguringScheduleRefresh = true;

    try {
      final interval = await ref.read(scheduleRefreshIntervalProvider.future);

      if (!mounted) return;

      if (_scheduleRefreshTimer != null &&
          _scheduleRefreshInterval == interval) {
        return;
      }

      _scheduleRefreshInterval = interval;
      _scheduleRefreshTimer?.cancel();
      _scheduleRefreshTimer = Timer.periodic(interval, (_) {
        _syncScheduleAndLogs();
      });
    } finally {
      _isConfiguringScheduleRefresh = false;
    }
  }

  void _syncScheduleAndLogs() {
    ref.invalidate(currentPlaylistProvider);
    ref.invalidate(scheduleRefreshIntervalProvider);
    ref.invalidate(serverClockOffsetProvider);
    _configureScheduleRefresh();
    _retryPendingLogs();
  }

  void _startLogRetryTimer() {
    _logRetryTimer?.cancel();
    _logRetryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _retryPendingLogs();
    });
  }

  Future<void> _retryPendingLogs() async {
    if (_isRetryingLogs) return;

    _isRetryingLogs = true;

    try {
      await ref.read(playbackLogRepositoryProvider).retryPendingLogs();
      ref.invalidate(playbackLogsProvider);
    } finally {
      _isRetryingLogs = false;
    }
  }
}
