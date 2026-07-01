import 'package:flutter/widgets.dart';

import 'kiosk_service.dart';
import 'restart_service.dart';

class AppLifecycleService extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        RestartService.cancelRestart();
        KioskService.enterKiosk();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        RestartService.scheduleRestart();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }
}
