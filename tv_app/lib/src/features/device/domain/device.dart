class Device {
  const Device({
    required this.id,
    required this.deviceCode,
    required this.name,
    required this.status,
    this.addressId,
    this.orientation,
    //required this.deviceToken
  });

  final int id;
  final int? addressId;
  final String deviceCode;
  final String name;
  final String status;
  final String? orientation;

  //final String deviceToken;

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as int,
      addressId: json['address_id'] as int?,
      deviceCode: json['device_code'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      orientation: json['orientation'] as String?,
      //deviceToken: json['device_token'] as String,
    );
  }
}
