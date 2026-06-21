import '../domain/auth_session.dart';
import 'auth_local_data_source.dart';
import 'auth_remote_data_source.dart';

class AuthRepository {
  AuthRepository({
    required AuthLocalDataSource localDataSource,
    required AuthRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _remoteDataSource.login(
      email: email,
      password: password,
    );

    await _localDataSource.saveSession(session);

    return session;
  }

  Future<String?> getToken() {
    return _localDataSource.getToken();
  }

  Future<AuthUser?> getUser() {
    return _localDataSource.getUser();
  }

  Future<void> logout() {
    return _localDataSource.clearSession();
  }
}
