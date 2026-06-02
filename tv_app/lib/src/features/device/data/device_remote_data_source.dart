import '../../../core/network/api_client.dart';
import '../domain/device.dart';

class DeviceRemoteDataSource {
  DeviceRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Device> activateDevice(String deviceCode) async {
    final response = await _apiClient.post(
      '/devices/activate',
      body: {'device_code': deviceCode},
    );

    return Device.fromJson(response['data']);
  }
}
