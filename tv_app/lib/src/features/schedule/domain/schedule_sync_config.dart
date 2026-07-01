class ScheduleSyncConfig {
  const ScheduleSyncConfig({required this.refreshInterval});

  static const defaultRefreshInterval = Duration(seconds: 30);

  final Duration refreshInterval;

  factory ScheduleSyncConfig.fromJson(Map<String, dynamic> json) {
    final seconds = _asInt(
      json['schedule_refresh_interval_seconds'] ??
          json['schedule_sync_interval_seconds'] ??
          json['refresh_interval_seconds'],
    );
    final minutes = _asInt(
      json['schedule_refresh_interval_minutes'] ??
          json['schedule_sync_interval_minutes'] ??
          json['refresh_interval_minutes'],
    );

    final interval = seconds > 0
        ? Duration(seconds: seconds)
        : minutes > 0
        ? Duration(minutes: minutes)
        : defaultRefreshInterval;

    return ScheduleSyncConfig(refreshInterval: _clampInterval(interval));
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static Duration _clampInterval(Duration interval) {
    if (interval < const Duration(seconds: 30)) {
      return const Duration(seconds: 30);
    }

    if (interval > const Duration(seconds: 30)) {
      return const Duration(seconds: 30);
    }

    return interval;
  }
}
