import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/heartbeat_local_data_source.dart';
import '../data/heartbeat_remote_data_source.dart';
import '../data/heartbeat_repository.dart';
import 'device_provider.dart';

final heartbeatLocalDataSourceProvider = Provider<HeartbeatLocalDataSource>((
  ref,
) {
  return HeartbeatLocalDataSource();
});

final heartbeatRemoteDataSourceProvider = Provider<HeartbeatRemoteDataSource>((
  ref,
) {
  return HeartbeatRemoteDataSource(ref.read(apiClientProvider));
});

final heartbeatRepositoryProvider = Provider<HeartbeatRepository>((ref) {
  return HeartbeatRepository(
    localDataSource: ref.read(heartbeatLocalDataSourceProvider),
    remoteDataSource: ref.read(heartbeatRemoteDataSourceProvider),
  );
});

final lastHeartbeatProvider = FutureProvider.family<DateTime?, String>((
  ref,
  deviceToken,
) async {
  final repository = ref.read(heartbeatRepositoryProvider);
  final heartbeat = await repository.getLastHeartbeat(deviceToken);

  return heartbeat?.lastConnectedAt;
});

final heartbeatTimerProvider =
    Provider.family<HeartbeatTimerController, HeartbeatTimerParams>((
      ref,
      params,
    ) {
      final repository = ref.read(heartbeatRepositoryProvider);

      final controller = HeartbeatTimerController(
        repository: repository,
        params: params,
      );

      ref.onDispose(controller.dispose);

      return controller;
    });

class HeartbeatTimerController {
  HeartbeatTimerController({required this.repository, required this.params});

  final HeartbeatRepository repository;
  final HeartbeatTimerParams params;

  Timer? _timer;

  void start() {
    _timer?.cancel();

    _sendHeartbeat();

    _timer = Timer.periodic(const Duration(minutes: 10), (_) {
      _sendHeartbeat();
    });
  }

  Future<void> _sendHeartbeat() async {
    await repository.sendHeartbeat(
      deviceToken: params.deviceToken,
      ipAddress: null,
    );
  }

  void dispose() {
    _timer?.cancel();
  }
}

class HeartbeatTimerParams {
  const HeartbeatTimerParams({required this.deviceToken});

  final String deviceToken;

  @override
  bool operator ==(Object other) {
    return other is HeartbeatTimerParams && other.deviceToken == deviceToken;
  }

  @override
  int get hashCode => deviceToken.hashCode;
}
