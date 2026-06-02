class Device {
  const Device({required this.deviceCode, required this.deviceToken});

  final String deviceCode;
  final String deviceToken;

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceCode: json['device_code'] as String,
      deviceToken: json['device_token'] as String,
    );
  }
}
