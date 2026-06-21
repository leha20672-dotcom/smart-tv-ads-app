import '../../../core/network/api_client.dart';
import '../domain/media.dart';
import '../domain/playable_media.dart';
import '../domain/schedule.dart';

class ScheduleRemoteDataSource {
  ScheduleRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PlayableMedia>> getCurrentPlaylist({
    required int deviceId,
    required String apiToken,
    DateTime? now,
  }) async {
    late final Map<String, dynamic> response;

    try {
      response = await _apiClient.get(
        '/devices/$deviceId/current-schedule',
        bearerToken: apiToken,
      );
    } catch (_) {
      response = await _apiClient.get(
        '/schedule',
        queryParameters: {'box_id': '$deviceId'},
        bearerToken: apiToken,
      );
    }

    return _parsePlaylist(response, now ?? DateTime.now());
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

    final playlist =
        playlistJson
            .map(
              (item) => _playableFromFlatJson(Map<String, dynamic>.from(item)),
            )
            .toList()
          ..sort((a, b) => a.playOrder.compareTo(b.playOrder));

    return playlist;
  }

  List<PlayableMedia> _parseScheduledPlaylist(
    List schedulesJson,
    DateTime now,
  ) {
    final result = <PlayableMedia>[];

    for (final rawSchedule in schedulesJson) {
      final scheduleJson = Map<String, dynamic>.from(rawSchedule);
      final schedule = Schedule.fromJson(scheduleJson);

      if (!_isScheduleActive(schedule, now)) {
        continue;
      }

      final mediaJson = scheduleJson['media'];

      if (mediaJson is! List) {
        continue;
      }

      for (final rawMedia in mediaJson) {
        final mediaItem = Map<String, dynamic>.from(rawMedia);
        result.add(
          _playableFromFlatJson(
            mediaItem,
            scheduleId: schedule.id,
            scheduleName: schedule.name,
          ),
        );
      }
    }

    result.sort((a, b) => a.playOrder.compareTo(b.playOrder));
    return result;
  }

  PlayableMedia _playableFromFlatJson(
    Map<String, dynamic> json, {
    int? scheduleId,
    String? scheduleName,
  }) {
    return PlayableMedia(
      scheduleId: scheduleId ?? _asInt(json['schedule_id']),
      scheduleName:
          scheduleName ?? (json['schedule_name'] ?? 'API Playlist') as String,
      media: Media.fromJson({
        'id': json['media_id'] ?? json['id'],
        'name': json['title'] ?? json['name'],
        'file_url': json['file_url'] ?? json['url'],
        'file_path': json['file_path'],
        'file_type': json['file_type'] ?? json['type'],
        'file_size': json['file_size'],
      }),
      zoneName: (json['zone_name'] ?? 'main_zone') as String,
      playOrder: _asInt(json['play_order'], defaultValue: 1),
      duration: _asInt(json['duration'], defaultValue: 10),
    );
  }

  bool _isScheduleActive(Schedule schedule, DateTime now) {
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
    final currentSeconds = now.hour * 3600 + now.minute * 60 + now.second;
    final startSeconds = _timeToSeconds(schedule.startTime);
    final endSeconds = _timeToSeconds(schedule.endTime);
    final isInTimeRange = endSeconds >= startSeconds
        ? currentSeconds >= startSeconds && currentSeconds <= endSeconds
        : currentSeconds >= startSeconds || currentSeconds <= endSeconds;

    return isInDateRange && isInDayOfWeek && isInTimeRange;
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
}
