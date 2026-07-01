import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../domain/playback_log.dart';

class PlaybackLogRemoteDataSource {
  PlaybackLogRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<void> sendCompletedLog({
    required PlaybackLog log,
    required String apiToken,
  }) async {
    final playedAt = log.endedAt ?? DateTime.now();

    await _apiClient.post(
      '/updateMediaLog',
      bearerToken: apiToken,
      body: {
        'schedule_id': log.scheduleId,
        'logs': [
          {
            'media_id': log.mediaId,
            'played_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(playedAt),
          },
        ],
      },
    );
  }
}
