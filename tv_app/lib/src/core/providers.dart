import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'config/app_config.dart';
import 'storage/app_storage.dart';
import 'storage/storage_keys.dart';

final storageProvider = Provider<AppStorage>((ref) {
  return AppStorage(Hive.box(StorageKeys.appBox));
});

final baseUrlProvider = StateProvider<String>((ref) {
  final storage = ref.watch(storageProvider);
  return storage.getString(StorageKeys.baseUrl) ?? AppConfig.defaultBaseUrl;
});

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);

  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    ),
  );
});
