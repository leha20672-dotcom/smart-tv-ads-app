import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/storage_keys.dart';
import '../domain/device_heartbeat.dart';

class HeartbeatLocalDataSource {
  Future<Box> _openBox() async {
    return Hive.openBox(StorageKeys.heartbeatBox);
  }

  Future<void> saveHeartbeat(DeviceHeartbeat heartbeat) async {
    final box = await _openBox();

    await box.put(StorageKeys.lastConnectedAt, heartbeat.lastConnectedAt.toIso8601String());
    await box.put(StorageKeys.deviceStatus, heartbeat.status);
  }

  Future<DeviceHeartbeat?> getLastHeartbeat(String deviceToken) async {
    final box = await _openBox();

    final lastConnectedAt = box.get(StorageKeys.lastConnectedAt);
    final status = box.get(StorageKeys.deviceStatus);

    if (lastConnectedAt == null || status == null) {
      return null;
    }

    return DeviceHeartbeat(
      deviceToken: deviceToken,
      status: status as String,
      lastConnectedAt: DateTime.parse(lastConnectedAt as String),
    );
  }

  Future<void> clearHeartbeat() async {
    final box = await _openBox();

    await box.delete(StorageKeys.lastConnectedAt);
    await box.delete(StorageKeys.deviceStatus);
  }
}