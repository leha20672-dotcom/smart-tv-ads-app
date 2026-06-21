class ScheduleMedia {
  const ScheduleMedia({
    required this.id,
    required this.scheduleId,
    required this.mediaId,
    required this.zoneName,
    required this.playOrder,
    required this.duration,
  });

  final int id;
  final int scheduleId;
  final int mediaId;
  final String zoneName;
  final int playOrder;
  final int duration;

  factory ScheduleMedia.fromJson(Map<String, dynamic> json) {
    return ScheduleMedia(
      id: _asInt(json['id']),
      scheduleId: _asInt(json['schedule_id']),
      mediaId: _asInt(json['media_id'] ?? json['id']),
      zoneName: (json['zone_name'] ?? 'main_zone') as String,
      playOrder: _asInt(json['play_order'], defaultValue: 1),
      duration: _asInt(json['duration'], defaultValue: 10),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'media_id': mediaId,
      'zone_name': zoneName,
      'play_order': playOrder,
      'duration': duration,
    };
  }

  static int _asInt(Object? value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
