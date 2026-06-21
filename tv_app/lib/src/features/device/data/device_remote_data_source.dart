import '../../../core/network/api_client.dart';
import '../domain/device.dart';

class DeviceRemoteDataSource {
  DeviceRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Device> createDevice({
    required String authToken,
    required String name,
    String type = 'android_box',
  }) async {
    final response = await _apiClient.post(
      '/devices',
      bearerToken: authToken,
      body: {'name': name, 'type': type},
    );

    final data = _extractDeviceJson(response);
    data.putIfAbsent('name', () => name);
    data.putIfAbsent('type', () => type);

    return Device.fromJson(data);
  }

  Future<String> getDeviceStatus({
    required int deviceId,
    required String authToken,
  }) async {
    final response = await _apiClient.get(
      '/devices/$deviceId/status',
      bearerToken: authToken,
    );

    return Device.statusFromJson(_extractDeviceJson(response));
  }

  Map<String, dynamic> _extractDeviceJson(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    final device = response['device'];
    if (device is Map) {
      return Map<String, dynamic>.from(device);
    }

    return response;
  }
}
