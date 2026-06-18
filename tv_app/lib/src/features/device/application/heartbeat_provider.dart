import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/heartbeat_local_data_source.dart';
import '../data/heartbeat_repository.dart';

final heartbeatLocalDataSourceProvider = Provider<HeartbeatLocalDataSource>((ref) {
  return HeartbeatLocalDataSource();
});
final heartbeatRepositoryProvider = Provider<HeartbeatRepository>((ref) {
  return HeartbeatRepository(
    ref.read(heartbeatLocalDataSourceProvider),
  );
});

final lastHeartbeatProvider = FutureProvider.family<DateTime?, String>((ref, deviceToken) async {
  final repository = ref.read(heartbeatRepositoryProvider);
  final heartbeat = await repository.getLastHeartbeat(deviceToken);

  return heartbeat?.lastConnectedAt;
});

final heartbeatTimerProvider = Provider.family<HeartbeatTimerController, String>((ref, deviceToken) {
  final repository = ref.read(heartbeatRepositoryProvider);

  final controller = HeartbeatTimerController(
    repository: repository,
    deviceToken: deviceToken,
  );

  ref.onDispose(controller.dispose);

  return controller;
});

class HeartbeatTimerController {
  HeartbeatTimerController({
    required this.repository,
    required this.deviceToken,
  });

  final HeartbeatRepository repository;
  final String deviceToken;

  Timer? _timer;

  void start() {
    _timer?.cancel();

    _sendHeartbeat();

    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendHeartbeat();
    });
  }

  Future<void> _sendHeartbeat() async {
    await repository.sendLocalHeartbeat(
      deviceToken: deviceToken,
      ipAddress: null,
    );
  }

  void dispose() {
    _timer?.cancel();
  }
}