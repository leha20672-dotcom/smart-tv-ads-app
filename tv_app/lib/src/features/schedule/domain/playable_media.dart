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
}