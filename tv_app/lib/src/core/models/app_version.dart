class AppVersion {
  const AppVersion({
    required this.version,
    required this.apkUrl,
    this.buildNumber,
    this.minSupportedBuild,
    this.forceUpdate = false,
    this.releaseNotes,
  });

  final String version;
  final String apkUrl;
  final int? buildNumber;
  final int? minSupportedBuild;
  final bool forceUpdate;
  final String? releaseNotes;

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version:
          (json['version'] ??
                  json['latest_version'] ??
                  json['version_name'] ??
                  '')
              .toString(),
      apkUrl: (json['apk_url'] ?? json['download_url'] ?? json['url'] ?? '')
          .toString(),
      buildNumber: _asNullableInt(
        json['build_number'] ?? json['version_code'] ?? json['build'],
      ),
      minSupportedBuild: _asNullableInt(
        json['min_supported_build'] ?? json['minimum_build'],
      ),
      forceUpdate: _asBool(json['force_update'] ?? json['required']),
      releaseNotes: json['release_notes']?.toString(),
    );
  }

  bool get hasDownload => apkUrl.isNotEmpty;

  AppVersion copyWith({String? apkUrl}) {
    return AppVersion(
      version: version,
      apkUrl: apkUrl ?? this.apkUrl,
      buildNumber: buildNumber,
      minSupportedBuild: minSupportedBuild,
      forceUpdate: forceUpdate,
      releaseNotes: releaseNotes,
    );
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();

      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }

    return false;
  }
}
