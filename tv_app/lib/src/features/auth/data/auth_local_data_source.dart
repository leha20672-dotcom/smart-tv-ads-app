import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/storage_keys.dart';
import '../domain/auth_session.dart';

class AuthLocalDataSource {
  Future<Box> _openBox() {
    return Hive.openBox(StorageKeys.authBox);
  }

  Future<void> saveSession(AuthSession session) async {
    final box = await _openBox();

    await box.put(StorageKeys.authToken, session.token);
    await box.put(StorageKeys.authUserId, session.user.id);
    await box.put(StorageKeys.authUserEmail, session.user.email);

    final name = session.user.name;
    if (name != null && name.isNotEmpty) {
      await box.put(StorageKeys.authUserName, name);
    }
  }

  Future<String?> getToken() async {
    final box = await _openBox();
    return box.get(StorageKeys.authToken);
  }

  Future<AuthUser?> getUser() async {
    final box = await _openBox();
    final id = box.get(StorageKeys.authUserId);
    final email = box.get(StorageKeys.authUserEmail);

    if (id == null || email == null) {
      return null;
    }

    return AuthUser(
      id: id is int ? id : int.tryParse('$id') ?? 0,
      email: email as String,
      name: box.get(StorageKeys.authUserName) as String?,
    );
  }

  Future<void> clearSession() async {
    final box = await _openBox();

    await box.delete(StorageKeys.authToken);
    await box.delete(StorageKeys.authUserId);
    await box.delete(StorageKeys.authUserEmail);
    await box.delete(StorageKeys.authUserName);
  }
}
