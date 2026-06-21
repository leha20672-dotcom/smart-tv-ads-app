import '../../../core/network/api_client.dart';
import '../domain/auth_session.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/login',
      body: {'email': email, 'password': password},
    );

    return AuthSession.fromJson(response);
  }
}
