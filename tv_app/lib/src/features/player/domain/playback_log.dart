enum PlaybackLogStatus { playing, completed, failed }

class PlaybackLog {
  const PlaybackLog({
    required this.id,
    required this.scheduleId,
    required this.mediaId,
    required this.startedAt,
    this.endedAt,
    required this.status,
    this.errorMessage,
    this.isSynced = false,
    this.syncAttempts = 0,
    this.lastSyncAttemptAt,
    this.nextRetryAt,
    this.syncErrorMessage,
  });

  static const Object _unset = Object();

  final String id;
  final int scheduleId;
  final int mediaId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final PlaybackLogStatus status;
  final String? errorMessage;
  final bool isSynced;
  final int syncAttempts;
  final DateTime? lastSyncAttemptAt;
  final DateTime? nextRetryAt;
  final String? syncErrorMessage;

  PlaybackLog copyWith({
    DateTime? endedAt,
    PlaybackLogStatus? status,
    Object? errorMessage = _unset,
    bool? isSynced,
    int? syncAttempts,
    Object? lastSyncAttemptAt = _unset,
    Object? nextRetryAt = _unset,
    Object? syncErrorMessage = _unset,
  }) {
    return PlaybackLog(
      id: id,
      scheduleId: scheduleId,
      mediaId: mediaId,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      isSynced: isSynced ?? this.isSynced,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncAttemptAt: identical(lastSyncAttemptAt, _unset)
          ? this.lastSyncAttemptAt
          : lastSyncAttemptAt as DateTime?,
      nextRetryAt: identical(nextRetryAt, _unset)
          ? this.nextRetryAt
          : nextRetryAt as DateTime?,
      syncErrorMessage: identical(syncErrorMessage, _unset)
          ? this.syncErrorMessage
          : syncErrorMessage as String?,
    );
  }

  factory PlaybackLog.fromJson(Map<String, dynamic> json) {
    return PlaybackLog(
      id: json['id'] as String,
      scheduleId: _asInt(json['schedule_id']),
      mediaId: _asInt(json['media_id']),
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: _asNullableDateTime(json['ended_at']),
      status: _statusFromString(json['status'] as String? ?? ''),
      errorMessage: json['error_message'] as String?,
      isSynced: _asBool(json['is_synced']),
      syncAttempts: _asInt(json['sync_attempts']),
      lastSyncAttemptAt: _asNullableDateTime(json['last_sync_attempt_at']),
      nextRetryAt: _asNullableDateTime(json['next_retry_at']),
      syncErrorMessage: json['sync_error_message'] as String?,
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
      'is_synced': isSynced,
      'sync_attempts': syncAttempts,
      'last_sync_attempt_at': lastSyncAttemptAt?.toIso8601String(),
      'next_retry_at': nextRetryAt?.toIso8601String(),
      'sync_error_message': syncErrorMessage,
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

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();

      return normalized == 'true' || normalized == '1';
    }

    return false;
  }

  static DateTime? _asNullableDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
