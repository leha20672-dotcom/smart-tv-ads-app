import '../../../core/network/api_client.dart';
import '../domain/device.dart';

class DeviceRemoteDataSource {
  DeviceRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Device> registerDevice({
    required String deviceCode,
    required String name,
    String orientation = 'landscape',
  }) async {
    final response = await _apiClient.post(
      '/devices/register',
      body: {
        'device_code': deviceCode,
        'name': name,
        'orientation': orientation,
      },
    );

    return Device.fromJson(response['data'] as Map<String, dynamic>);
  }
}