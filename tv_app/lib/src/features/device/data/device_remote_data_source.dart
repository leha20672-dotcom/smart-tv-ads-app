import '../../../core/network/api_client.dart';
import '../domain/device.dart';

class DeviceRemoteDataSource {
  DeviceRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<DeviceRegistration> registerDevice({
    required String deviceCode,
    required String name,
    String? ipAddress,
  }) async {
    final response = await _apiClient.post(
      '/register-device',
      body: {
        'device_code': deviceCode,
        'name': name,
        if (ipAddress != null && ipAddress.isNotEmpty) 'ip_address': ipAddress,
      },
    );

    return DeviceRegistration.fromJson(
      json: response,
      deviceCode: deviceCode,
      name: name,
    );
  }

  Future<DevicePairingStatus> checkPairing({
    required String deviceCode,
    required String name,
  }) async {
    final response = await _apiClient.post(
      '/register-device',
      body: {'device_code': deviceCode, 'name': name},
    );

    return DevicePairingStatus.fromJson(response);
  }
}
