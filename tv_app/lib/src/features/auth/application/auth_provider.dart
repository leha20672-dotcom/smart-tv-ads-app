import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../device/application/device_provider.dart';
import '../data/auth_local_data_source.dart';
import '../data/auth_remote_data_source.dart';
import '../data/auth_repository.dart';
import '../domain/auth_session.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.read(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    localDataSource: ref.read(authLocalDataSourceProvider),
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
  );
});

final authTokenProvider = FutureProvider<String?>((ref) async {
  final repository = ref.read(authRepositoryProvider);
  return repository.getToken();
});

final authUserProvider = FutureProvider<AuthUser?>((ref) async {
  final repository = ref.read(authRepositoryProvider);
  return repository.getUser();
});
