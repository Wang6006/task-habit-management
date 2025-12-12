// habit.dart
import './habit_status.dart';

class Habit {
  final int? id;
  final String title;
  final String description;
  final int index;
  final Set<int> days;
  final DateTime time;
  final bool reminder;
  final String frequency; 
  final int frequencyDays;
  final DateTime createdDate;

  Habit({
    this.id,
    required this.title,
    required this.description,
    required this.index,
    required this.days,
    required this.time,
    this.reminder = false,
    this.frequency = 'weekly',
    this.frequencyDays = 7,
    DateTime? createdDate,
  }) : createdDate = createdDate ?? DateTime.now();

  String get daysString => (days.toList()..sort()).join(',');

  static Set<int> parseDays(String daysStr) {
    if (daysStr.isEmpty) return {};
    return daysStr.split(',').map((e) => int.parse(e)).toSet();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'index': index,
      'days': daysString,
      'time': time.toIso8601String(),
      'reminder': reminder ? 1 : 0,
      'frequency': frequency,
      'frequencyDays': frequencyDays,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      index: map['index'] as int,
      days: parseDays(map['days'] as String),
      time: DateTime.parse(map['time'] as String),
      reminder: (map['reminder'] as int) == 1,
      frequency: map['frequency'] as String? ?? 'weekly',
      frequencyDays: map['frequencyDays'] as int? ?? 7,
      createdDate: map['createdDate'] != null
          ? DateTime.parse(map['createdDate'] as String)
          : DateTime.now(),
    );
  }

  Habit copyWith({
    int? id,
    String? title,
    String? description,
    int? index,
    Set<int>? days,
    DateTime? time,
    bool? reminder,
    String? frequency,
    int? frequencyDays,
    DateTime? createdDate,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      index: index ?? this.index,
      days: days ?? this.days,
      time: time ?? this.time,
      reminder: reminder ?? this.reminder,
      frequency: frequency ?? this.frequency,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  static String getDayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  bool isActiveToday() {
    final today = DateTime.now().weekday;
    return days.contains(today);
  }

  String getFrequencyText() {
    if (frequency == 'weekly') {
      return '$frequencyDays days per week';
    } else if (frequency == 'monthly') {
      return '$frequencyDays days per month';
    }
    return frequency;
  }
}

// ============================================================
// STREAK CALCULATION - DAY-BASED (theo ngày liên tiếp)
// ============================================================
extension HabitStreakCalculation on Habit {
  /// Calculate current streak based on consecutive DAYS
  /// Considers the frequency target (can skip non-scheduled days)
  int getCurrentStreakByFrequency(List<HabitStatus> statuses) {
    if (statuses.isEmpty) return 0;

    if (frequency == 'weekly') {
      return _calculateDayStreakWithWeeklyTarget(statuses);
    } else if (frequency == 'monthly') {
      return _calculateDayStreakWithMonthlyTarget(statuses);
    }
    return 0;
  }

  /// Calculate best streak based on consecutive DAYS
  int getBestStreakByFrequency(List<HabitStatus> statuses) {
    if (statuses.isEmpty) return 0;

    if (frequency == 'weekly') {
      return _calculateBestDayStreakWithWeeklyTarget(statuses);
    } else if (frequency == 'monthly') {
      return _calculateBestDayStreakWithMonthlyTarget(statuses);
    }
    return 0;
  }

  /// CURRENT STREAK - Weekly Target
  int _calculateDayStreakWithWeeklyTarget(List<HabitStatus> statuses) {
    final now = DateTime.now();
    final normalizedToday = DateTime(now.year, now.month, now.day);

    int streak = 0;
    DateTime checkDate = normalizedToday;

    // Đếm ngược từ hôm nay
    for (int i = 0; i < 520; i++) {
      // Nếu không phải ngày scheduled, skip
      if (!days.contains(checkDate.weekday)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      // Kiểm tra xem ngày này có completed không
      final isCompleted = statuses.any((s) => s.normalizedDate == checkDate);

      if (isCompleted) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      // Nếu chưa complete, kiểm tra xem có thể bỏ qua không
      final weekStart = _getWeekStart(checkDate);
      final canSkip = _canSkipDayInWeek(checkDate, weekStart, statuses);

      if (canSkip) {
        // Được phép skip ngày này
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      } else {
        break;
      }
    }

    return streak;
  }

  /// CURRENT STREAK - Monthly Target
  int _calculateDayStreakWithMonthlyTarget(List<HabitStatus> statuses) {
    final now = DateTime.now();
    final normalizedToday = DateTime(now.year, now.month, now.day);

    int streak = 0;
    DateTime checkDate = normalizedToday;

    for (int i = 0; i < 365; i++) {
      if (!days.contains(checkDate.weekday)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      final isCompleted = statuses.any((s) => s.normalizedDate == checkDate);

      if (isCompleted) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      final monthStart = DateTime(checkDate.year, checkDate.month, 1);
      final canSkip = _canSkipDayInMonth(checkDate, monthStart, statuses);

      if (canSkip) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      } else {
        break;
      }
    }

    return streak;
  }

  /// BEST STREAK - Weekly Target
  int _calculateBestDayStreakWithWeeklyTarget(List<HabitStatus> statuses) {
    if (statuses.isEmpty) return 0;

    final oldestDate = statuses
        .map((s) => s.normalizedDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final now = DateTime.now();

    int maxStreak = 0;
    int currentStreak = 0;
    DateTime checkDate = oldestDate;

    while (checkDate.isBefore(now.add(const Duration(days: 1)))) {
      if (!days.contains(checkDate.weekday)) {
        checkDate = checkDate.add(const Duration(days: 1));
        continue;
      }

      final isCompleted = statuses.any((s) => s.normalizedDate == checkDate);

      if (isCompleted) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        final weekStart = _getWeekStart(checkDate);
        final canSkip = _canSkipDayInWeek(checkDate, weekStart, statuses);

        if (!canSkip) {
          currentStreak = 0;
        }
      }

      checkDate = checkDate.add(const Duration(days: 1));
    }

    return maxStreak;
  }

  /// BEST STREAK - Monthly Target
  int _calculateBestDayStreakWithMonthlyTarget(List<HabitStatus> statuses) {
    if (statuses.isEmpty) return 0;

    final oldestDate = statuses
        .map((s) => s.normalizedDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final now = DateTime.now();

    int maxStreak = 0;
    int currentStreak = 0;
    DateTime checkDate = oldestDate;

    while (checkDate.isBefore(now.add(const Duration(days: 1)))) {
      if (!days.contains(checkDate.weekday)) {
        checkDate = checkDate.add(const Duration(days: 1));
        continue;
      }

      final isCompleted = statuses.any((s) => s.normalizedDate == checkDate);

      if (isCompleted) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        final monthStart = DateTime(checkDate.year, checkDate.month, 1);
        final canSkip = _canSkipDayInMonth(checkDate, monthStart, statuses);

        if (!canSkip) {
          currentStreak = 0;
        }
      }

      checkDate = checkDate.add(const Duration(days: 1));
    }

    return maxStreak;
  }

  /// Check if we can skip a day in a week (target not yet failed)
  bool _canSkipDayInWeek(
    DateTime checkDate,
    DateTime weekStart,
    List<HabitStatus> statuses,
  ) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);

    // Đếm số ngày đã complete trong tuần
    int completedInWeek = 0;
    for (var status in statuses) {
      if (status.normalizedDate.isAfter(
            weekStart.subtract(const Duration(days: 1)),
          ) &&
          status.normalizedDate.isBefore(weekEnd) &&
          days.contains(status.date.weekday)) {
        completedInWeek++;
      }
    }

    // Đếm số ngày scheduled còn lại trong tuần (sau checkDate)
    int remainingScheduledDays = 0;
    DateTime countDate = checkDate.add(const Duration(days: 1));
    while (countDate.isBefore(weekEnd) &&
        countDate.isBefore(normalizedNow.add(const Duration(days: 1)))) {
      if (days.contains(countDate.weekday)) {
        remainingScheduledDays++;
      }
      countDate = countDate.add(const Duration(days: 1));
    }

    // Có thể skip nếu: completed + remaining >= target
    return (completedInWeek + remainingScheduledDays) >= frequencyDays;
  }

  /// Check if we can skip a day in a month
  bool _canSkipDayInMonth(
    DateTime checkDate,
    DateTime monthStart,
    List<HabitStatus> statuses,
  ) {
    final monthEnd = DateTime(checkDate.year, checkDate.month + 1, 1);
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);

    int completedInMonth = 0;
    for (var status in statuses) {
      if (status.normalizedDate.isAfter(
            monthStart.subtract(const Duration(days: 1)),
          ) &&
          status.normalizedDate.isBefore(monthEnd) &&
          days.contains(status.date.weekday)) {
        completedInMonth++;
      }
    }

    int remainingScheduledDays = 0;
    DateTime countDate = checkDate.add(const Duration(days: 1));
    while (countDate.isBefore(monthEnd) &&
        countDate.isBefore(normalizedNow.add(const Duration(days: 1)))) {
      if (days.contains(countDate.weekday)) {
        remainingScheduledDays++;
      }
      countDate = countDate.add(const Duration(days: 1));
    }

    return (completedInMonth + remainingScheduledDays) >= frequencyDays;
  }

  /// Check if target reached in current period
  bool isTargetReachedInCurrentPeriod(List<HabitStatus> statuses) {
    final now = DateTime.now();

    if (frequency == 'weekly') {
      final weekStart = _getWeekStart(now);
      final weekEnd = weekStart.add(const Duration(days: 7));

      int weekCompletions = 0;
      for (var status in statuses) {
        if (status.normalizedDate.isAfter(
              weekStart.subtract(const Duration(days: 1)),
            ) &&
            status.normalizedDate.isBefore(weekEnd) &&
            days.contains(status.date.weekday)) {
          weekCompletions++;
        }
      }

      return weekCompletions >= frequencyDays;
    } else if (frequency == 'monthly') {
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);

      int monthCompletions = 0;
      for (var status in statuses) {
        if (status.normalizedDate.isAfter(
              monthStart.subtract(const Duration(days: 1)),
            ) &&
            status.normalizedDate.isBefore(monthEnd) &&
            days.contains(status.date.weekday)) {
          monthCompletions++;
        }
      }

      return monthCompletions >= frequencyDays;
    }
    return false;
  }

  /// Helper: Get start of week (Monday)
  DateTime _getWeekStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: date.weekday - 1));
  }
}
