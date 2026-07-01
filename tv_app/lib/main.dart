import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'src/core/services/app_lifecycle_service.dart';
import 'src/core/services/kiosk_service.dart';
import 'src/core/services/restart_service.dart';
import 'src/core/services/update_service.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await RestartService.initialize();
    await KioskService.initialize();
  }

  WidgetsBinding.instance.addObserver(AppLifecycleService());

  await Hive.initFlutter();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const ProviderScope(child: SmartTvAdsApp()));

  Future<void>.microtask(() => UpdateService().checkUpdate());
}
