class HabitStatus {
  final int? id;
  final int habitId;
  final DateTime date;

  HabitStatus({this.id, required this.habitId, required this.date});

  // Normalize date to start of day for comparison
  DateTime get normalizedDate {
    return DateTime(date.year, date.month, date.day);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'date': normalizedDate.toIso8601String(),
    };
  }

  factory HabitStatus.fromMap(Map<String, dynamic> map) {
    return HabitStatus(
      id: map['id'] as int?,
      habitId: map['habitId'] as int,
      date: DateTime.parse(map['date'] as String),
    );
  }

  HabitStatus copyWith({int? id, int? habitId, DateTime? date}) {
    return HabitStatus(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitStatus &&
        other.habitId == habitId &&
        other.normalizedDate == normalizedDate;
  }

  @override
  int get hashCode => Object.hash(habitId, normalizedDate);
}
