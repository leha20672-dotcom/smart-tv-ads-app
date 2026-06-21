import 'package:uuid/uuid.dart';

import '../../auth/data/auth_local_data_source.dart';
import '../../device/data/device_local_data_source.dart';
import '../domain/playback_log.dart';
import 'playback_log_local_data_source.dart';
import 'playback_log_remote_data_source.dart';

class PlaybackLogRepository {
  PlaybackLogRepository({
    required PlaybackLogLocalDataSource localDataSource,
    required PlaybackLogRemoteDataSource remoteDataSource,
    required DeviceLocalDataSource deviceLocalDataSource,
    required AuthLocalDataSource authLocalDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _deviceLocalDataSource = deviceLocalDataSource,
       _authLocalDataSource = authLocalDataSource;

  final PlaybackLogLocalDataSource _localDataSource;
  final PlaybackLogRemoteDataSource _remoteDataSource;
  final DeviceLocalDataSource _deviceLocalDataSource;
  final AuthLocalDataSource _authLocalDataSource;

  Future<PlaybackLog> startLog({
    required int scheduleId,
    required int mediaId,
  }) async {
    final log = PlaybackLog(
      id: const Uuid().v4(),
      scheduleId: scheduleId,
      mediaId: mediaId,
      startedAt: DateTime.now(),
      status: PlaybackLogStatus.playing,
    );

    await _localDataSource.saveLog(log);

    return log;
  }

  Future<void> completeLog(PlaybackLog log) async {
    final updateLog = log.copyWith(
      endedAt: DateTime.now(),
      status: PlaybackLogStatus.completed,
    );

    await _localDataSource.saveLog(updateLog);
    await _trySendCompletedLog(updateLog);
  }

  Future<void> failLog({
    required PlaybackLog log,
    required String errorMessage,
  }) async {
    final updatedLog = log.copyWith(
      endedAt: DateTime.now(),
      status: PlaybackLogStatus.failed,
      errorMessage: errorMessage,
    );

    await _localDataSource.saveLog(updatedLog);
  }

  Future<List<PlaybackLog>> getLogs() {
    return _localDataSource.getLogs();
  }

  Future<void> _trySendCompletedLog(PlaybackLog log) async {
    final apiToken = await _authLocalDataSource.getToken();
    final deviceId = await _deviceLocalDataSource.getDeviceId();

    if (apiToken == null || apiToken.isEmpty || deviceId == null) {
      return;
    }

    try {
      await _remoteDataSource.sendCompletedLog(
        log: log,
        deviceId: deviceId,
        apiToken: apiToken,
      );
    } catch (_) {
      // Local log is already saved; remote sync can be retried later.
    }
  }
}
