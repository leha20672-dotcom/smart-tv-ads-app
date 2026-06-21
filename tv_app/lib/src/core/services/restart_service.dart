import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';

class RestartService {
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  static Future<void> scheduleRestart() async {
    await AndroidAlarmManager.oneShot(
      const Duration(seconds: 30),
      1001,
      restartCallback,
      exact: true,
      wakeup: true,
    );
  }

  static Future<void> cancelRestart() async {
    await AndroidAlarmManager.cancel(1001);
  }
}

@pragma('vm:entry-point')
Future<void> restartCallback() async {
  debugPrint("Restart App");
}