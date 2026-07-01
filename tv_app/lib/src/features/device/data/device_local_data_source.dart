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
    await box.put(StorageKeys.deviceApprovalStatus, device.status);

    final type = device.type;
    if (type != null && type.isNotEmpty) {
      await box.put(StorageKeys.deviceType, type);
    }

    if (device.apiToken != null && device.apiToken!.isNotEmpty) {
      await box.put(StorageKeys.deviceToken, device.apiToken);
    }
  }

  Future<void> savePendingDevice({
    required String deviceCode,
    required String name,
    required String status,
    String? pairingCode,
  }) async {
    final box = await _openBox();

    await box.put(StorageKeys.deviceCode, deviceCode);
    await box.put(StorageKeys.deviceName, name);
    await box.put(StorageKeys.deviceApprovalStatus, status);

    if (pairingCode != null && pairingCode.isNotEmpty) {
      await box.put(StorageKeys.devicePairingCode, pairingCode);
    }
  }

  Future<void> saveDeviceToken(String deviceToken) async {
    final box = await _openBox();

    await box.put(StorageKeys.deviceToken, deviceToken);
    await box.put(StorageKeys.deviceApprovalStatus, DeviceStatus.active);
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

  Future<String?> getDeviceStatus() async {
    final box = await _openBox();
    return box.get(StorageKeys.deviceApprovalStatus);
  }

  Future<String?> getDevicePairingCode() async {
    final box = await _openBox();
    return box.get(StorageKeys.devicePairingCode);
  }

  Future<void> updateDeviceStatus(String status) async {
    final box = await _openBox();
    await box.put(StorageKeys.deviceApprovalStatus, status);
  }

  Future<String?> getDeviceToken() async {
    final box = await _openBox();
    return box.get(StorageKeys.deviceToken);
  }

  Future<bool> hasDevice() async {
    final deviceCode = await getDeviceCode();

    return deviceCode != null && deviceCode.isNotEmpty;
  }

  Future<void> clearDevice() async {
    final box = await _openBox();

    await box.delete(StorageKeys.deviceId);
    await box.delete(StorageKeys.deviceCode);
    await box.delete(StorageKeys.deviceName);
    await box.delete(StorageKeys.deviceType);
    await box.delete(StorageKeys.deviceApprovalStatus);
    await box.delete(StorageKeys.devicePairingCode);
    await box.delete(StorageKeys.deviceToken);
  }
}
