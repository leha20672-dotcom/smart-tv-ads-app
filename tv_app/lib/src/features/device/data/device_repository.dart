import '../domain/device.dart';
import 'device_local_data_source.dart';
import 'device_remote_data_source.dart';

class DeviceRepository {
  DeviceRepository({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  final DeviceLocalDataSource localDataSource;
  final DeviceRemoteDataSource remoteDataSource;

  Future<Device> createDevice({
    required String authToken,
    required String name,
    String type = 'android_box',
  }) async {
    final device = await remoteDataSource.createDevice(
      authToken: authToken,
      name: name,
      type: type,
    );

    await localDataSource.saveDevice(device);

    return device;
  }

  Future<int?> getDeviceId() {
    return localDataSource.getDeviceId();
  }

  Future<String?> getDeviceCode() {
    return localDataSource.getDeviceCode();
  }

  Future<String?> getDeviceStatus() {
    return localDataSource.getDeviceStatus();
  }

  Future<String?> getDeviceToken() {
    return localDataSource.getDeviceToken();
  }

  Future<String> refreshDeviceStatus({
    required int deviceId,
    required String authToken,
  }) async {
    final status = await remoteDataSource.getDeviceStatus(
      deviceId: deviceId,
      authToken: authToken,
    );

    await localDataSource.updateDeviceStatus(status);

    return status;
  }

  Future<void> clearDevice() {
    return localDataSource.clearDevice();
  }
}
