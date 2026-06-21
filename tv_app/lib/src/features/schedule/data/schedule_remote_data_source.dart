import '../../../core/network/api_client.dart';

class ScheduleRemoteDataSource {

  ScheduleRemoteDataSource(
    this._apiClient,
  );

  final ApiClient _apiClient;

  Future<Map<String,dynamic>>
      getSchedule(
    int deviceId,
  ) {

    return _apiClient.post(
      '/schedule',
      body: {
        'device_id': deviceId,
      },
    );
  }
}