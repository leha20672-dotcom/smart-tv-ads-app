import 'package:flutter/foundation.dart';

class AppConfig {
  static const _defaultApiBaseUrl =
      'https://uneven-cringing-diligence.ngrok-free.dev/api';
  static const _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );
  static const updateCheckUrl = String.fromEnvironment('UPDATE_CHECK_URL');
  static const updateCheckPath = String.fromEnvironment(
    'UPDATE_CHECK_PATH',
    defaultValue: '/app-version',
  );
  static const remoteUpdateEnabled = bool.fromEnvironment(
    'REMOTE_UPDATE_ENABLED',
    defaultValue: true,
  );
  static const preferRootUpdateInstall = bool.fromEnvironment(
    'UPDATE_PREFER_ROOT_INSTALL',
    defaultValue: true,
  );
  static const stayAliveEnabled = bool.fromEnvironment(
    'STAY_ALIVE_ENABLED',
    defaultValue: true,
  );
  static const stayAliveIntervalSeconds = int.fromEnvironment(
    'STAY_ALIVE_INTERVAL_SECONDS',
    defaultValue: 30,
  );
  static const kioskModeEnabled = bool.fromEnvironment(
    'KIOSK_MODE_ENABLED',
    defaultValue: true,
  );
  static const rootModeEnabled = bool.fromEnvironment(
    'ROOT_MODE_ENABLED',
    defaultValue: true,
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
      if (_configuredBaseUrl.isNotEmpty) _configuredBaseUrl,
      if (_defaultApiBaseUrl.isNotEmpty) _defaultApiBaseUrl,
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        androidEmulatorBaseUrl,
      defaultBaseUrl,
      desktopBaseUrl,
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android)
        androidEmulatorBaseUrl,
    }.toList();
  }
}
