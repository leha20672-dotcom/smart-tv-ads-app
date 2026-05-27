import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/player_controller.dart';
import 'widgets/registration_panel.dart';
import 'widgets/tv_video_player.dart';

class TvHomeScreen extends ConsumerWidget {
  const TvHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);

    return Scaffold(
      body: state.when(
        loading: () => const _StatusView(message: 'Dang tai cau hinh TV...'),
        error: (error, stackTrace) => _StatusView(message: error.toString()),
        data: (data) {
          if (!data.isRegistered) {
            return RegistrationPanel(
              initialBaseUrl: data.baseUrl,
              message: data.message,
            );
          }

          final currentItem = data.currentItem;

          if (currentItem == null) {
            return _StatusView(
              message: data.message ?? 'TV da dang ky. Dang cho playlist...',
              actionLabel: 'Dong bo lai',
              onAction: () => ref
                  .read(playerControllerProvider.notifier)
                  .refreshPlaylist(),
            );
          }

          return TvVideoPlayer(item: currentItem);
        },
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tv, size: 72, color: Color(0xff22d3ee)),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.sync),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
