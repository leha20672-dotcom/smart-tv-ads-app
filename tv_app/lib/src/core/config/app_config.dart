import 'package:flutter/foundation.dart';

class AppConfig {
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _lanBaseUrl = String.fromEnvironment(
    'API_LAN_BASE_URL',
    defaultValue: 'http://192.168.123.11:8000/api',
  );

  static String get defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }

    return 'http://127.0.0.1:8000/api';
  }

  static List<String> get fallbackBaseUrls {
    final androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api';
    final desktopBaseUrl = 'http://127.0.0.1:8000/api';

    return {
      defaultBaseUrl,
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        androidEmulatorBaseUrl,
      if (_lanBaseUrl.isNotEmpty) _lanBaseUrl,
      desktopBaseUrl,
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android)
        androidEmulatorBaseUrl,
    }.toList();
  }
}
