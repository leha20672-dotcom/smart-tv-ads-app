import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../domain/playback_log.dart';

class PlaybackLogRemoteDataSource {
  PlaybackLogRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<void> sendCompletedLog({
    required PlaybackLog log,
    required int deviceId,
    required String apiToken,
  }) async {
    final playedAt = log.endedAt ?? DateTime.now();

    await _apiClient.post(
      '/log-media',
      bearerToken: apiToken,
      body: {
        'box_id': deviceId,
        'media_id': log.mediaId,
        'played_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(playedAt),
      },
    );
  }
}
