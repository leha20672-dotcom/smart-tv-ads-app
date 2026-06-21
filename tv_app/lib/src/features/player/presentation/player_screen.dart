import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../../device/application/device_provider.dart';
import '../../device/application/heartbeat_provider.dart';
import '../../schedule/application/schedule_provider.dart';
import 'fullscreen_media_player.dart';
import 'idle_clock_screen.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.deviceId});

  final int deviceId;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _heartbeatStarted = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startHeartbeat();
    });
  }

  Future<void> _startHeartbeat() async {
    if (_heartbeatStarted) return;

    _heartbeatStarted = true;

    final deviceRepository = ref.read(deviceRepositoryProvider);
    final authRepository = ref.read(authRepositoryProvider);
    final deviceCode = await deviceRepository.getDeviceCode();
    final apiToken = await authRepository.getToken();

    if (!mounted) return;

    ref
        .read(
          heartbeatTimerProvider(
            HeartbeatTimerParams(
              deviceId: widget.deviceId,
              deviceToken: deviceCode ?? '${widget.deviceId}',
              apiToken: apiToken,
            ),
          ),
        )
        .start();
  }

  @override
  Widget build(BuildContext context) {
    final playlistAsync = ref.watch(currentPlaylistProvider(widget.deviceId));

    return PopScope(
      canPop: false,
      child: playlistAsync.when(
        loading: () => const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Text(
              'Lỗi load lịch phát\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
        ),
        data: (playlist) {
          if (playlist.isEmpty) {
            return const IdleClockScreen();
          }

          return FullscreenMediaPlayer(playlist: playlist);
        },
      ),
    );
  }
}
