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

  Future<Device> registerDevice({
    required String deviceCode,
    required String name,
    String orientation = 'landscape',
  }) async {
    final device = await remoteDataSource.registerDevice(
      deviceCode: deviceCode,
      name: name,
      orientation: orientation,
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

  Future<void> clearDevice() {
    return localDataSource.clearDevice();
  }
}