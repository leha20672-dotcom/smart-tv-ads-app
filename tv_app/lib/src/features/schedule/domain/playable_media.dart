import 'media.dart';

class PlayableMedia {
  const PlayableMedia({
    required this.scheduleId,
    required this.scheduleName,
    required this.media,
    required this.zoneName,
    required this.playOrder,
    required this.duration,
  });

  final int scheduleId;
  final String scheduleName;
  final Media media;
  final String zoneName;
  final int playOrder;
  final int duration;

  factory PlayableMedia.fromJson(Map<String, dynamic> json) {
    return PlayableMedia(
      scheduleId: _asInt(json['schedule_id']),
      scheduleName: (json['schedule_name'] ?? '') as String,
      media: Media.fromJson(Map<String, dynamic>.from(json['media'] as Map)),
      zoneName: (json['zone_name'] ?? 'main_zone') as String,
      playOrder: _asInt(json['play_order'], defaultValue: 1),
      duration: _asInt(json['duration'], defaultValue: 10),
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
    };
  }

  static int _asInt(Object? value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
