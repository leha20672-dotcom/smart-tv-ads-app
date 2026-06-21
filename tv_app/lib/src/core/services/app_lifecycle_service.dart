import 'package:flutter/widgets.dart';
import 'restart_service.dart';

class AppLifecycleService
    extends WidgetsBindingObserver {

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state) {

    if (state == AppLifecycleState.paused) {
      RestartService.scheduleRestart();
    }

    if (state == AppLifecycleState.resumed) {
      RestartService.cancelRestart();
    }
  }
}