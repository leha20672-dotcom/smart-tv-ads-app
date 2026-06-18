class Schedule {
  const Schedule({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.daysOfWeek,
  });

  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  final String startTime;

  final String endTime;

  final List<int> daysOfWeek;

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as int,
      name: json['name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      startTime: json['start_time'] as String, 
      endTime: json['end_time'] as String,
      daysOfWeek: List<int>.from(json['days_of_week'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'days_of_week': daysOfWeek,  
    };
  }
}