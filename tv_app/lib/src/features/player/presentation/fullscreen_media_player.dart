import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../device/application/device_provider.dart';
import '../../device/application/device_reset_provider.dart';
import '../../schedule/domain/media.dart';
import '../../schedule/domain/playable_media.dart';
import '../application/playback_log_provider.dart';
import '../domain/playback_log.dart';
import 'idle_clock_screen.dart';

class FullscreenMediaPlayer extends ConsumerStatefulWidget {
  const FullscreenMediaPlayer({
    super.key,
    required this.playlist,
    this.serverClockOffset = Duration.zero,
  });

  final List<PlayableMedia> playlist;
  final Duration serverClockOffset;

  @override
  ConsumerState<FullscreenMediaPlayer> createState() =>
      _FullscreenMediaPlayerState();
}

class _FullscreenMediaPlayerState extends ConsumerState<FullscreenMediaPlayer> {
  late final FocusNode _focusNode;
  int _pressOneCount = 0;
  DateTime? _lastPressOneAt;

  int _currentIndex = 0;
  Timer? _mediaTimer;
  Timer? _timelineTimer;
  VideoPlayerController? _videoController;
  WebViewController? _webViewController;
  int _webLoadProgress = 0;
  String? _webErrorText;
  String? _mediaErrorText;
  PlaybackLog? _currentLog;
  bool _isChangingMedia = false;
  bool _isSyncingTimeline = false;
  bool _isTimelineIdle = false;
  String? _currentSlotKey;
  int _playbackGeneration = 0;
  int? _handledMediaErrorGeneration;
  String? _apiToken;
  final Set<String> _failedSlotKeys = <String>{};

  PlayableMedia get _currentMedia => widget.playlist[_currentIndex];

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    if (_usesSyncedTimeline) {
      _isTimelineIdle = true;
      _startTimelineSync();
    } else {
      _playCurrentMedia();
    }
  }

  @override
  void didUpdateWidget(covariant FullscreenMediaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final playlistChanged =
        _playlistSignature(oldWidget.playlist) !=
        _playlistSignature(widget.playlist);
    final timelineModeChanged =
        _usesSyncedTimelineFor(oldWidget.playlist) != _usesSyncedTimeline;
    final clockOffsetChanged =
        oldWidget.serverClockOffset != widget.serverClockOffset;

    if (playlistChanged || timelineModeChanged) {
      Future.microtask(() async {
        _timelineTimer?.cancel();
        await _resetPlayback(markCompleted: true);
        _failedSlotKeys.clear();

        if (!mounted || widget.playlist.isEmpty) return;

        if (_usesSyncedTimeline) {
          setState(() {
            _isTimelineIdle = true;
          });
          _startTimelineSync();
        } else {
          _currentIndex = 0;
          await _playCurrentMedia();
        }
      });
      return;
    }

    if (clockOffsetChanged && _usesSyncedTimeline) {
      Future.microtask(_syncToTimeline);
    }
  }

  @override
  void dispose() {
    _mediaTimer?.cancel();
    _timelineTimer?.cancel();
    _videoController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _playCurrentMedia({
    Duration startOffset = Duration.zero,
    DateTime? slotEndAtServer,
  }) async {
    if (_isChangingMedia || widget.playlist.isEmpty) return;

    _isChangingMedia = true;
    final generation = _nextPlaybackGeneration();

    _mediaTimer?.cancel();
    await _videoController?.dispose();
    _videoController = null;
    _webViewController = null;
    _webLoadProgress = 0;
    _webErrorText = null;
    _mediaErrorText = null;
    _handledMediaErrorGeneration = null;
    _apiToken ??= await ref.read(deviceRepositoryProvider).getDeviceToken();

    final playableMedia = _currentMedia;
    final media = playableMedia.media;
    final logRepository = ref.read(playbackLogRepositoryProvider);

    final playbackLog = await logRepository.startLog(
      scheduleId: playableMedia.scheduleId,
      mediaId: media.id,
    );

    if (!_isActivePlayback(generation)) {
      await logRepository.failLog(
        log: playbackLog,
        errorMessage: 'Playback was superseded before media started.',
      );
      return;
    }

    _currentLog = playbackLog;

    try {
      switch (media.fileType) {
        case MediaType.image:
          _playTimedMedia(
            playableMedia.duration,
            slotEndAtServer: slotEndAtServer,
            generation: generation,
          );
          if (mounted) {
            setState(() {});
          }
          return;

        case MediaType.url:
          await _playUrl(
            media.filePath,
            playableMedia.duration,
            slotEndAtServer: slotEndAtServer,
            generation: generation,
          );
          return;

        case MediaType.video:
          await _playVideo(
            _playbackPath(media),
            startOffset: startOffset,
            slotEndAtServer: slotEndAtServer,
            generation: generation,
          );
          return;

        case MediaType.music:
          await _playMusic(
            _playbackPath(media),
            playableMedia.duration,
            startOffset: startOffset,
            slotEndAtServer: slotEndAtServer,
            generation: generation,
          );
          return;
      }
    } catch (error) {
      await _handleCurrentMediaFailure(error.toString(), generation);
    } finally {
      if (_isActivePlayback(generation)) {
        _isChangingMedia = false;
      }
    }
  }

  void _playTimedMedia(
    int durationSeconds, {
    DateTime? slotEndAtServer,
    int? generation,
  }) {
    final timerGeneration = generation ?? _playbackGeneration;
    final timerDuration = _timerDuration(
      durationSeconds: durationSeconds,
      slotEndAtServer: slotEndAtServer,
    );

    _mediaTimer = Timer(timerDuration, () async {
      if (!_isActivePlayback(timerGeneration)) return;

      await _markCurrentLogCompleted();
      if (_usesSyncedTimeline) {
        await _syncToTimeline();
      } else {
        _goToNextMedia();
      }
    });
  }

  Future<void> _playVideo(
    String path, {
    Duration startOffset = Duration.zero,
    DateTime? slotEndAtServer,
    required int generation,
  }) async {
    await _playControllerMedia(
      path,
      startOffset: startOffset,
      slotEndAtServer: slotEndAtServer,
      generation: generation,
    );
  }

  Future<void> _playMusic(
    String path,
    int fallbackDurationSeconds, {
    Duration startOffset = Duration.zero,
    DateTime? slotEndAtServer,
    required int generation,
  }) async {
    await _playControllerMedia(
      path,
      fallbackDurationSeconds: fallbackDurationSeconds,
      startOffset: startOffset,
      slotEndAtServer: slotEndAtServer,
      generation: generation,
    );
  }

  Future<void> _playControllerMedia(
    String path, {
    int? fallbackDurationSeconds,
    Duration startOffset = Duration.zero,
    DateTime? slotEndAtServer,
    required int generation,
  }) async {
    final controller = _videoControllerFor(path);

    _videoController = controller;

    await controller.initialize().timeout(const Duration(seconds: 8));
    if (!_isActivePlayback(generation) || _videoController != controller) {
      if (_videoController == controller) {
        await controller.dispose();
        _videoController = null;
      }
      return;
    }

    await _seekToTimelineOffset(controller, startOffset);
    if (!_isActivePlayback(generation) || _videoController != controller) {
      if (_videoController == controller) {
        await controller.dispose();
        _videoController = null;
      }
      return;
    }

    await controller.setLooping(false);
    await controller.play();

    var didComplete = false;

    controller.addListener(() async {
      if (!_isActivePlayback(generation) || _videoController != controller) {
        return;
      }

      final value = controller.value;

      if (!value.isInitialized || _currentLog == null || didComplete) return;
      if (value.duration == Duration.zero) return;

      final isEnded = value.position >= value.duration && !value.isPlaying;

      if (isEnded) {
        didComplete = true;
        await _markCurrentLogCompleted();
        if (!_usesSyncedTimeline) {
          _goToNextMedia();
        }
      }
    });

    if (_usesSyncedTimeline && slotEndAtServer != null) {
      _playTimedMedia(
        fallbackDurationSeconds ?? controller.value.duration.inSeconds,
        slotEndAtServer: slotEndAtServer,
        generation: generation,
      );
    } else if (controller.value.duration == Duration.zero &&
        fallbackDurationSeconds != null) {
      _playTimedMedia(fallbackDurationSeconds, generation: generation);
    }

    if (mounted && _isActivePlayback(generation)) {
      setState(() {});
    }
  }

  Future<void> _playUrl(
    String path,
    int durationSeconds, {
    DateTime? slotEndAtServer,
    required int generation,
  }) async {
    final uri = _parseWebUri(path);

    if (uri == null) {
      throw FormatException('Invalid URL: $path');
    }

    final controller = WebViewController();
    _webViewController = controller;

    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(Colors.black);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (progress) {
          if (!mounted ||
              !_isActivePlayback(generation) ||
              _webViewController != controller) {
            return;
          }

          setState(() {
            _webLoadProgress = progress;
          });
        },
        onPageFinished: (_) {
          if (!mounted ||
              !_isActivePlayback(generation) ||
              _webViewController != controller) {
            return;
          }

          setState(() {
            _webLoadProgress = 100;
          });
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == false) return;
          if (!mounted ||
              !_isActivePlayback(generation) ||
              _webViewController != controller) {
            return;
          }

          setState(() {
            _webErrorText = 'Không thể tải URL';
          });

          Future.microtask(() async {
            if (!_isActivePlayback(generation)) return;

            await _handleCurrentMediaFailure(error.description, generation);
          });
        },
      ),
    );
    await controller.loadRequest(uri);
    if (!_isActivePlayback(generation) || _webViewController != controller) {
      return;
    }

    _playTimedMedia(
      durationSeconds,
      slotEndAtServer: slotEndAtServer,
      generation: generation,
    );

    if (mounted && _isActivePlayback(generation)) {
      setState(() {});
    }
  }

  Future<void> _markCurrentLogCompleted() async {
    final log = _currentLog;

    if (log == null) return;

    _currentLog = null;

    final logRepository = ref.read(playbackLogRepositoryProvider);

    await logRepository.completeLog(log);
  }

  Future<void> _markCurrentLogFailed(String errorMessage) async {
    final log = _currentLog;

    if (log == null) return;

    _currentLog = null;

    final logRepository = ref.read(playbackLogRepositoryProvider);

    await logRepository.failLog(log: log, errorMessage: errorMessage);
  }

  void _goToNextMedia() {
    if (_usesSyncedTimeline) {
      Future.microtask(_syncToTimeline);
      return;
    }

    if (!mounted || widget.playlist.isEmpty) return;

    _mediaTimer?.cancel();

    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.playlist.length;
    });

    Future.microtask(_playCurrentMedia);
  }

  bool get _usesSyncedTimeline {
    return _usesSyncedTimelineFor(widget.playlist);
  }

  bool _usesSyncedTimelineFor(List<PlayableMedia> playlist) {
    return playlist.any((item) {
      return item.isSyncedTimeline &&
          item.timelineStartSecond != null &&
          item.timelineEndSecond != null &&
          item.scheduleStartDateTime != null;
    });
  }

  DateTime get _serverNow => DateTime.now().add(widget.serverClockOffset);

  void _startTimelineSync() {
    _timelineTimer?.cancel();
    _syncToTimeline();

    _timelineTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncToTimeline();
    });
  }

  Future<void> _syncToTimeline() async {
    if (!_usesSyncedTimeline ||
        widget.playlist.isEmpty ||
        _isChangingMedia ||
        _isSyncingTimeline) {
      return;
    }

    _isSyncingTimeline = true;

    try {
      final now = _serverNow;
      final activeIndex = _activeTimelineIndex(now);

      if (activeIndex == null) {
        await _showTimelineIdle(markCompleted: true);
        return;
      }

      final activeMedia = widget.playlist[activeIndex];
      final slotStartAt = _slotStartAt(activeMedia, now: now);
      final slotEndAt = _slotEndAt(activeMedia, now: now);

      if (slotStartAt == null || slotEndAt == null) {
        await _showTimelineIdle(markCompleted: true);
        return;
      }

      final slotKey = _slotKey(activeMedia, slotStartAt);

      if (_failedSlotKeys.contains(slotKey)) {
        if (!_isTimelineIdle || _currentSlotKey != slotKey) {
          await _showTimelineIdle(slotKey: slotKey, markCompleted: true);
        }
        return;
      }

      if (_currentSlotKey == slotKey && !_isTimelineIdle) {
        return;
      }

      await _resetPlayback(markCompleted: true);

      if (!mounted) return;

      setState(() {
        _currentIndex = activeIndex;
        _currentSlotKey = slotKey;
        _isTimelineIdle = false;
      });

      final startOffset = now.difference(slotStartAt);
      await _playCurrentMedia(
        startOffset: startOffset.isNegative ? Duration.zero : startOffset,
        slotEndAtServer: slotEndAt,
      );
    } finally {
      _isSyncingTimeline = false;
    }
  }

  int? _activeTimelineIndex(DateTime now) {
    for (var index = 0; index < widget.playlist.length; index++) {
      final media = widget.playlist[index];
      final slotStartAt = _slotStartAt(media, now: now);
      final slotEndAt = _slotEndAt(media, now: now);

      if (slotStartAt == null || slotEndAt == null) {
        continue;
      }

      if (!now.isBefore(slotStartAt) && now.isBefore(slotEndAt)) {
        return index;
      }
    }

    return null;
  }

  DateTime? _slotStartAt(PlayableMedia media, {DateTime? now}) {
    final loopedSlot = _loopedScheduleSlot(media, now ?? _serverNow);
    if (loopedSlot != null) {
      return loopedSlot.startAt;
    }

    final scheduleStartAt = _timelineBaseAt(media, now: now);
    final timelineStartSecond = media.timelineStartSecond;

    if (scheduleStartAt == null || timelineStartSecond == null) {
      return null;
    }

    return scheduleStartAt.add(Duration(seconds: timelineStartSecond));
  }

  DateTime? _slotEndAt(PlayableMedia media, {DateTime? now}) {
    final loopedSlot = _loopedScheduleSlot(media, now ?? _serverNow);
    if (loopedSlot != null) {
      return loopedSlot.endAt;
    }

    final scheduleStartAt = _timelineBaseAt(media, now: now);
    final timelineEndSecond = media.timelineEndSecond;

    if (scheduleStartAt == null || timelineEndSecond == null) {
      return null;
    }

    return scheduleStartAt.add(Duration(seconds: timelineEndSecond));
  }

  DateTime? _timelineBaseAt(PlayableMedia media, {DateTime? now}) {
    final scheduleStartAt = media.scheduleStartDateTime;
    if (scheduleStartAt == null) {
      return null;
    }

    final serverNow = now ?? _serverNow;
    var base = DateTime(
      serverNow.year,
      serverNow.month,
      serverNow.day,
      scheduleStartAt.hour,
      scheduleStartAt.minute,
      scheduleStartAt.second,
      scheduleStartAt.millisecond,
      scheduleStartAt.microsecond,
    );

    final scheduleEndAt = _scheduleWindowEndAtForBase(media, base);
    if (serverNow.isBefore(base) && scheduleEndAt != null) {
      final yesterdayBase = base.subtract(const Duration(days: 1));
      final yesterdayEndAt = _scheduleWindowEndAtForBase(media, yesterdayBase);

      if (yesterdayEndAt != null &&
          !serverNow.isBefore(yesterdayBase) &&
          serverNow.isBefore(yesterdayEndAt)) {
        base = yesterdayBase;
      }

      return base;
    }

    final timelineEndSecond = media.timelineEndSecond;
    if (serverNow.isBefore(base) && timelineEndSecond != null) {
      final yesterdayBase = base.subtract(const Duration(days: 1));
      final yesterdayEndAt = yesterdayBase.add(
        Duration(seconds: timelineEndSecond),
      );

      if (!serverNow.isBefore(yesterdayBase) &&
          serverNow.isBefore(yesterdayEndAt)) {
        base = yesterdayBase;
      }
    }

    return base;
  }

  _TimelineSlot? _loopedScheduleSlot(PlayableMedia media, DateTime now) {
    final base = _timelineBaseAt(media, now: now);
    final scheduleEndAt = _scheduleWindowEndAtForBase(media, base);
    final startSecond = media.timelineStartSecond;
    final endSecond = media.timelineEndSecond;
    final cycleDuration = _scheduleCycleDurationSeconds(media);

    if (base == null ||
        scheduleEndAt == null ||
        startSecond == null ||
        endSecond == null ||
        cycleDuration <= 0 ||
        !now.isBefore(scheduleEndAt) ||
        now.isBefore(base)) {
      return null;
    }

    final elapsedSeconds = now.difference(base).inSeconds;
    final cycleStartSecond = elapsedSeconds - (elapsedSeconds % cycleDuration);
    final positionInCycle = elapsedSeconds - cycleStartSecond;

    if (positionInCycle < startSecond || positionInCycle >= endSecond) {
      return null;
    }

    final slotStartAt = base.add(
      Duration(seconds: cycleStartSecond + startSecond),
    );
    var slotEndAt = base.add(Duration(seconds: cycleStartSecond + endSecond));

    if (slotEndAt.isAfter(scheduleEndAt)) {
      slotEndAt = scheduleEndAt;
    }

    return _TimelineSlot(startAt: slotStartAt, endAt: slotEndAt);
  }

  DateTime? _scheduleWindowEndAtForBase(
    PlayableMedia media,
    DateTime? scheduleBaseAt,
  ) {
    final scheduleEndAt = media.scheduleEndDateTime;

    if (scheduleBaseAt == null || scheduleEndAt == null) {
      return null;
    }

    var endAt = DateTime(
      scheduleBaseAt.year,
      scheduleBaseAt.month,
      scheduleBaseAt.day,
      scheduleEndAt.hour,
      scheduleEndAt.minute,
      scheduleEndAt.second,
      scheduleEndAt.millisecond,
      scheduleEndAt.microsecond,
    );

    if (!endAt.isAfter(scheduleBaseAt)) {
      endAt = endAt.add(const Duration(days: 1));
    }

    return endAt;
  }

  int _scheduleCycleDurationSeconds(PlayableMedia media) {
    var maxEndSecond = 0;

    for (final item in widget.playlist) {
      if (!_sameSchedule(item, media)) {
        continue;
      }

      final endSecond = item.timelineEndSecond ?? 0;
      if (endSecond > maxEndSecond) {
        maxEndSecond = endSecond;
      }
    }

    return maxEndSecond;
  }

  bool _sameSchedule(PlayableMedia a, PlayableMedia b) {
    return a.scheduleId == b.scheduleId &&
        a.scheduleStartAt == b.scheduleStartAt &&
        a.scheduleEndAt == b.scheduleEndAt;
  }

  String _slotKey(PlayableMedia media, DateTime slotStartAt) {
    return [
      media.scheduleId,
      media.media.id,
      media.timelineStartSecond,
      media.timelineEndSecond,
      media.scheduleStartAt,
      media.scheduleEndAt,
      slotStartAt.toIso8601String(),
    ].join(':');
  }

  String _playlistSignature(List<PlayableMedia> playlist) {
    return playlist
        .map((item) {
          final media = item.media;
          return [
            item.scheduleId,
            item.scheduleName,
            media.id,
            media.filePath,
            media.fileType.name,
            item.zoneName,
            item.playOrder,
            item.duration,
            item.timelineStartSecond,
            item.timelineEndSecond,
            item.scheduleStartAt,
            item.scheduleEndAt,
            item.isSyncedTimeline,
          ].join(',');
        })
        .join('|');
  }

  int _nextPlaybackGeneration() {
    _playbackGeneration++;
    return _playbackGeneration;
  }

  bool _isActivePlayback(int generation) {
    return mounted && generation == _playbackGeneration;
  }

  Future<void> _resetPlayback({required bool markCompleted}) async {
    _nextPlaybackGeneration();
    _isChangingMedia = false;
    _mediaTimer?.cancel();

    if (markCompleted) {
      await _markCurrentLogCompleted();
    }

    await _videoController?.dispose();
    _videoController = null;
    _webViewController = null;
    _webLoadProgress = 0;
    _webErrorText = null;
    _mediaErrorText = null;
    _currentSlotKey = null;
  }

  Future<void> _handleCurrentMediaFailure(
    String errorMessage,
    int generation,
  ) async {
    await _markCurrentLogFailed(errorMessage);

    if (!_isActivePlayback(generation)) {
      return;
    }

    await _videoController?.dispose();
    _videoController = null;
    _webViewController = null;
    _mediaErrorText = errorMessage;

    if (_usesSyncedTimeline) {
      _isChangingMedia = false;
      final slotEndAt = _slotEndAt(_currentMedia, now: _serverNow);

      if (mounted) {
        setState(() {
          _isTimelineIdle = false;
        });
      }

      _playTimedMedia(
        _currentMedia.duration,
        slotEndAtServer: slotEndAt,
        generation: generation,
      );
      return;
    }

    _goToNextMedia();
  }

  Future<void> _showTimelineIdle({
    String? slotKey,
    bool markCompleted = false,
  }) async {
    _nextPlaybackGeneration();
    _isChangingMedia = false;
    _mediaTimer?.cancel();

    if (markCompleted) {
      await _markCurrentLogCompleted();
    }

    await _videoController?.dispose();
    _videoController = null;
    _webViewController = null;
    _webLoadProgress = 0;
    _webErrorText = null;
    _mediaErrorText = null;

    if (!mounted) return;

    if (!_isTimelineIdle || _currentSlotKey != slotKey) {
      setState(() {
        _isTimelineIdle = true;
        _currentSlotKey = slotKey;
      });
    }
  }

  Duration _timerDuration({
    required int durationSeconds,
    DateTime? slotEndAtServer,
  }) {
    if (_usesSyncedTimeline && slotEndAtServer != null) {
      final remaining = slotEndAtServer.difference(_serverNow);
      if (remaining > const Duration(milliseconds: 250)) {
        return remaining;
      }

      return const Duration(milliseconds: 250);
    }

    final safeDuration = durationSeconds <= 0 ? 10 : durationSeconds;
    return Duration(seconds: safeDuration);
  }

  Future<void> _seekToTimelineOffset(
    VideoPlayerController controller,
    Duration startOffset,
  ) async {
    if (!_usesSyncedTimeline || startOffset <= Duration.zero) {
      return;
    }

    final duration = controller.value.duration;
    if (duration == Duration.zero) {
      return;
    }

    final maxSeek = duration > const Duration(milliseconds: 500)
        ? duration - const Duration(milliseconds: 500)
        : Duration.zero;
    final seekOffset = startOffset > maxSeek ? maxSeek : startOffset;

    if (seekOffset > Duration.zero) {
      await controller.seekTo(seekOffset);
    }
  }

  Future<void> _showResetConfirmDialog() async {
    _mediaTimer?.cancel();
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
            'Thiết bị sẽ đăng xuất và quay lại màn hình đăng ký. Bạn có chắc không?',
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

    if (_usesSyncedTimeline) {
      await _syncToTimeline();
    } else {
      await _resumeCurrentMedia();
    }
  }

  Future<void> _resumeCurrentMedia() async {
    final media = _currentMedia.media;

    if (media.fileType == MediaType.video ||
        media.fileType == MediaType.music) {
      await _videoController?.play();
      return;
    }

    if (media.fileType == MediaType.image || media.fileType == MediaType.url) {
      _playTimedMedia(_currentMedia.duration);
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
    if (_usesSyncedTimeline && _isTimelineIdle) {
      return const IdleClockScreen();
    }

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
    final mediaErrorText = _mediaErrorText;
    if (mediaErrorText != null && mediaErrorText.isNotEmpty) {
      return _buildErrorView('Không thể phát nội dung');
    }

    switch (media.fileType) {
      case MediaType.image:
        return _buildImage(_playbackPath(media));

      case MediaType.video:
        final controller = _videoController;

        if (controller == null || !controller.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        );

      case MediaType.url:
        return _buildUrlView(media.filePath);

      case MediaType.music:
        return _buildMusicView(media);
    }
  }

  Widget _buildImage(String path) {
    final image = _isNetworkSource(path)
        ? Image.network(
            path,
            fit: BoxFit.fill,
            headers: _authHeaders,
            errorBuilder: _imageError,
          )
        : _isFileSource(path)
        ? Image.file(
            _fileFromPath(path),
            fit: BoxFit.fill,
            errorBuilder: _imageError,
          )
        : Image.asset(path, fit: BoxFit.fill, errorBuilder: _imageError);

    return SizedBox.expand(child: image);
  }

  Widget _imageError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    final generation = _playbackGeneration;

    if (_handledMediaErrorGeneration != generation) {
      _handledMediaErrorGeneration = generation;
      Future.microtask(() async {
        await _handleCurrentMediaFailure(error.toString(), generation);
      });
    }

    return _buildErrorView('Không thể hiển thị hình ảnh');
  }

  Widget _buildUrlView(String _) {
    final controller = _webViewController;

    if (_webErrorText != null) {
      return _buildErrorView(_webErrorText!);
    }

    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(child: WebViewWidget(controller: controller)),
          if (_webLoadProgress > 0 && _webLoadProgress < 100)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(value: _webLoadProgress / 100),
            ),
        ],
      ),
    );
  }

  Widget _buildMusicView(Media media) {
    final controller = _videoController;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.music_note, color: Colors.white, size: 96),
              const SizedBox(height: 24),
              Text(
                media.name.isEmpty ? 'Đang phát âm thanh' : media.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 28),
              if (controller == null || !controller.value.isInitialized)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: 360,
                  child: ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: _playbackProgress(value),
                        minHeight: 6,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
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

  bool _isNetworkSource(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  String _playbackPath(Media media) {
    final localFilePath = media.localFilePath;

    if (localFilePath != null && localFilePath.isNotEmpty) {
      final localFile = _fileFromPath(localFilePath);
      if (localFile.existsSync()) {
        return localFile.path;
      }
    }

    return media.filePath;
  }

  VideoPlayerController _videoControllerFor(String path) {
    if (_isNetworkSource(path)) {
      return VideoPlayerController.networkUrl(
        Uri.parse(path),
        httpHeaders: _authHeaders,
      );
    }

    if (_isFileSource(path)) {
      return VideoPlayerController.file(_fileFromPath(path));
    }

    return VideoPlayerController.asset(path);
  }

  Map<String, String> get _authHeaders {
    final token = _apiToken;

    if (token == null || token.isEmpty) {
      return const {};
    }

    return {'Authorization': 'Bearer $token'};
  }

  bool _isFileSource(String path) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.scheme == 'file') {
      return true;
    }

    return path.startsWith('/') || RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(path);
  }

  File _fileFromPath(String path) {
    final uri = Uri.tryParse(path);

    if (uri != null && uri.scheme == 'file') {
      return File.fromUri(uri);
    }

    return File(path);
  }

  Uri? _parseWebUri(String value) {
    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) return null;

    final uri = Uri.tryParse(trimmedValue);
    if (uri == null) return null;

    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      return uri;
    }

    if (!trimmedValue.contains('://')) {
      return Uri.tryParse('https://$trimmedValue');
    }

    return null;
  }

  double? _playbackProgress(VideoPlayerValue value) {
    if (value.duration == Duration.zero) return null;

    final progress =
        value.position.inMilliseconds / value.duration.inMilliseconds;

    return progress.clamp(0, 1).toDouble();
  }
}

class _TimelineSlot {
  const _TimelineSlot({required this.startAt, required this.endAt});

  final DateTime startAt;
  final DateTime endAt;
}
