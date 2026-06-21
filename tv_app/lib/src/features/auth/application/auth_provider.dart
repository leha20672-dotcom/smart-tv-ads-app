import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../device/application/device_provider.dart';
import '../../device/domain/device.dart';
import '../data/auth_local_data_source.dart';
import '../data/auth_remote_data_source.dart';
import '../data/auth_repository.dart';
import '../domain/auth_session.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.read(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    localDataSource: ref.read(authLocalDataSourceProvider),
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
  );
});

final authTokenProvider = FutureProvider<String?>((ref) async {
  final repository = ref.read(authRepositoryProvider);
  return repository.getToken();
});

final authUserProvider = FutureProvider<AuthUser?>((ref) async {
  final repository = ref.read(authRepositoryProvider);
  return repository.getUser();
});

final appRouteStateProvider = FutureProvider<AppRouteState>((ref) async {
  final authRepository = ref.read(authRepositoryProvider);
  final deviceRepository = ref.read(deviceRepositoryProvider);

  final token = await authRepository.getToken();
  final deviceId = await deviceRepository.getDeviceId();
  final deviceStatus = await deviceRepository.getDeviceStatus();

  return AppRouteState(
    authToken: token,
    deviceId: deviceId,
    deviceStatus: deviceStatus,
  );
});

class AppRouteState {
  const AppRouteState({
    required this.authToken,
    required this.deviceId,
    required this.deviceStatus,
  });

  final String? authToken;
  final int? deviceId;
  final String? deviceStatus;

  bool get hasAuthToken => authToken != null && authToken!.isNotEmpty;

  bool get canPlay {
    return hasAuthToken &&
        deviceId != null &&
        DeviceStatus.isActive(deviceStatus);
  }
}
