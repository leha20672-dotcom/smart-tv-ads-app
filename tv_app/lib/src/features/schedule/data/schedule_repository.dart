import '../domain/address_schedule.dart';
import '../domain/media.dart';
import '../domain/schedule.dart';
import '../domain/schedule_media.dart';
import 'schedule_local_data_source.dart';
import 'schedule_mock_data_source.dart';

class ScheduleRepository {
  ScheduleRepository({
    required ScheduleMockDataSource mockDataSource,
    required ScheduleLocalDataSource localDataSource,
  }) : _mockDataSource = mockDataSource,
       _localDataSource = localDataSource;

  final ScheduleMockDataSource _mockDataSource;
  final ScheduleLocalDataSource _localDataSource;

  Future<int?> getDeviceAddressId(int deviceId) {
    return _mockDataSource.getDeviceAddressId(deviceId);
  }

  Future<List<AddressSchedule>> getAddressSchedules() async {
    try {
      final data = await _mockDataSource.getAddressSchedules();
      await _localDataSource.cacheAddressSchedules(data);
      return data;
    } catch (_) {
      return _localDataSource.getCacheAddressSchedules();
    }
  }

  Future<List<Schedule>> getSchedules() async {
    try {
      final data = await _mockDataSource.getSchedules();
      await _localDataSource.cacheSchedules(data);
      return data;
    } catch (_) {
      return _localDataSource.getCachedSchedules();
    }
  }

  Future<List<ScheduleMedia>> getScheduleMedia() async {
    try {
      final data = await _mockDataSource.getScheduleMedia();
      await _localDataSource.cacheScheduleMedia(data);
      return data;
    } catch (_) {
      return _localDataSource.getCachedScheduleMedia();
    }
  }

  Future<List<Media>> getMedia() async {
    try {
      final data = await _mockDataSource.getMedia();
      await _localDataSource.cacheMedia(data);
      return data;
    } catch (_) {
      return _localDataSource.getCachedMedia();
    }
  }
}
