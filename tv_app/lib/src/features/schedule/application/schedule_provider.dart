import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/schedule_local_data_source.dart';
import '../data/schedule_mock_data_source.dart';
import '../data/schedule_repository.dart';
import '../domain/playable_media.dart';
import 'schedule_service.dart';

final scheduleMockDataSourceProvider = Provider<ScheduleMockDataSource>((ref) {
  return ScheduleMockDataSource();
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(
    mockDataSource: ref.read(scheduleMockDataSourceProvider),
    localDataSource: ref.read(scheduleLocalDataSourceProvider),
  );
});

final scheduleLocalDataSourceProvider = Provider<ScheduleLocalDataSource>((
  ref,
) {
  return ScheduleLocalDataSource();
});

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService();
});

final currentPlaylistProvider = FutureProvider.family<List<PlayableMedia>, int>(
  (ref, deviceId) async {
    final repository = ref.read(scheduleRepositoryProvider);
    final service = ref.read(scheduleServiceProvider);

    final addressId = await repository.getDeviceAddressId(deviceId);

    if (addressId == null) {
      return [];
    }

    final addressSchedules = await repository.getAddressSchedules();
    final schedules = await repository.getSchedules();
    final scheduleMedia = await repository.getScheduleMedia();
    final mediaList = await repository.getMedia();

    return service.buildCurrentPlaylist(
      addressId: addressId,
      addressSchedule: addressSchedules,
      schedules: schedules,
      scheduleMedia: scheduleMedia,
      mediaList: mediaList,
    );
  },
);
