import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/storage_keys.dart';
import '../domain/address_schedule.dart';
import '../domain/media.dart';
import '../domain/playable_media.dart';
import '../domain/schedule.dart';
import '../domain/schedule_media.dart';

class ScheduleLocalDataSource {
  Future<Box> _openBox() async {
    return Hive.openBox(StorageKeys.scheduleBox);
  }

  Future<void> cacheAddressSchedules(
    List<AddressSchedule> addressSchedules,
  ) async {
    final box = await _openBox();

    final jsonList = addressSchedules.map((item) => item.toJson()).toList();

    await box.put(StorageKeys.addressSchedules, jsonList);
  }

  Future<void> cacheSchedules(List<Schedule> schedules) async {
    final box = await _openBox();

    final jsonList = schedules.map((item) => item.toJson()).toList();

    await box.put(StorageKeys.schedules, jsonList);
  }

  Future<void> cacheScheduleMedia(List<ScheduleMedia> scheduleMedia) async {
    final box = await _openBox();

    final jsonList = scheduleMedia.map((item) => item.toJson()).toList();

    await box.put(StorageKeys.scheduleMedia, jsonList);
  }

  Future<void> cacheMedia(List<Media> mediaList) async {
    final box = await _openBox();

    final jsonList = mediaList.map((item) => item.toJson()).toList();

    await box.put(StorageKeys.media, jsonList);
  }

  Future<void> cacheCurrentPlaylist(List<PlayableMedia> playlist) async {
    final box = await _openBox();

    final jsonList = playlist.map((item) => item.toJson()).toList();

    await box.put(StorageKeys.currentPlaylist, jsonList);
  }

  Future<List<AddressSchedule>> getCacheAddressSchedules() async {
    final box = await _openBox();

    final rawList = box.get(StorageKeys.addressSchedules);

    if (rawList == null) return [];

    return List<Map<String, dynamic>>.from(
      rawList.map((item) => Map<String, dynamic>.from(item)),
    ).map(AddressSchedule.fromJson).toList();
  }

  Future<List<Schedule>> getCachedSchedules() async {
    final box = await _openBox();

    final rawList = box.get(StorageKeys.schedules);

    if (rawList == null) return [];

    return List<Map<String, dynamic>>.from(
      rawList.map((item) => Map<String, dynamic>.from(item)),
    ).map(Schedule.fromJson).toList();
  }

  Future<List<ScheduleMedia>> getCachedScheduleMedia() async {
    final box = await _openBox();

    final rawList = box.get(StorageKeys.scheduleMedia);

    if (rawList == null) return [];

    return List<Map<String, dynamic>>.from(
      rawList.map((item) => Map<String, dynamic>.from(item)),
    ).map(ScheduleMedia.fromJson).toList();
  }

  Future<List<Media>> getCachedMedia() async {
    final box = await _openBox();

    final rawList = box.get(StorageKeys.media);

    if (rawList == null) return [];

    return List<Map<String, dynamic>>.from(
      rawList.map((item) => Map<String, dynamic>.from(item)),
    ).map(Media.fromJson).toList();
  }

  Future<List<PlayableMedia>> getCachedCurrentPlaylist() async {
    final box = await _openBox();

    final rawList = box.get(StorageKeys.currentPlaylist);

    if (rawList == null) return [];

    return List<Map<String, dynamic>>.from(
      rawList.map((item) => Map<String, dynamic>.from(item)),
    ).map(PlayableMedia.fromJson).toList();
  }

  Future<void> clearScheduleCache() async {
    final box = await _openBox();

    await box.delete(StorageKeys.addressSchedules);
    await box.delete(StorageKeys.schedules);
    await box.delete(StorageKeys.scheduleMedia);
    await box.delete(StorageKeys.media);
    await box.delete(StorageKeys.currentPlaylist);
  }
}
