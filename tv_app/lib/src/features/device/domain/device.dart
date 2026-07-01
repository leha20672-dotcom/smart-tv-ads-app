class Device {
  const Device({
    required this.id,
    required this.deviceCode,
    required this.name,
    required this.status,
    this.addressId,
    this.type,
    this.orientation,
    this.apiToken,
  });

  final int id;
  final int? addressId;
  final String deviceCode;
  final String name;
  final String status;
  final String? type;
  final String? orientation;
  final String? apiToken;

  factory Device.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['device_id'] ?? json['id']);
    final deviceCode =
        (json['device_code'] ?? json['code'] ?? json['deviceCode']) as String?;

    return Device(
      id: id,
      addressId: _asNullableInt(json['address_id']),
      deviceCode: deviceCode?.isNotEmpty == true ? deviceCode! : 'TV-$id',
      name: (json['name'] ?? json['device_name'] ?? '') as String,
      status: statusFromJson(json),
      type: json['type'] as String?,
      orientation: json['orientation'] as String?,
      apiToken: json['token'] as String?,
    );
  }

  Device copyWith({
    int? id,
    int? addressId,
    String? deviceCode,
    String? name,
    String? status,
    String? type,
    String? orientation,
    String? apiToken,
  }) {
    return Device(
      id: id ?? this.id,
      addressId: addressId ?? this.addressId,
      deviceCode: deviceCode ?? this.deviceCode,
      name: name ?? this.name,
      status: status ?? this.status,
      type: type ?? this.type,
      orientation: orientation ?? this.orientation,
      apiToken: apiToken ?? this.apiToken,
    );
  }

  static String statusFromJson(Map<String, dynamic> json) {
    final rawDeviceStatus = json['device_status'] ?? json['approval_status'];
    if (rawDeviceStatus is String && rawDeviceStatus.isNotEmpty) {
      return rawDeviceStatus.toLowerCase();
    }

    final rawStatus = json['status'];
    if (rawStatus is String &&
        rawStatus.isNotEmpty &&
        rawStatus.toLowerCase() != 'success') {
      return rawStatus.toLowerCase();
    }

    final isApproved = json['is_approved'];
    if (isApproved == true || isApproved == 1 || isApproved == '1') {
      return DeviceStatus.active;
    }
    if (isApproved == false || isApproved == 0 || isApproved == '0') {
      return DeviceStatus.pending;
    }

    final isActive = json['is_active'];
    if (isActive == true || isActive == 1 || isActive == '1') {
      return DeviceStatus.active;
    }
    if (isActive == false || isActive == 0 || isActive == '0') {
      return DeviceStatus.pending;
    }

    return DeviceStatus.pending;
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    final parsed = _asInt(value);
    return parsed == 0 ? null : parsed;
  }
}

class DeviceStatus {
  static const String active = 'active';
  static const String pending = 'pending';

  static bool isActive(String? status) {
    final normalized = status?.toLowerCase();
    return normalized == active ||
        normalized == 'approved' ||
        normalized == 'online' ||
        normalized == '1' ||
        normalized == 'true';
  }
}

class DeviceRegistration {
  const DeviceRegistration({
    required this.deviceCode,
    required this.name,
    required this.status,
    required this.pairingCode,
    this.message,
    this.deviceToken,
    this.expiresAt,
  });

  final String deviceCode;
  final String name;
  final String status;
  final String pairingCode;
  final String? message;
  final String? deviceToken;
  final DateTime? expiresAt;

  factory DeviceRegistration.fromJson({
    required Map<String, dynamic> json,
    required String deviceCode,
    required String name,
  }) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    final expiresAtValue = data['expires_at'];

    return DeviceRegistration(
      deviceCode: deviceCode,
      name: name,
      status: (data['status'] ?? json['status'] ?? DeviceStatus.pending)
          .toString()
          .toLowerCase(),
      pairingCode: (data['pairing_code'] ?? '').toString(),
      message: (data['message'] ?? json['message'])?.toString(),
      deviceToken: (data['device_token'] ?? json['device_token']) as String?,
      expiresAt: expiresAtValue is String
          ? DateTime.tryParse(expiresAtValue)
          : null,
    );
  }
}

class DevicePairingStatus {
  const DevicePairingStatus({
    required this.status,
    required this.message,
    this.deviceToken,
  });

  final String status;
  final String message;
  final String? deviceToken;

  bool get isActive => DeviceStatus.isActive(status) && hasDeviceToken;

  bool get hasDeviceToken => deviceToken != null && deviceToken!.isNotEmpty;

  factory DevicePairingStatus.fromJson(Map<String, dynamic> json) {
    return DevicePairingStatus(
      status: (json['status'] ?? DeviceStatus.pending).toString().toLowerCase(),
      message: (json['message'] ?? '').toString(),
      deviceToken: json['device_token'] as String?,
    );
  }
}
