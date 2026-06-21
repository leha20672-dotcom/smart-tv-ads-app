class DeviceHeartbeat {
  const DeviceHeartbeat({
    required this.deviceToken,
    required this.status,
    required this.lastConnectedAt,
    this.ipAddress,
  });

  final String deviceToken;
  final String status;
  final DateTime lastConnectedAt;
  final String? ipAddress;

  factory DeviceHeartbeat.fromJson(Map<String, dynamic> json) {
    return DeviceHeartbeat(
      deviceToken: json['device_token'] as String,
      status: json['status'] as String,
      lastConnectedAt: DateTime.parse(json['last_connected_at'] as String),
      ipAddress: json['ip_address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_token': deviceToken,
      'status': status,
      'last_connected_at': lastConnectedAt.toIso8601String(),
      'ip_address': ipAddress,
    };
  }

}
