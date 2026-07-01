import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../device/application/device_provider.dart';
import '../data/media_cache_service.dart';
import '../data/schedule_local_data_source.dart';
import '../data/schedule_repository.dart';
import '../data/schedule_remote_data_source.dart';
import '../domain/playable_media.dart';

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

final mediaCacheServiceProvider = Provider<MediaCacheService>((ref) {
  return MediaCacheService();
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(
    localDataSource: ref.read(scheduleLocalDataSourceProvider),
    mediaCacheService: ref.read(mediaCacheServiceProvider),
    remoteDataSource: ref.read(scheduleRemoteDataSourceProvider),
  );
});

final currentPlaylistProvider = FutureProvider<List<PlayableMedia>>((
  ref,
) async {
  final repository = ref.read(scheduleRepositoryProvider);
  final deviceRepository = ref.read(deviceRepositoryProvider);
  final apiToken = await deviceRepository.getDeviceToken();

  return repository.getCurrentPlaylist(apiToken: apiToken);
});

final scheduleRefreshIntervalProvider = FutureProvider<Duration>((ref) async {
  final repository = ref.read(scheduleRepositoryProvider);
  final deviceRepository = ref.read(deviceRepositoryProvider);
  final apiToken = await deviceRepository.getDeviceToken();

  return repository.getScheduleRefreshInterval(apiToken: apiToken);
});

final serverClockOffsetProvider = FutureProvider<Duration>((ref) async {
  final repository = ref.read(scheduleRepositoryProvider);
  final deviceRepository = ref.read(deviceRepositoryProvider);
  final apiToken = await deviceRepository.getDeviceToken();

  return repository.getServerClockOffset(apiToken: apiToken);
});
