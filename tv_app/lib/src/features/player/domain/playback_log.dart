enum PlaybackLogStatus {
  playing, 
  completed, 
  failed,
}

class PlaybackLog {
  const PlaybackLog({
    required this.id,
    required this.scheduleId,
    required this.mediaId,
    required this.startedAt,
    this.endedAt,
    required this.status,
    this.errorMessage,
  });

  final String id;
  final int scheduleId;
  final int mediaId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final PlaybackLogStatus status;
  final String? errorMessage;

  PlaybackLog copyWith({
    DateTime? endedAt,
    PlaybackLogStatus? status,
    String? errorMessage,
  }) {
    return PlaybackLog(
      id: id,
      scheduleId: scheduleId,
      mediaId: mediaId,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory PlaybackLog.fromJson(Map<String, dynamic> json) {
    return PlaybackLog(
      id: json['id'] as String,
      scheduleId: json['schedule_id'] as int,
      mediaId: json['media_id'] as int,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] == null
        ? null
        : DateTime.parse(json['ended_at'] as String),
        status: _statusFromString(json['status'] as String),
        errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'media_id': mediaId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'status': status.name,
      'error_message': errorMessage,
    };
  }

  static PlaybackLogStatus _statusFromString(String value) {
    switch (value) {
      case 'playing':
        return PlaybackLogStatus.playing;
      case 'completed':
        return PlaybackLogStatus.completed;
      case 'failed':
        return PlaybackLogStatus.failed;
      default:
        return PlaybackLogStatus.failed;
    }
  }
}