class AddressSchedule {
  const AddressSchedule({
    required this.id,
    required this.addressId,
    required this.scheduleId,
  });

  final int id;
  final int addressId;
  final int scheduleId;

  factory AddressSchedule.fromJson(Map<String, dynamic> json) {
    return AddressSchedule(
      id: json['id'] as int,
      addressId: json['address_id'] as int,
      scheduleId: json['schedule_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address_id': addressId,
      'schedule_id':  scheduleId,
    };
  }
}