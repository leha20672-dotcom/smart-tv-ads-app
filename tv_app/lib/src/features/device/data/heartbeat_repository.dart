import '../domain/device_heartbeat.dart';
import 'heartbeat_local_data_source.dart';

import 'package:flutter/foundation.dart';

class HeartbeatRepository {
  HeartbeatRepository(this._localDataSource);

  final HeartbeatLocalDataSource _localDataSource;

  Future<DeviceHeartbeat> sendLocalHeartbeat({
    required String deviceToken,
    String? ipAddress,
  }) async {
    final heartbeat = DeviceHeartbeat(
      deviceToken: deviceToken,
      status: 'online',
      lastConnectedAt: DateTime.now(),
      ipAddress: ipAddress,
    );

    await _localDataSource.saveHeartbeat(heartbeat);

    debugPrint('Heartbeat: ${heartbeat.status} - ${heartbeat.lastConnectedAt}');
    return heartbeat;
  }

  Future<DeviceHeartbeat?> getLastHeartbeat(String deviceToken) {
    return _localDataSource.getLastHeartbeat(deviceToken);
  }

  Future<void> clearHeartbeat() {
    return _localDataSource.clearHeartbeat();
  }
}
