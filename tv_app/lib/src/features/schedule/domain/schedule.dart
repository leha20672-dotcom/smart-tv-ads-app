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
      id: _asInt(json['id'] ?? json['schedule_id']),
      name: (json['name'] ?? json['schedule_name'] ?? '') as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      daysOfWeek: _daysOfWeekFromJson(json['days_of_week']),
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

  static List<int> _daysOfWeekFromJson(Object? value) {
    if (value is List) {
      final days = value.map(_asInt).where((day) => day > 0).toList();
      return days.isEmpty
          ? const [1, 2, 3, 4, 5, 6, 7]
          : _normalizeWeekdays(days);
    }

    if (value is String && value.isNotEmpty) {
      final normalized = value.replaceAll('[', '').replaceAll(']', '');
      final days = normalized
          .split(',')
          .map((day) => _asInt(day.trim()))
          .where((day) => day > 0)
          .toList();

      return days.isEmpty
          ? const [1, 2, 3, 4, 5, 6, 7]
          : _normalizeWeekdays(days);
    }

    return const [1, 2, 3, 4, 5, 6, 7];
  }

  static List<int> _normalizeWeekdays(List<int> days) {
    if (days.contains(8)) {
      return days
          .map((day) => day == 8 ? 7 : day - 1)
          .where((day) => day >= 1 && day <= 7)
          .toSet()
          .toList();
    }

    return days.where((day) => day >= 1 && day <= 7).toSet().toList();
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
