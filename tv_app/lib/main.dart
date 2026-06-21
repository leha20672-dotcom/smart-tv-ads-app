import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'src/app.dart';
import 'dart:io';
import 'src/core/services/restart_service.dart';
import 'src/core/services/app_lifecycle_service.dart';
import 'src/core/services/update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
  await RestartService.initialize();

    WidgetsBinding.instance.addObserver(
      AppLifecycleService(),
    );
  }

  WidgetsBinding.instance.addObserver(
    AppLifecycleService(),
  );

  await Hive.initFlutter();

final updateService = UpdateService();

  await updateService.checkUpdate();

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(
    const ProviderScope(
      child: SmartTvAdsApp(),
    ),
  );
}