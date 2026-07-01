import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/storage_keys.dart';
import '../domain/playable_media.dart';

class ScheduleLocalDataSource {
  Future<Box> _openBox() async {
    return Hive.openBox(StorageKeys.scheduleBox);
  }

  Future<void> cacheCurrentPlaylist(List<PlayableMedia> playlist) async {
    final box = await _openBox();

    final jsonList = playlist.map((item) => item.toJson()).toList();

    await box.put(StorageKeys.currentPlaylist, jsonList);
  }

  Future<void> cacheScheduleRefreshInterval(Duration interval) async {
    final box = await _openBox();

    await box.put(
      StorageKeys.scheduleRefreshIntervalSeconds,
      interval.inSeconds,
    );
  }

  Future<List<PlayableMedia>> getCachedCurrentPlaylist() async {
    final box = await _openBox();

    final rawList = box.get(StorageKeys.currentPlaylist);

    if (rawList == null) return [];

    return List<Map<String, dynamic>>.from(
      rawList.map((item) => Map<String, dynamic>.from(item)),
    ).map(PlayableMedia.fromJson).toList();
  }

  Future<Duration?> getCachedScheduleRefreshInterval() async {
    final box = await _openBox();
    final seconds = box.get(StorageKeys.scheduleRefreshIntervalSeconds);

    if (seconds is int && seconds > 0) {
      return Duration(seconds: seconds);
    }

    if (seconds is num && seconds > 0) {
      return Duration(seconds: seconds.toInt());
    }

    return null;
  }

  Future<void> cacheServerClockOffset(Duration offset) async {
    final box = await _openBox();

    await box.put(
      StorageKeys.serverClockOffsetMilliseconds,
      offset.inMilliseconds,
    );
  }

  Future<Duration?> getCachedServerClockOffset() async {
    final box = await _openBox();
    final milliseconds = box.get(StorageKeys.serverClockOffsetMilliseconds);

    if (milliseconds is int) {
      return Duration(milliseconds: milliseconds);
    }

    if (milliseconds is num) {
      return Duration(milliseconds: milliseconds.toInt());
    }

    return null;
  }

  Future<void> clearScheduleCache() async {
    final box = await _openBox();

    await box.delete(StorageKeys.currentPlaylist);
    await box.delete(StorageKeys.scheduleRefreshIntervalSeconds);
    await box.delete(StorageKeys.serverClockOffsetMilliseconds);
  }
}
