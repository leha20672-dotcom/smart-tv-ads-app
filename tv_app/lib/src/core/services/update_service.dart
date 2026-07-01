import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';
import '../models/app_version.dart';

class UpdateService {
  UpdateService({Dio? dio}) : _dio = dio ?? Dio();

  static const MethodChannel _channel = MethodChannel('tv_ads_app/update');

  final Dio _dio;

  Future<void> checkUpdate() async {
    if (!AppConfig.remoteUpdateEnabled || !Platform.isAndroid) {
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      debugPrint('Current Version: $currentVersion+$currentBuild');

      final latestVersion = await _fetchLatestVersion();

      if (latestVersion == null ||
          !latestVersion.hasDownload ||
          !_shouldUpdate(
            currentVersion: currentVersion,
            currentBuild: currentBuild,
            latestVersion: latestVersion,
          )) {
        return;
      }

      final apkPath = await _downloadApk(latestVersion);

      await _installApk(apkPath);
    } catch (error, stackTrace) {
      debugPrint('Remote update failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<AppVersion?> _fetchLatestVersion() async {
    final updateUrls = _updateUrls();

    for (final updateUrl in updateUrls) {
      try {
        final response = await _dio.getUri<Map<String, dynamic>>(
          Uri.parse(updateUrl),
          options: Options(
            headers: const {'Accept': 'application/json'},
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );

        final data = _unwrapResponse(response.data);

        if (data == null) {
          continue;
        }

        final version = AppVersion.fromJson(data);

        if (!version.hasDownload) {
          continue;
        }

        return version.copyWith(
          apkUrl: _resolveDownloadUrl(
            updateUrl: updateUrl,
            apkUrl: version.apkUrl,
          ),
        );
      } catch (error) {
        debugPrint('Update check failed for $updateUrl: $error');
      }
    }

    return null;
  }

  List<String> _updateUrls() {
    if (AppConfig.updateCheckUrl.isNotEmpty) {
      return [AppConfig.updateCheckUrl];
    }

    final path = AppConfig.updateCheckPath.startsWith('/')
        ? AppConfig.updateCheckPath
        : '/${AppConfig.updateCheckPath}';

    return AppConfig.fallbackBaseUrls.map((baseUrl) {
      final trimmedBaseUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;

      return '$trimmedBaseUrl$path';
    }).toList();
  }

  Map<String, dynamic>? _unwrapResponse(Map<String, dynamic>? response) {
    if (response == null) return null;

    final data = response['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return response;
  }

  String _resolveDownloadUrl({
    required String updateUrl,
    required String apkUrl,
  }) {
    final parsedApkUrl = Uri.tryParse(apkUrl);

    if (parsedApkUrl != null &&
        parsedApkUrl.hasScheme &&
        parsedApkUrl.host.isNotEmpty) {
      return apkUrl;
    }

    return Uri.parse(updateUrl).resolve(apkUrl).toString();
  }

  bool _shouldUpdate({
    required String currentVersion,
    required int currentBuild,
    required AppVersion latestVersion,
  }) {
    final minSupportedBuild = latestVersion.minSupportedBuild;
    if (minSupportedBuild != null && currentBuild < minSupportedBuild) {
      return true;
    }

    final latestBuild = latestVersion.buildNumber;
    if (latestBuild != null) {
      return latestBuild > currentBuild;
    }

    return _compareVersions(latestVersion.version, currentVersion) > 0;
  }

  int _compareVersions(String left, String right) {
    final leftParts = _versionParts(left);
    final rightParts = _versionParts(right);
    final maxLength = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;

    for (var index = 0; index < maxLength; index++) {
      final leftValue = index < leftParts.length ? leftParts[index] : 0;
      final rightValue = index < rightParts.length ? rightParts[index] : 0;

      if (leftValue != rightValue) {
        return leftValue.compareTo(rightValue);
      }
    }

    return 0;
  }

  List<int> _versionParts(String version) {
    return version
        .split(RegExp(r'[.+-]'))
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }

  Future<String> _downloadApk(AppVersion version) async {
    final tempDirectory = await getTemporaryDirectory();
    final updateDirectory = Directory('${tempDirectory.path}/updates');

    if (!updateDirectory.existsSync()) {
      updateDirectory.createSync(recursive: true);
    }

    final buildSuffix = version.buildNumber == null
        ? ''
        : '_${version.buildNumber}';
    final apkPath =
        '${updateDirectory.path}/tv_app_${_safeFilePart(version.version)}$buildSuffix.apk';

    await _dio.download(
      version.apkUrl,
      apkPath,
      options: Options(
        followRedirects: true,
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(seconds: 15),
        responseType: ResponseType.bytes,
      ),
    );

    return apkPath;
  }

  String _safeFilePart(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  Future<void> _installApk(String apkPath) async {
    final startedInstall = await _channel.invokeMethod<bool>('installApk', {
      'apkPath': apkPath,
      'preferRootInstall': AppConfig.preferRootUpdateInstall,
    });

    if (startedInstall != true) {
      debugPrint(
        'APK downloaded, waiting for install permission before install can continue.',
      );
    }
  }
}
