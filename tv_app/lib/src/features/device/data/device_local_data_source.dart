import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/storage_keys.dart';
import '../domain/device.dart';

class DeviceLocalDataSource {
  Future<Box> _openBox() async {
    return Hive.openBox(StorageKeys.deviceBox);
  }

  Future<void> saveDevice(Device device) async {
    final box = await _openBox();

    await box.put(StorageKeys.deviceId, device.id);
    await box.put(StorageKeys.deviceCode, device.deviceCode);
    await box.put(StorageKeys.deviceName, device.name);
  }

  Future<int?> getDeviceId() async {
    final box = await _openBox();
    return box.get(StorageKeys.deviceId);
  }

  Future<String?> getDeviceCode() async {
    final box = await _openBox();
    return box.get(StorageKeys.deviceCode);
  }

  Future<String?> getDeviceName() async {
    final box = await _openBox();
    return box.get(StorageKeys.deviceName);
  }

  Future<bool> hasDevice() async {
    final deviceId = await getDeviceId();
    final deviceCode = await getDeviceCode();

    return deviceId != null && deviceCode != null && deviceCode.isNotEmpty;
  }

  Future<void> clearDevice() async {
    final box = await _openBox();

    await box.delete(StorageKeys.deviceId);
    await box.delete(StorageKeys.deviceCode);
    await box.delete(StorageKeys.deviceName);
  }
}