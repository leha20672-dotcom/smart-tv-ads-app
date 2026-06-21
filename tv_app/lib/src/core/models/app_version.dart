class AppVersion {

  final String version;

  final String apkUrl;

  AppVersion({
    required this.version,
    required this.apkUrl,
  });

  factory AppVersion.fromJson(
    Map<String, dynamic> json,
  ) {
    return AppVersion(
      version: json['version'],
      apkUrl: json['apk_url'],
    );
  }
}