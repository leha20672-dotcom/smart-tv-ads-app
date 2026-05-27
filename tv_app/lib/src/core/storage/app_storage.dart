import 'package:hive_flutter/hive_flutter.dart';

import 'storage_keys.dart';

class AppStorage {
  AppStorage(this._box);

  final Box<dynamic> _box;

  String? getString(String key) => _box.get(key) as String?;

  dynamic getValue(String key) => _box.get(key);

  Future<void> setString(String key, String value) {
    return _box.put(key, value);
  }

  Future<void> setValue(String key, dynamic value) {
    return _box.put(key, value);
  }

  Future<void> clearDevice() async {
    await _box.delete(StorageKeys.deviceCode);
    await _box.delete(StorageKeys.deviceName);
  }
}
