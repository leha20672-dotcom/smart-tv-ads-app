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
      id: json['id'] as int,
      scheduleId: json['schedule_id'] as int,
      mediaId: json['media_id'] as int,
      zoneName: json['zone_name'] as String,
      playOrder: json['play_order'] as int,
      duration: json['duration'] as int,
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
}