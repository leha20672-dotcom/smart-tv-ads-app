import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../playlist/domain/playlist.dart';
import '../../application/player_controller.dart';

class TvVideoPlayer extends ConsumerStatefulWidget {
  const TvVideoPlayer({
    required this.item,
    super.key,
  });

  final PlaylistItem item;

  @override
  ConsumerState<TvVideoPlayer> createState() => _TvVideoPlayerState();
}

class _TvVideoPlayerState extends ConsumerState<TvVideoPlayer> {
  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void didUpdateWidget(covariant TvVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.item.media.id != widget.item.media.id) {
      _loadVideo();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    setState(() => _hasError = false);

    final oldController = _controller;
    _controller = null;
    await oldController?.dispose();

    final localPath = widget.item.media.localPath;
    final hasLocalFile = localPath != null && File(localPath).existsSync();

    final controller = hasLocalFile
        ? VideoPlayerController.file(File(localPath!))
        : VideoPlayerController.networkUrl(
            Uri.parse(
              ref
                  .read(playerControllerProvider.notifier)
                  .resolveMediaUrl(widget.item.media.fileUrl),
            ),
          );
    _controller = controller;

    try {
      await controller.initialize();
      controller
        ..setLooping(false)
        ..play();

      controller.addListener(_handleVideoTick);

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _handleVideoTick() {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final position = controller.value.position;
    final duration = controller.value.duration;

    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 300)) {
      controller.removeListener(_handleVideoTick);
      ref.read(playerControllerProvider.notifier).playNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (_hasError) {
      return _VideoStatus(
        title: 'Khong phat duoc video',
        subtitle: widget.item.media.originalName,
        onRetry: _loadVideo,
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return _VideoStatus(
        title: 'Dang tai video...',
        subtitle: widget.item.media.originalName,
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

class _VideoStatus extends StatelessWidget {
  const _VideoStatus({
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(subtitle),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thu lai'),
            ),
          ],
        ],
      ),
    );
  }
}
