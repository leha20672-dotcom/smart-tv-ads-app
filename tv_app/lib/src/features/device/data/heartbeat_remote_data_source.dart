import '../../../core/network/api_client.dart';

class HeartbeatRemoteDataSource {
  HeartbeatRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<void> sendHeartbeat({required String apiToken}) async {
    try {
      await _apiClient.post('/check-status', bearerToken: apiToken);
    } on ApiException catch (error) {
      if (error.statusCode != 404 && error.statusCode != 405) {
        rethrow;
      }

      await _apiClient.post('/devices/ping', bearerToken: apiToken);
    }
  }
}
