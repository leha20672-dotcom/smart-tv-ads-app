import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/playback_log_local_data_source.dart';
import '../data/playback_log_repository.dart';
import '../domain/playback_log.dart';

final playbackLogLocalDataSourceProvider = Provider<PlaybackLogLocalDataSource>((ref) {
    return PlaybackLogLocalDataSource();
});

final playbackLogRepositoryProvider = Provider<PlaybackLogRepository>((ref) {
    return PlaybackLogRepository(
        ref.read(playbackLogLocalDataSourceProvider),
    );
});

final playbackLogsProvider = FutureProvider<List<PlaybackLog>>((ref) async {
    final repository = ref.read(playbackLogRepositoryProvider);
    return repository.getLogs();
});