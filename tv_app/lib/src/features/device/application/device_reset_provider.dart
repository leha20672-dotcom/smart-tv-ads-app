import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    await deviceRepository.clearDevice();
    await heartbeatRepository.clearHeartbeat();

    ref.invalidate(deviceCodeProvider);
  }
}