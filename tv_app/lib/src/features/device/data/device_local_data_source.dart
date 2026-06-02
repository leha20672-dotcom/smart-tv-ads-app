import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/storage_keys.dart';

class DeviceLocalDataSource {
  Future<Box> _openBox() async {
    return Hive.openBox(StorageKeys.deviceBox);
  }

  Future<void> saveDeviceCode(String deviceCode) async {
    final box = await _openBox();
    await box.put(StorageKeys.deviceCode, deviceCode);
  }

  Future<String> getDeviceCode() async {
    final box = await _openBox();
    return box.get(StorageKeys.deviceCode);
  }

  Future<void> saveDeviceToken(String deviceToken) async {
    final box = await _openBox();
    await box.put(StorageKeys.deviceToken, deviceToken);
  }

  Future<String?> getDeviceToken() async {
    final box = await _openBox();
    return box.get(StorageKeys.deviceToken);
  }

  Future<void> saveDevice({
    required String deviceCode,
    required String deviceToken,
  }) async {
    final box = await _openBox();

    await box.put(StorageKeys.deviceCode, deviceCode);
    await box.put(StorageKeys.deviceToken, deviceToken);
  }

  Future<bool> hasDeviceToken() async {
    final deviceToken = await getDeviceToken();
    return deviceToken != null && deviceToken.isNotEmpty;
  }

  Future<void> clearDevice() async {
    final box = await _openBox();
    await box.delete(StorageKeys.deviceCode);
    await box.delete(StorageKeys.deviceToken);
  }
}
