import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../../device/application/device_provider.dart';
import '../data/schedule_local_data_source.dart';
import '../data/schedule_mock_data_source.dart';
import '../data/schedule_repository.dart';
import '../data/schedule_remote_data_source.dart';
import '../domain/playable_media.dart';
import 'schedule_service.dart';

final scheduleMockDataSourceProvider = Provider<ScheduleMockDataSource>((ref) {
  return ScheduleMockDataSource();
});

final scheduleLocalDataSourceProvider = Provider<ScheduleLocalDataSource>((
  ref,
) {
  return ScheduleLocalDataSource();
});

final scheduleRemoteDataSourceProvider = Provider<ScheduleRemoteDataSource>((
  ref,
) {
  return ScheduleRemoteDataSource(ref.read(apiClientProvider));
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(
    mockDataSource: ref.read(scheduleMockDataSourceProvider),
    localDataSource: ref.read(scheduleLocalDataSourceProvider),
    remoteDataSource: ref.read(scheduleRemoteDataSourceProvider),
  );
});

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService();
});

final currentPlaylistProvider = FutureProvider.family<List<PlayableMedia>, int>(
  (ref, deviceId) async {
    final repository = ref.read(scheduleRepositoryProvider);
    final authRepository = ref.read(authRepositoryProvider);
    final apiToken = await authRepository.getToken();

    return repository.getCurrentPlaylist(
      deviceId: deviceId,
      apiToken: apiToken,
    );
  },
);
