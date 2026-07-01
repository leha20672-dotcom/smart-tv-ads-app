import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/storage_keys.dart';
import '../domain/playback_log.dart';

class PlaybackLogLocalDataSource {
  Future<Box> _openBox() async {
    return Hive.openBox(StorageKeys.playbackLogBox);
  }

  Future<void> saveLog(PlaybackLog log) async {
    final box = await _openBox();

    final logs = await getLogs();

    final index = logs.indexWhere((item) => item.id == log.id);

    if (index >= 0) {
      logs[index] = log;
    } else {
      logs.add(log);
    }

    final jsonList = logs.map((item) => item.toJson()).toList();

    await box.put(StorageKeys.playbackLogs, jsonList);
  }

  Future<List<PlaybackLog>> getLogs() async {
    final box = await _openBox();

    final rawList = box.get(StorageKeys.playbackLogs);

    if (rawList == null) return [];

    return List<Map<String, dynamic>>.from(
      rawList.map((item) => Map<String, dynamic>.from(item)),
    ).map(PlaybackLog.fromJson).toList();
  }

  Future<List<PlaybackLog>> getPendingSyncLogs({
    DateTime? now,
    int limit = 20,
  }) async {
    final logs = await getLogs();
    final currentTime = now ?? DateTime.now();

    final pendingLogs = logs.where((log) {
      final nextRetryAt = log.nextRetryAt;

      return log.status == PlaybackLogStatus.completed &&
          !log.isSynced &&
          (nextRetryAt == null || !nextRetryAt.isAfter(currentTime));
    }).toList()..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    if (pendingLogs.length <= limit) {
      return pendingLogs;
    }

    return pendingLogs.take(limit).toList();
  }

  Future<void> clearLogs() async {
    final box = await _openBox();

    await box.delete(StorageKeys.playbackLogs);
  }
}
