import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../domain/device_heartbeat.dart';
import 'heartbeat_local_data_source.dart';

class HeartbeatRepository {
  HeartbeatRepository(
    this._localDataSource,
  );

  final HeartbeatLocalDataSource _localDataSource;

  final ApiClient _apiClient = ApiClient();

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

    await _localDataSource.saveHeartbeat(
      heartbeat,
    );

    try {
      await _apiClient.post(
        '/devices/heartbeat',
        body: {
          'device_token': deviceToken,
          'status': 'online',
          'ip_address': ipAddress,
        },
      );

      debugPrint(
        'Heartbeat sent to server',
      );
    } catch (e) {
      debugPrint(
        'Heartbeat Error: $e',
      );
    }

    return heartbeat;
  }

  Future<DeviceHeartbeat?> getLastHeartbeat(
    String deviceToken,
  ) {
    return _localDataSource.getLastHeartbeat(
      deviceToken,
    );
  }

  Future<void> clearHeartbeat() {
    return _localDataSource.clearHeartbeat();
  }
}