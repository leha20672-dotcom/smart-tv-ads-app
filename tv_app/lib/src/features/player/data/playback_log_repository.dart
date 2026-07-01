import 'package:uuid/uuid.dart';

import '../../device/data/device_local_data_source.dart';
import '../domain/playback_log.dart';
import 'playback_log_local_data_source.dart';
import 'playback_log_remote_data_source.dart';

class PlaybackLogRepository {
  PlaybackLogRepository({
    required PlaybackLogLocalDataSource localDataSource,
    required PlaybackLogRemoteDataSource remoteDataSource,
    required DeviceLocalDataSource deviceLocalDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _deviceLocalDataSource = deviceLocalDataSource;

  final PlaybackLogLocalDataSource _localDataSource;
  final PlaybackLogRemoteDataSource _remoteDataSource;
  final DeviceLocalDataSource _deviceLocalDataSource;

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
      isSynced: false,
      nextRetryAt: null,
      syncErrorMessage: null,
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

  Future<int> retryPendingLogs({int batchSize = 20}) async {
    final apiToken = await _deviceLocalDataSource.getDeviceToken();

    if (apiToken == null || apiToken.isEmpty) {
      return 0;
    }

    final pendingLogs = await _localDataSource.getPendingSyncLogs(
      limit: batchSize,
    );
    var syncedCount = 0;

    for (final log in pendingLogs) {
      final didSync = await _sendCompletedLog(log: log, apiToken: apiToken);

      if (didSync) {
        syncedCount++;
      }
    }

    return syncedCount;
  }

  Future<void> _trySendCompletedLog(PlaybackLog log) async {
    final apiToken = await _deviceLocalDataSource.getDeviceToken();

    if (apiToken == null || apiToken.isEmpty) {
      return;
    }

    await _sendCompletedLog(log: log, apiToken: apiToken);
  }

  Future<bool> _sendCompletedLog({
    required PlaybackLog log,
    required String apiToken,
  }) async {
    final now = DateTime.now();

    try {
      await _remoteDataSource.sendCompletedLog(log: log, apiToken: apiToken);

      await _localDataSource.saveLog(
        log.copyWith(
          isSynced: true,
          lastSyncAttemptAt: now,
          nextRetryAt: null,
          syncErrorMessage: null,
        ),
      );

      return true;
    } catch (error) {
      final attempts = log.syncAttempts + 1;

      await _localDataSource.saveLog(
        log.copyWith(
          isSynced: false,
          syncAttempts: attempts,
          lastSyncAttemptAt: now,
          nextRetryAt: now.add(_retryDelay(attempts)),
          syncErrorMessage: error.toString(),
        ),
      );

      return false;
    }
  }

  Duration _retryDelay(int attempts) {
    if (attempts <= 1) return const Duration(minutes: 1);
    if (attempts == 2) return const Duration(minutes: 2);
    if (attempts == 3) return const Duration(minutes: 5);
    if (attempts == 4) return const Duration(minutes: 15);
    return const Duration(minutes: 30);
  }
}
