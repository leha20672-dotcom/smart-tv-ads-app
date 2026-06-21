import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import 'device_provider.dart';
import 'heartbeat_provider.dart';

final deviceResetProvider = Provider<DeviceResetService>((ref) {
  return DeviceResetService(ref);
});

class DeviceResetService {
  DeviceResetService(this.ref);

  final Ref ref;

  Future<void> resetDevice() async {
    final deviceRepository = ref.read(deviceRepositoryProvider);
    final heartbeatRepository = ref.read(heartbeatRepositoryProvider);
    final authRepository = ref.read(authRepositoryProvider);

    await deviceRepository.clearDevice();
    await heartbeatRepository.clearHeartbeat();
    await authRepository.logout();

    ref.invalidate(appRouteStateProvider);
    ref.invalidate(authTokenProvider);
    ref.invalidate(authUserProvider);
    ref.invalidate(deviceIdProvider);
    ref.invalidate(deviceCodeProvider);
    ref.invalidate(deviceTokenProvider);
    ref.invalidate(deviceStatusProvider);
  }
}
