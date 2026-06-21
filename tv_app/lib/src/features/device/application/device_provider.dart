import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/device_local_data_source.dart';
import '../data/device_remote_data_source.dart';
import '../data/device_repository.dart';
import '../domain/device.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final deviceLocalDataSourceProvider = Provider<DeviceLocalDataSource>((ref) {
  return DeviceLocalDataSource();
});

final deviceRemoteDataSourceProvider = Provider<DeviceRemoteDataSource>((ref) {
  return DeviceRemoteDataSource(ref.read(apiClientProvider));
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(
    localDataSource: ref.read(deviceLocalDataSourceProvider),
    remoteDataSource: ref.read(deviceRemoteDataSourceProvider),
  );
});

final deviceIdProvider = FutureProvider<int?>((ref) async {
  final repository = ref.read(deviceRepositoryProvider);
  return repository.getDeviceId();
});

final deviceCodeProvider = FutureProvider<String?>((ref) async {
  final repository = ref.read(deviceRepositoryProvider);
  return repository.getDeviceCode();
});

final deviceTokenProvider = FutureProvider<String?>((ref) async {
  final repository = ref.read(deviceRepositoryProvider);
  return repository.getDeviceToken();
});

final deviceStatusProvider = FutureProvider<String?>((ref) async {
  final repository = ref.read(deviceRepositoryProvider);
  return repository.getDeviceStatus();
});

final registerDeviceProvider =
    FutureProvider.family<Device, RegisterDeviceParams>((ref, params) async {
      final repository = ref.read(deviceRepositoryProvider);

      return repository.createDevice(
        authToken: params.authToken,
        name: params.name,
        type: params.type,
      );
    });

class RegisterDeviceParams {
  const RegisterDeviceParams({
    required this.authToken,
    required this.name,
    this.type = 'android_box',
  });

  final String authToken;
  final String name;
  final String type;
}
