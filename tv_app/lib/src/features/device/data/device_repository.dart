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

  Future<Device> activateDevice(String deviceCode) async {
    final device = await remoteDataSource.activateDevice(deviceCode);

    await localDataSource.saveDevice(
      deviceCode: device.deviceCode,
      deviceToken: device.deviceToken,
    );
    return device;
  }

  Future<String?> getDeviceToken() {
    return localDataSource.getDeviceToken();
  }

  Future<void> clearDevice() {
    return localDataSource.clearDevice();
  }
}
