import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../schedule/application/schedule_provider.dart';
import 'fullscreen_media_player.dart';
import 'idle_clock_screen.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key, required this.deviceId});

  final int deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(currentPlaylistProvider(deviceId));
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
