import '../domain/device_heartbeat.dart';
import 'heartbeat_local_data_source.dart';
import 'heartbeat_remote_data_source.dart';

import 'package:flutter/foundation.dart';

class HeartbeatRepository {
  HeartbeatRepository({
    required HeartbeatLocalDataSource localDataSource,
    required HeartbeatRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  final HeartbeatLocalDataSource _localDataSource;
  final HeartbeatRemoteDataSource _remoteDataSource;

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

  Future<DeviceHeartbeat> sendHeartbeat({
    required int deviceId,
    required String deviceToken,
    required String? apiToken,
    String? ipAddress,
  }) async {
    final heartbeat = await sendLocalHeartbeat(
      deviceToken: deviceToken,
      ipAddress: ipAddress,
    );

    if (apiToken == null || apiToken.isEmpty) {
      return heartbeat;
    }

    try {
      await _remoteDataSource.sendHeartbeat(
        deviceId: deviceId,
        apiToken: apiToken,
      );
    } catch (_) {
      debugPrint('Remote heartbeat failed; local heartbeat saved.');
    }

    return heartbeat;
  }

  Future<DeviceHeartbeat?> getLastHeartbeat(String deviceToken) {
    return _localDataSource.getLastHeartbeat(deviceToken);
  }

  Future<void> clearHeartbeat() {
    return _localDataSource.clearHeartbeat();
  }
}
