import 'package:uuid/uuid.dart';

import '../domain/device.dart';
import 'device_local_data_source.dart';
import 'device_remote_data_source.dart';

class DeviceRepository {
  DeviceRepository({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  final DeviceLocalDataSource localDataSource;
  final DeviceRemoteDataSource remoteDataSource;

  Future<DeviceRegistration> registerDevice({
    required String name,
    String? deviceCode,
  }) async {
    final normalizedDeviceCode = deviceCode?.trim().isNotEmpty == true
        ? deviceCode!.trim()
        : await _getOrCreateDeviceCode();

    await localDataSource.savePendingDevice(
      deviceCode: normalizedDeviceCode,
      name: name,
      status: DeviceStatus.pending,
    );

    final registration = await remoteDataSource.registerDevice(
      deviceCode: normalizedDeviceCode,
      name: name,
    );

    await localDataSource.savePendingDevice(
      deviceCode: registration.deviceCode,
      name: registration.name,
      status: registration.status,
      pairingCode: registration.pairingCode,
    );

    final deviceToken = registration.deviceToken;
    if (deviceToken != null && deviceToken.isNotEmpty) {
      await localDataSource.saveDeviceToken(deviceToken);
    }

    return registration;
  }

  Future<int?> getDeviceId() {
    return localDataSource.getDeviceId();
  }

  Future<String?> getDeviceCode() {
    return localDataSource.getDeviceCode();
  }

  Future<String?> getDeviceName() {
    return localDataSource.getDeviceName();
  }

  Future<String?> getDeviceStatus() {
    return localDataSource.getDeviceStatus();
  }

  Future<String?> getDevicePairingCode() {
    return localDataSource.getDevicePairingCode();
  }

  Future<String?> getDeviceToken() {
    return localDataSource.getDeviceToken();
  }

  Future<String?> restoreDeviceTokenIfPossible() async {
    final storedToken = await getDeviceToken();
    if (storedToken != null && storedToken.isNotEmpty) {
      return storedToken;
    }

    final deviceCode = await getDeviceCode();
    if (deviceCode == null || deviceCode.isEmpty) {
      return null;
    }

    try {
      final pairingStatus = await checkPairing();

      if (pairingStatus.deviceToken != null &&
          pairingStatus.deviceToken!.isNotEmpty) {
        return pairingStatus.deviceToken;
      }
    } catch (_) {
      // Keep the app on the pairing screen if the API is offline; the stored
      // device code will be reused for the next automatic/manual check.
    }

    return getDeviceToken();
  }

  Future<DevicePairingStatus> checkPairing() async {
    final deviceCode = await getDeviceCode();

    if (deviceCode == null || deviceCode.isEmpty) {
      throw Exception('Missing device code');
    }

    final deviceName = await localDataSource.getDeviceName();

    final pairingStatus = await remoteDataSource.checkPairing(
      deviceCode: deviceCode,
      name: deviceName?.isNotEmpty == true ? deviceName! : deviceCode,
    );

    await localDataSource.updateDeviceStatus(pairingStatus.status);

    final deviceToken = pairingStatus.deviceToken;
    if (deviceToken != null && deviceToken.isNotEmpty) {
      await localDataSource.saveDeviceToken(deviceToken);
    }

    return pairingStatus;
  }

  Future<void> clearDevice() {
    return localDataSource.clearDevice();
  }

  Future<String> _getOrCreateDeviceCode() async {
    final existingCode = await getDeviceCode();

    if (existingCode != null && existingCode.isNotEmpty) {
      return existingCode;
    }

    final code = const Uuid().v4().replaceAll('-', '').substring(0, 16);

    return 'BOX-${code.toUpperCase()}';
  }
}
