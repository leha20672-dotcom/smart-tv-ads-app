import '../../../core/network/api_client.dart';

class HeartbeatRemoteDataSource {
  HeartbeatRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<void> sendHeartbeat({
    required int deviceId,
    required String apiToken,
  }) async {
    await _apiClient.post(
      '/check-status',
      bearerToken: apiToken,
      body: {'box_id': deviceId},
    );
  }
}
