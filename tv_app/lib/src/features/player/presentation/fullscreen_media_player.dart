import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

import '../../schedule/domain/media.dart';
import '../../schedule/domain/playable_media.dart';

import '../application/playback_log_provider.dart';
import '../domain/playback_log.dart';
import '../../device/application/device_reset_provider.dart';

class FullscreenMediaPlayer extends ConsumerStatefulWidget {
  const FullscreenMediaPlayer({super.key, required this.playlist});

  final List<PlayableMedia> playlist;

  @override
  ConsumerState<FullscreenMediaPlayer> createState() =>
      _FullscreenMediaPlayerState();
}

class _FullscreenMediaPlayerState extends ConsumerState<FullscreenMediaPlayer> {
  late final FocusNode _focusNode;
  int _pressOneCount = 0;
  DateTime? _lastPressOneAt;

  int _currentIndex = 0;
  Timer? _imageTimer;
  VideoPlayerController? _videoController;
  PlaybackLog? _currentLog;
  bool _isChangingMedia = false;

  PlayableMedia get _currentMedia => widget.playlist[_currentIndex];

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _playCurrentMedia();
  }

  @override
  void didUpdateWidget(covariant FullscreenMediaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.playlist != widget.playlist) {
      _currentIndex = 0;
      _playCurrentMedia();
    }
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _videoController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _playCurrentMedia() async {
    if (_isChangingMedia) return;

    _isChangingMedia = true;

    _imageTimer?.cancel();
    await _videoController?.dispose();
    _videoController = null;

    final playableMedia = _currentMedia;
    final media = playableMedia.media;

    final logRepository = ref.read(playbackLogRepositoryProvider);

    _currentLog = await logRepository.startLog(
      scheduleId: playableMedia.scheduleId,
      mediaId: media.id,
    );
    try {
      if (media.fileType == MediaType.image) {
        _playImage(playableMedia.duration);
        setState(() {});
        return;
      }

      if (media.fileType == MediaType.video) {
        await _playVideo(media.filePath);
        return;
      }
      await _markCurrentLogFailed('Unsupported media type');
      _goToNextMedia();
    } catch (error) {
      await _markCurrentLogFailed(error.toString());
      _goToNextMedia();
    } finally {
      _isChangingMedia = false;
    }
  }

  void _playImage(int durationSeconds) {
    _imageTimer = Timer(Duration(seconds: durationSeconds), () async {
      await _markCurrentLogCompleted();
      _goToNextMedia();
    });
  }

  Future<void> _playVideo(String path) async {
    final controller = VideoPlayerController.asset(path);

    _videoController = controller;

    await controller.initialize();
    await controller.setLooping(false);
    await controller.play();

    controller.addListener(() async {
      final value = controller.value;

      if (!value.isInitialized) return;

      final isEnded = value.position >= value.duration;

      if (isEnded && _currentLog != null) {
        await _markCurrentLogCompleted();
        _goToNextMedia();
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _markCurrentLogCompleted() async {
    final log = _currentLog;

    if (log == null) return;

    final logRepository = ref.read(playbackLogRepositoryProvider);

    await logRepository.completeLog(log);

    _currentLog = null;
  }

  Future<void> _markCurrentLogFailed(String errorMessage) async {
    final log = _currentLog;

    if (log == null) return;

    final logRepository = ref.read(playbackLogRepositoryProvider);

    await logRepository.failLog(log: log, errorMessage: errorMessage);

    _currentLog = null;
  }

  void _goToNextMedia() {
    if (!mounted) return;

    _imageTimer?.cancel();

    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.playlist.length;
    });

    _playCurrentMedia();
  }

  Future<void> _showResetConfirmDialog() async {
    _imageTimer?.cancel();
    await _videoController?.pause();

    if (!mounted) return;

    final shouldReset = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text(
            'Đặt lại thiết bị?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Thiết bị đã bị đăng xuất và quay lại màn hình đăng ký. Bạn có chắc không?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Đặt lại'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      final resetService = ref.read(deviceResetProvider);
      await resetService.resetDevice();
      return;
    }

    await _resumeCurrentMedia();
  }

  Future<void> _resumeCurrentMedia() async {
    final media = _currentMedia.media;

    if (media.fileType == MediaType.video) {
      await _videoController?.play();
      return;
    }

    if (media.fileType == MediaType.image) {
      _playImage(_currentMedia.duration);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final isNumberOne =
        event.logicalKey == LogicalKeyboardKey.digit1 ||
        event.logicalKey == LogicalKeyboardKey.numpad1;

    if (!isNumberOne) return;

    final now = DateTime.now();

    if (_lastPressOneAt == null ||
        now.difference(_lastPressOneAt!).inSeconds > 5) {
      _pressOneCount = 1;
    } else {
      _pressOneCount++;
    }

    _lastPressOneAt = now;

    if (_pressOneCount >= 10) {
      _pressOneCount = 0;
      _showResetConfirmDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = _currentMedia.media;
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.expand(child: _buildMediaView(media)),
      ),
    );
  }

  Widget _buildMediaView(Media media) {
    switch (media.fileType) {
      case MediaType.image:
        return Image.asset(
          media.filePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            _markCurrentLogFailed(error.toString());
            return _buildErrorView('Không thể hiển thị hình ảnh');
          },
        );

      case MediaType.video:
        final controller = _videoController;

        if (controller == null || !controller.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        );

      case MediaType.url:
        return _buildUnsupportedView('Url/WebView sẽ làm sau');

      case MediaType.music:
        return _buildUnsupportedView('Music sẽ làm sau');
    }
  }

  Widget _buildUnsupportedView(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 28),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent, fontSize: 28),
      ),
    );
  }
}
