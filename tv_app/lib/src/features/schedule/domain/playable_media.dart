import 'media.dart';

class PlayableMedia {
  const PlayableMedia({
    required this.scheduleId,
    required this.scheduleName,
    required this.media,
    required this.zoneName,
    required this.playOrder,
    required this.duration,
    this.timelineStartSecond,
    this.timelineEndSecond,
    this.scheduleStartAt,
    this.scheduleEndAt,
    this.isSyncedTimeline = false,
  });

  final int scheduleId;
  final String scheduleName;
  final Media media;
  final String zoneName;
  final int playOrder;
  final int duration;
  final int? timelineStartSecond;
  final int? timelineEndSecond;
  final String? scheduleStartAt;
  final String? scheduleEndAt;
  final bool isSyncedTimeline;

  DateTime? get scheduleStartDateTime {
    final value = scheduleStartAt;
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  DateTime? get scheduleEndDateTime {
    final value = scheduleEndAt;
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  PlayableMedia copyWith({
    int? scheduleId,
    String? scheduleName,
    Media? media,
    String? zoneName,
    int? playOrder,
    int? duration,
    int? timelineStartSecond,
    int? timelineEndSecond,
    String? scheduleStartAt,
    String? scheduleEndAt,
    bool? isSyncedTimeline,
  }) {
    return PlayableMedia(
      scheduleId: scheduleId ?? this.scheduleId,
      scheduleName: scheduleName ?? this.scheduleName,
      media: media ?? this.media,
      zoneName: zoneName ?? this.zoneName,
      playOrder: playOrder ?? this.playOrder,
      duration: duration ?? this.duration,
      timelineStartSecond: timelineStartSecond ?? this.timelineStartSecond,
      timelineEndSecond: timelineEndSecond ?? this.timelineEndSecond,
      scheduleStartAt: scheduleStartAt ?? this.scheduleStartAt,
      scheduleEndAt: scheduleEndAt ?? this.scheduleEndAt,
      isSyncedTimeline: isSyncedTimeline ?? this.isSyncedTimeline,
    );
  }

  factory PlayableMedia.fromJson(Map<String, dynamic> json) {
    return PlayableMedia(
      scheduleId: _asInt(json['schedule_id']),
      scheduleName: (json['schedule_name'] ?? '') as String,
      media: Media.fromJson(Map<String, dynamic>.from(json['media'] as Map)),
      zoneName: (json['zone_name'] ?? 'main_zone') as String,
      playOrder: _asInt(json['play_order'], defaultValue: 1),
      duration: _asInt(json['duration'], defaultValue: 10),
      timelineStartSecond: _asNullableInt(json['timeline_start_second']),
      timelineEndSecond: _asNullableInt(json['timeline_end_second']),
      scheduleStartAt: json['schedule_start_at'] as String?,
      scheduleEndAt: json['schedule_end_at'] as String?,
      isSyncedTimeline: json['is_synced_timeline'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schedule_id': scheduleId,
      'schedule_name': scheduleName,
      'media': media.toJson(),
      'zone_name': zoneName,
      'play_order': playOrder,
      'duration': duration,
      if (timelineStartSecond != null)
        'timeline_start_second': timelineStartSecond,
      if (timelineEndSecond != null) 'timeline_end_second': timelineEndSecond,
      if (scheduleStartAt != null && scheduleStartAt!.isNotEmpty)
        'schedule_start_at': scheduleStartAt,
      if (scheduleEndAt != null && scheduleEndAt!.isNotEmpty)
        'schedule_end_at': scheduleEndAt,
      'is_synced_timeline': isSyncedTimeline,
    };
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    return _asInt(value);
  }

  static int _asInt(Object? value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
