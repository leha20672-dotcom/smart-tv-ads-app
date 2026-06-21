import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../../device/application/device_provider.dart';
import '../data/playback_log_local_data_source.dart';
import '../data/playback_log_remote_data_source.dart';
import '../data/playback_log_repository.dart';
import '../domain/playback_log.dart';

final playbackLogLocalDataSourceProvider = Provider<PlaybackLogLocalDataSource>(
  (ref) {
    return PlaybackLogLocalDataSource();
  },
);

final playbackLogRemoteDataSourceProvider =
    Provider<PlaybackLogRemoteDataSource>((ref) {
      return PlaybackLogRemoteDataSource(ref.read(apiClientProvider));
    });

final playbackLogRepositoryProvider = Provider<PlaybackLogRepository>((ref) {
  return PlaybackLogRepository(
    localDataSource: ref.read(playbackLogLocalDataSourceProvider),
    remoteDataSource: ref.read(playbackLogRemoteDataSourceProvider),
    deviceLocalDataSource: ref.read(deviceLocalDataSourceProvider),
    authLocalDataSource: ref.read(authLocalDataSourceProvider),
  );
});

final playbackLogsProvider = FutureProvider<List<PlaybackLog>>((ref) async {
  final repository = ref.read(playbackLogRepositoryProvider);
  return repository.getLogs();
});
