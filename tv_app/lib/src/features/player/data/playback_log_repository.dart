import 'package:uuid/uuid.dart';

import '../domain/playback_log.dart';
import 'playback_log_local_data_source.dart';

class PlaybackLogRepository {
  PlaybackLogRepository(this._localDataSource);

  final PlaybackLogLocalDataSource _localDataSource;

  Future<PlaybackLog> startLog({
    required int scheduleId,
    required int mediaId,
  }) async {
    final log = PlaybackLog(
      id: const Uuid().v4(),
      scheduleId:scheduleId,
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
}