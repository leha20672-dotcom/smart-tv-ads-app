import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/device_local_data_source.dart';
import '../data/device_remote_data_source.dart';
import '../data/device_repository.dart';
import '../domain/device.dart';

final apiClinetProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final deviceLocalDataSourceProvider = Provider<DeviceLocalDataSource>((ref) {
  return DeviceLocalDataSource();
});

final deviceRemoteDataSourceProvider = Provider<DeviceRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClinetProvider);
  return DeviceRemoteDataSource(apiClient);
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(
    localDataSource: ref.read(deviceLocalDataSourceProvider),
    remoteDataSource: ref.read(deviceRemoteDataSourceProvider),
  );
});

final deviceTokenProvider = FutureProvider<String?>((ref) async {
  final localDataSource = ref.read(deviceLocalDataSourceProvider);
  return localDataSource.getDeviceToken();
});

final activateDeviceProvider = FutureProvider.family<Device, String>((
  ref,
  deviceCode,
) async {
  final repository = ref.read(deviceRepositoryProvider);
  return repository.activateDevice(deviceCode);
});
