import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/app_config.dart';

class KioskService {
  static const MethodChannel _channel = MethodChannel('tv_ads_app/kiosk');

  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    await _invoke('startStayAlive', {
      'enabled': AppConfig.stayAliveEnabled,
      'intervalSeconds': AppConfig.stayAliveIntervalSeconds,
      'rootMode': AppConfig.rootModeEnabled,
    });

    if (AppConfig.kioskModeEnabled) {
      await enterKiosk();
    }
  }

  static Future<void> enterKiosk() async {
    if (!Platform.isAndroid) return;

    await _invoke('enterKiosk', {'rootMode': AppConfig.rootModeEnabled});
  }

  static Future<void> exitKiosk() async {
    if (!Platform.isAndroid) return;

    await _invoke('exitKiosk');
  }

  static Future<bool> isRootAvailable() async {
    if (!Platform.isAndroid) return false;

    try {
      return await _channel.invokeMethod<bool>('isRootAvailable') ?? false;
    } catch (error) {
      debugPrint('Root check failed: $error');
      return false;
    }
  }

  static Future<void> _invoke(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } catch (error) {
      debugPrint('Kiosk service method $method failed: $error');
    }
  }
}
