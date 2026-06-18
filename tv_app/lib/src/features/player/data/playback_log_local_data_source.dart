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

  Future<List<PlaybackLog>> getUnsyncedLogs() async {
    final logs = await getLogs();

    // Hiện tại chưa có field is_synced
    // Tạm thời lấy các log completed/failed để sau này gửi API
    return logs.where(
      (log) => 
          log.status == PlaybackLogStatus.completed ||
          log.status == PlaybackLogStatus.failed,
    ).toList();
  }

  Future<void> clearLogs() async {
    final box = await _openBox();

    await box.delete(StorageKeys.playbackLogs);
  }
}