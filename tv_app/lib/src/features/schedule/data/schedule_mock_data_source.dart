import '../domain/address_schedule.dart';
import '../domain/media.dart';
import '../domain/schedule.dart';
import '../domain/schedule_media.dart';
import 'mock_schedule_data.dart';

class ScheduleMockDataSource {
  Future<int?> getDeviceAddressId(int deviceId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return mockDeviceJson['address_id'] as int?;
  }

  Future<List<AddressSchedule>> getAddressSchedules() async {
    return mockAddressScheduleJson
        .map((json) => AddressSchedule.fromJson(json))
        .toList();
  }

  Future<List<Schedule>> getSchedules() async {
    return mockSchedulesJson.map((json) => Schedule.fromJson(json)).toList();
  }

  Future<List<ScheduleMedia>> getScheduleMedia() async {
    return mockScheduleMediaJson
        .map((json) => ScheduleMedia.fromJson(json))
        .toList();
  }

  Future<List<Media>> getMedia() async {
    return mockMediaJson.map((json) => Media.fromJson(json)).toList();
  }
}
