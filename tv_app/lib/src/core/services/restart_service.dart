import 'dart:io';

import 'package:flutter/services.dart';

class RestartService {
  static const MethodChannel _channel = MethodChannel('tv_ads_app/restart');

  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;
  }

  static Future<void> scheduleRestart({
    Duration delay = const Duration(seconds: 30),
  }) async {
    if (!Platform.isAndroid) return;

    await _channel.invokeMethod<void>('scheduleRestart', {
      'delaySeconds': delay.inSeconds,
    });
  }

  static Future<void> cancelRestart() async {
    if (!Platform.isAndroid) return;

    await _channel.invokeMethod<void>('cancelRestart');
  }
}
