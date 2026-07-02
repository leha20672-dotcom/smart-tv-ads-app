import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../domain/media.dart';
import '../domain/playable_media.dart';
import '../domain/schedule.dart';
import '../domain/schedule_sync_config.dart';

class ScheduleRemoteDataSource {
  ScheduleRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PlayableMedia>> getCurrentPlaylist({
    required String apiToken,
    DateTime? now,
  }) async {
    final serverNow = now ?? await getServerTime(apiToken: apiToken);
    final response = await _apiClient.get(
      '/get-schedule',
      bearerToken: apiToken,
    );

    final playlist = _parsePlaylist(_unwrapResponse(response), serverNow);
    debugPrint(
      'Schedule API /get-schedule returned ${playlist.length} playable item(s).',
    );

    return playlist;
  }

  Future<DateTime> getServerTime({required String apiToken}) async {
    try {
      final response = await _apiClient.get(
        '/server-time',
        bearerToken: apiToken,
      );

      final serverTime = _looseDateTimeFromJson(response['server_time']);
      if (serverTime != null) {
        return serverTime;
      }

      final timestamp = response['timestamp'];
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
      if (timestamp is num) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
      }
    } catch (error) {
      debugPrint('Server time sync failed: $error');
      // Fall back to device time if the server clock endpoint is temporarily
      // unavailable; schedule fetch still has a chance to return a flat playlist.
    }

    return DateTime.now();
  }

  Future<ScheduleSyncConfig> getSyncConfig({required String apiToken}) async {
    final response = await _apiClient.get('/info', bearerToken: apiToken);
    final data = _unwrapResponse(response);
    final configurations = data['configurations'];

    if (configurations is Map) {
      return ScheduleSyncConfig.fromJson(
        Map<String, dynamic>.from(configurations),
      );
    }

    return ScheduleSyncConfig.fromJson(data);
  }

  Map<String, dynamic> _unwrapResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return response;
  }

  List<PlayableMedia> _parsePlaylist(
    Map<String, dynamic> response,
    DateTime now,
  ) {
    final schedulesJson = response['schedules'];

    if (schedulesJson is List && schedulesJson.isNotEmpty) {
      return _parseScheduledPlaylist(schedulesJson, now);
    }

    final playlistJson = response['playlist'];

    if (playlistJson is! List) {
      return [];
    }

    if (_hasNestedSchedulePlaylist(playlistJson)) {
      return _parseNestedSchedulePlaylist(playlistJson, now);
    }

    final scheduleStartAt = _scheduleStartAtFromJson(response, now);
    final scheduleEndAt = _scheduleEndAtFromJson(response, now);
    final playlist = playlistJson
        .map(
          (item) => _playableFromFlatJson(
            Map<String, dynamic>.from(item),
            scheduleStartAt: scheduleStartAt,
            scheduleEndAt: scheduleEndAt,
          ),
        )
        .toList();

    return _normalizeTimeline(
      playlist,
      scheduleStartAt: scheduleStartAt,
      forceTimeline:
          scheduleStartAt != null ||
          playlist.any((item) => item.isSyncedTimeline),
    );
  }

  List<PlayableMedia> _parseScheduledPlaylist(
    List schedulesJson,
    DateTime now,
  ) {
    final result = <PlayableMedia>[];

    for (final rawSchedule in schedulesJson) {
      final scheduleJson = Map<String, dynamic>.from(rawSchedule);
      final schedule = Schedule.fromJson(scheduleJson);

      if (!_isScheduleAvailableToday(schedule, now)) {
        continue;
      }

      final mediaJson = scheduleJson['media'];

      if (mediaJson is! List) {
        continue;
      }

      final scheduleStartAt = _scheduleStartAt(schedule, now);
      final scheduleEndAt = _scheduleEndAt(schedule, now);
      final schedulePlaylist = <PlayableMedia>[];

      for (final rawMedia in mediaJson) {
        final mediaItem = Map<String, dynamic>.from(rawMedia);
        schedulePlaylist.add(
          _playableFromFlatJson(
            mediaItem,
            scheduleId: schedule.id,
            scheduleName: schedule.name,
            scheduleStartAt: scheduleStartAt,
            scheduleEndAt: scheduleEndAt,
            forceTimeline: true,
          ),
        );
      }

      result.addAll(
        _normalizeTimeline(
          schedulePlaylist,
          scheduleStartAt: scheduleStartAt,
          forceTimeline: true,
        ),
      );
    }

    result.sort((a, b) => a.playOrder.compareTo(b.playOrder));
    return result;
  }

  bool _hasNestedSchedulePlaylist(List playlistJson) {
    return playlistJson.any((item) {
      if (item is! Map) {
        return false;
      }

      return item['playlist'] is List;
    });
  }

  List<PlayableMedia> _parseNestedSchedulePlaylist(
    List schedulesJson,
    DateTime now,
  ) {
    final result = <PlayableMedia>[];

    for (final rawSchedule in schedulesJson) {
      if (rawSchedule is! Map) {
        continue;
      }

      final scheduleJson = Map<String, dynamic>.from(rawSchedule);
      final playlistJson = scheduleJson['playlist'];

      if (playlistJson is! List || playlistJson.isEmpty) {
        continue;
      }

      if (!_isNestedScheduleActive(scheduleJson, now)) {
        continue;
      }

      final scheduleStartAt = _nestedScheduleStartAt(scheduleJson, now);
      final scheduleEndAt = _nestedScheduleEndAt(scheduleJson, now);
      final scheduleId = _asInt(
        scheduleJson['schedule_id'] ?? scheduleJson['id'],
      );
      final scheduleName =
          (scheduleJson['schedule_name'] ??
                  scheduleJson['name'] ??
                  'API Playlist')
              .toString();
      final schedulePlaylist = <PlayableMedia>[];

      for (final rawMedia in playlistJson) {
        if (rawMedia is! Map) {
          continue;
        }

        schedulePlaylist.add(
          _playableFromFlatJson(
            Map<String, dynamic>.from(rawMedia),
            scheduleId: scheduleId,
            scheduleName: scheduleName,
            scheduleStartAt: scheduleStartAt,
            scheduleEndAt: scheduleEndAt,
            forceTimeline: true,
          ),
        );
      }

      result.addAll(
        _normalizeTimeline(
          schedulePlaylist,
          scheduleStartAt: scheduleStartAt,
          forceTimeline: true,
        ),
      );
    }

    result.sort((a, b) => a.playOrder.compareTo(b.playOrder));
    return result;
  }

  PlayableMedia _playableFromFlatJson(
    Map<String, dynamic> json, {
    int? scheduleId,
    String? scheduleName,
    DateTime? scheduleStartAt,
    DateTime? scheduleEndAt,
    bool forceTimeline = false,
  }) {
    final timelineStartSecond = _timelineStartSecond(json);
    final hasDuration = _hasDurationField(json);
    final duration = _durationFromJson(json);
    final timelineEndSecond = _timelineEndSecond(
      json,
      startSecond: timelineStartSecond,
      duration: duration,
      hasDuration: hasDuration,
    );
    final itemScheduleStartAt =
        _scheduleStartAtFromJson(json, null) ?? scheduleStartAt;
    final itemScheduleEndAt =
        _scheduleEndAtFromJson(json, null) ?? scheduleEndAt;

    return PlayableMedia(
      scheduleId: scheduleId ?? _asInt(json['schedule_id']),
      scheduleName:
          scheduleName ?? (json['schedule_name'] ?? 'API Playlist').toString(),
      media: Media.fromJson({
        'id': json['media_id'] ?? json['id'],
        'name': json['title'] ?? json['name'] ?? json['file_name'],
        'download_url': json['download_url'],
        'file_url': json['file_url'] ?? json['url'],
        'file_path': json['file_path'] ?? json['path'],
        'file_type':
            json['file_type'] ??
            json['type'] ??
            json['media_type'] ??
            json['mime_type'] ??
            json['file_name'],
        'file_size': json['file_size'],
      }),
      zoneName: (json['zone_name'] ?? 'main_zone') as String,
      playOrder: _asInt(json['play_order'], defaultValue: 1),
      duration: duration,
      timelineStartSecond: timelineStartSecond,
      timelineEndSecond: timelineEndSecond,
      scheduleStartAt: itemScheduleStartAt?.toIso8601String(),
      scheduleEndAt: itemScheduleEndAt?.toIso8601String(),
      isSyncedTimeline:
          forceTimeline ||
          itemScheduleStartAt != null ||
          timelineStartSecond != null ||
          timelineEndSecond != null,
    );
  }

  List<PlayableMedia> _normalizeTimeline(
    List<PlayableMedia> playlist, {
    required DateTime? scheduleStartAt,
    required bool forceTimeline,
  }) {
    final sortedPlaylist = playlist.toList()
      ..sort((a, b) => a.playOrder.compareTo(b.playOrder));

    if (!forceTimeline) {
      return sortedPlaylist;
    }

    var cursorSecond = 0;

    return sortedPlaylist.map((item) {
      var startSecond = item.timelineStartSecond;
      var endSecond = item.timelineEndSecond;
      final safeDuration = item.duration <= 0 ? 10 : item.duration;

      if (startSecond == null && endSecond == null) {
        startSecond = cursorSecond;
        endSecond = startSecond + safeDuration;
      } else if (startSecond == null) {
        startSecond = (endSecond! - safeDuration).clamp(0, endSecond);
      } else if (endSecond == null || endSecond <= startSecond) {
        endSecond = startSecond + safeDuration;
      }

      cursorSecond = endSecond;

      return item.copyWith(
        duration: (endSecond - startSecond).clamp(1, 86400),
        timelineStartSecond: startSecond,
        timelineEndSecond: endSecond,
        scheduleStartAt:
            item.scheduleStartAt ?? scheduleStartAt?.toIso8601String(),
        isSyncedTimeline: true,
      );
    }).toList();
  }

  bool _isScheduleAvailableToday(Schedule schedule, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(
      schedule.startDate.year,
      schedule.startDate.month,
      schedule.startDate.day,
    );
    final endDate = DateTime(
      schedule.endDate.year,
      schedule.endDate.month,
      schedule.endDate.day,
    );

    final isInDateRange = !today.isBefore(startDate) && !today.isAfter(endDate);
    final isInDayOfWeek = schedule.daysOfWeek.contains(now.weekday);

    return isInDateRange && isInDayOfWeek;
  }

  bool _isNestedScheduleActive(
    Map<String, dynamic> scheduleJson,
    DateTime now,
  ) {
    final startAt = _looseDateTimeFromJson(scheduleJson['date_start']);
    final endAt = _looseDateTimeFromJson(scheduleJson['date_end']);
    final today = DateTime(now.year, now.month, now.day);

    if (startAt != null) {
      final startDate = DateTime(startAt.year, startAt.month, startAt.day);
      if (today.isBefore(startDate)) {
        return false;
      }
    }

    if (endAt != null) {
      final endDate = DateTime(endAt.year, endAt.month, endAt.day);
      if (today.isAfter(endDate)) {
        return false;
      }
    }

    final daysOfWeek = _daysOfWeekFromJson(
      scheduleJson['days_active'] ?? scheduleJson['days_of_week'],
    );

    return daysOfWeek.isEmpty || daysOfWeek.contains(now.weekday);
  }

  DateTime _scheduleStartAt(Schedule schedule, DateTime now) {
    var date = DateTime(now.year, now.month, now.day);
    final startSeconds = _timeToSeconds(schedule.startTime);
    final endSeconds = _timeToSeconds(schedule.endTime);
    final currentSeconds = now.hour * 3600 + now.minute * 60 + now.second;

    if (endSeconds < startSeconds && currentSeconds <= endSeconds) {
      date = date.subtract(const Duration(days: 1));
    }

    return date.add(Duration(seconds: startSeconds));
  }

  DateTime _scheduleEndAt(Schedule schedule, DateTime now) {
    final startAt = _scheduleStartAt(schedule, now);
    final startSeconds = _timeToSeconds(schedule.startTime);
    final endSeconds = _timeToSeconds(schedule.endTime);
    final endDate = endSeconds <= startSeconds
        ? startAt.add(const Duration(days: 1))
        : startAt;

    return DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).add(Duration(seconds: endSeconds));
  }

  DateTime? _nestedScheduleStartAt(
    Map<String, dynamic> scheduleJson,
    DateTime now,
  ) {
    return _looseDateTimeFromJson(scheduleJson['date_start']) ??
        _scheduleStartAtFromJson(scheduleJson, now);
  }

  DateTime? _nestedScheduleEndAt(
    Map<String, dynamic> scheduleJson,
    DateTime now,
  ) {
    return _looseDateTimeFromJson(scheduleJson['date_end']) ??
        _scheduleEndAtFromJson(scheduleJson, now);
  }

  DateTime? _scheduleStartAtFromJson(
    Map<String, dynamic> json,
    DateTime? fallbackDate,
  ) {
    final absoluteValue =
        json['schedule_start_at'] ??
        json['schedule_started_at'] ??
        json['timeline_start_at'];

    if (absoluteValue is String && absoluteValue.isNotEmpty) {
      final parsed = DateTime.tryParse(absoluteValue);
      if (parsed != null) {
        return parsed;
      }
    }

    final dateValue = json['start_date'] ?? json['schedule_date'];
    final timeValue =
        json['start_time'] ?? json['schedule_start_time'] ?? json['time_start'];

    if (timeValue is String && timeValue.isNotEmpty) {
      DateTime date;

      if (dateValue is String && dateValue.isNotEmpty) {
        date = DateTime.tryParse(dateValue) ?? fallbackDate ?? DateTime.now();
      } else {
        final now = fallbackDate ?? DateTime.now();
        date = DateTime(now.year, now.month, now.day);
      }

      return DateTime(
        date.year,
        date.month,
        date.day,
      ).add(Duration(seconds: _timeToSeconds(timeValue)));
    }

    return null;
  }

  DateTime? _scheduleEndAtFromJson(
    Map<String, dynamic> json,
    DateTime? fallbackDate,
  ) {
    final absoluteValue =
        json['schedule_end_at'] ??
        json['schedule_ended_at'] ??
        json['timeline_end_at'];

    if (absoluteValue is String && absoluteValue.isNotEmpty) {
      final parsed = DateTime.tryParse(absoluteValue);
      if (parsed != null) {
        return parsed;
      }
    }

    final dateValue = json['end_date'] ?? json['schedule_date'];
    final timeValue =
        json['end_time'] ?? json['schedule_end_time'] ?? json['time_end'];

    if (timeValue is String && timeValue.isNotEmpty) {
      DateTime date;

      if (dateValue is String && dateValue.isNotEmpty) {
        date = DateTime.tryParse(dateValue) ?? fallbackDate ?? DateTime.now();
      } else {
        final now = fallbackDate ?? DateTime.now();
        date = DateTime(now.year, now.month, now.day);
      }

      return DateTime(
        date.year,
        date.month,
        date.day,
      ).add(Duration(seconds: _timeToSeconds(timeValue)));
    }

    return null;
  }

  DateTime? _looseDateTimeFromJson(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    final trimmedValue = value.trim();
    final parsed = DateTime.tryParse(trimmedValue);

    if (parsed != null) {
      return parsed;
    }

    final normalized = trimmedValue.replaceFirst(RegExp(r'\s+-\s+'), ' ');
    return DateTime.tryParse(normalized);
  }

  List<int> _daysOfWeekFromJson(Object? value) {
    final days = <int>[];

    if (value is List) {
      days.addAll(value.map(_asInt));
    } else if (value is String && value.isNotEmpty) {
      final normalized = value.replaceAll('[', '').replaceAll(']', '');
      days.addAll(
        normalized
            .split(',')
            .map((day) => _asInt(day.trim()))
            .where((day) => day > 0),
      );
    }

    return _normalizeWeekdays(days);
  }

  List<int> _normalizeWeekdays(List<int> days) {
    if (days.contains(8) ||
        (days.isNotEmpty && days.every((day) => day >= 2 && day <= 7))) {
      return days
          .map((day) => day == 8 ? 7 : day - 1)
          .where((day) => day >= 1 && day <= 7)
          .toSet()
          .toList();
    }

    return days.where((day) => day >= 1 && day <= 7).toSet().toList();
  }

  int? _timelineStartSecond(Map<String, dynamic> json) {
    return _asNullableInt(
      json['timeline_start_second'] ??
          json['start_second'] ??
          json['from_second'] ??
          json['second_from'] ??
          json['offset_start'] ??
          json['start_offset_seconds'],
    );
  }

  int? _timelineEndSecond(
    Map<String, dynamic> json, {
    required int? startSecond,
    required int duration,
    required bool hasDuration,
  }) {
    if (startSecond != null && hasDuration && duration > 0) {
      return startSecond + duration;
    }

    final rawEndSecond = _asNullableInt(
      json['timeline_end_second'] ??
          json['end_second'] ??
          json['to_second'] ??
          json['second_to'] ??
          json['offset_end'] ??
          json['end_offset_seconds'],
    );

    if (rawEndSecond == null) {
      return null;
    }

    return rawEndSecond + 1;
  }

  int _durationFromJson(Map<String, dynamic> json) {
    return _asInt(
      json['duration'] ??
          json['duration_seconds'] ??
          json['display_duration'] ??
          json['display_duration_seconds'],
      defaultValue: 10,
    );
  }

  bool _hasDurationField(Map<String, dynamic> json) {
    return json.containsKey('duration') ||
        json.containsKey('duration_seconds') ||
        json.containsKey('display_duration') ||
        json.containsKey('display_duration_seconds');
  }

  int _timeToSeconds(String time) {
    final parts = time.split(':');

    if (parts.length < 2) {
      return 0;
    }

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

    return hour * 3600 + minute * 60 + second;
  }

  int _asInt(Object? value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  int? _asNullableInt(Object? value) {
    if (value == null) return null;
    return _asInt(value);
  }
}
