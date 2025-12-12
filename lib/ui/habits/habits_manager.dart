import 'package:flutter/material.dart';
import '../../../models/habit.dart';
import '../../../models/habit_status.dart';
import '../../database_helper.dart';
import '../../services/notifications.dart';
import '../../services/sound_service.dart';
import '../settings/settings_manager.dart';


class HabitsManager extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  NotificationService? _notificationService;
  SettingsManager? _settingsManager;
  Map<Habit, List<HabitStatus>> _habitsWithStatuses = {};
  List<Habit> _completedHabitsToday = [];
  bool _isLoading = false;
  bool _compactView = false;

  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  // Getters
  Map<Habit, List<HabitStatus>> get habitsWithStatuses => _habitsWithStatuses;
  List<Habit> get completedHabitsToday => _completedHabitsToday;
  bool get isLoading => _isLoading;
  bool get compactView => _compactView;
  void setSettingsManager(SettingsManager manager) {
    _settingsManager = manager;
  }
  List<Habit> get habits =>
      _habitsWithStatuses.keys.toList()
        ..sort((a, b) => a.index.compareTo(b.index));

  int get totalHabits => habits.length;
  int get completedCount => _completedHabitsToday.length;

  Future<void> loadHabits() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('>>> LOADING HABITS');

      final habits = await _dbHelper.getAllHabits();
      debugPrint('>>> LOADED ${habits.length} HABITS');

      final allStatuses = await _dbHelper.getAllHabitStatuses();
      debugPrint('>>> LOADED ${allStatuses.length} HABIT STATUSES');

      _habitsWithStatuses = {};
      for (var habit in habits) {
        final habitStatuses =
            allStatuses.where((status) => status.habitId == habit.id).toList()
              ..sort((a, b) => b.date.compareTo(a.date));
        _habitsWithStatuses[habit] = habitStatuses;
      }

      _updateCompletedHabitsToday();
      debugPrint('>>> LOAD COMPLETE');
    } catch (e) {
      debugPrint('>>> ERROR LOADING HABITS: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateCompletedHabitsToday() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    _completedHabitsToday = habits.where((habit) {
      final statuses = _habitsWithStatuses[habit] ?? [];
      return statuses.any((status) => status.normalizedDate == normalizedToday);
    }).toList();
  }

  Future<void> addHabit(Habit habit) async {
    try {
      debugPrint('>>> ADDING HABIT: ${habit.title}');

      final id = await _dbHelper.insertHabit(habit);
      final newHabit = habit.copyWith(id: id);

      _habitsWithStatuses[newHabit] = [];

      if (newHabit.reminder) {
        await _scheduleHabitReminder(newHabit);
      }

      notifyListeners();
      debugPrint('>>> HABIT ADDED: ID=$id');
    } catch (e) {
      debugPrint('>>> ERROR ADDING HABIT: $e');
    }
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      debugPrint('>>> UPDATING HABIT: ${habit.title}');

      await _dbHelper.updateHabit(habit);

      // Cancel existing notification first
      if (habit.id != null) {
        await _notificationService?.cancelNotification(habit.id!);
      }

      // Schedule new reminder if enabled
      if (habit.reminder) {
        await _scheduleHabitReminder(habit);
      }

      // Update local state
      final oldHabitKey = _habitsWithStatuses.keys.firstWhere(
        (h) => h.id == habit.id,
        orElse: () => habit,
      );

      final statuses = _habitsWithStatuses[oldHabitKey];
      _habitsWithStatuses.remove(oldHabitKey);
      _habitsWithStatuses[habit] = statuses ?? [];

      _updateCompletedHabitsToday();
      notifyListeners();
      debugPrint('>>> HABIT UPDATED');
    } catch (e) {
      debugPrint('>>> ERROR UPDATING HABIT: $e');
    }
  }

  Future<void> deleteHabit(Habit habit) async {
    try {
      debugPrint('>>> DELETING HABIT: ${habit.title}');

      if (habit.id != null) {
        await _notificationService?.cancelNotification(habit.id!);
        await _dbHelper.deleteHabit(habit.id!);
      }

      _habitsWithStatuses.remove(habit);
      _updateCompletedHabitsToday();
      notifyListeners();
      debugPrint('>>> HABIT DELETED');
    } catch (e) {
      debugPrint('>>> ERROR DELETING HABIT: $e');
    }
  }

  Future<void> reorderHabits(
    List<Habit> habitsList,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      debugPrint('>>> REORDERING: $oldIndex -> $newIndex');

      // Create a working copy
      final updatedList = List<Habit>.from(habitsList);

      // Perform the reorder
      final movedHabit = updatedList.removeAt(oldIndex);
      updatedList.insert(newIndex, movedHabit);

      // Rebuild map maintaining the statuses correctly
      final newMap = <Habit, List<HabitStatus>>{};
      for (int i = 0; i < updatedList.length; i++) {
        final habit = updatedList[i];
        final updatedHabit = habit.copyWith(index: i);
        // Keep the original statuses
        newMap[updatedHabit] = _habitsWithStatuses[habit] ?? [];

        // Update in database (without awaiting to avoid blocking)
        _dbHelper.updateHabit(updatedHabit);
      }

      // Single update to avoid flickering
      _habitsWithStatuses = newMap;
      _updateCompletedHabitsToday();
      notifyListeners();

      debugPrint('>>> REORDER COMPLETE');
    } catch (e) {
      debugPrint('>>> ERROR REORDERING: $e');
      await loadHabits();
    }
  }

  Future<void> toggleHabitStatus(Habit habit, {DateTime? date}) async {
    try {
      final targetDate = date ?? DateTime.now();
      final normalizedDate = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );

      final statuses = _habitsWithStatuses[habit] ?? [];
      final existingStatus = statuses.firstWhere(
        (status) => status.normalizedDate == normalizedDate,
        orElse: () => HabitStatus(habitId: -1, date: normalizedDate),
      );

      if (existingStatus.habitId == -1) {
        // Add status
        final newStatus = HabitStatus(habitId: habit.id!, date: normalizedDate);
        await _dbHelper.insertHabitStatus(newStatus);
        statuses.insert(0, newStatus);

        if (_settingsManager?.completionSoundsEnabled ?? true) {
           SoundService.playCompletionSound();
        }
        // Check if target reached
        if (habit.isTargetReachedInCurrentPeriod(statuses)) {
          debugPrint('>>> HABIT TARGET REACHED: ${habit.title}');
        }
      } else {
        // Remove status
        await _dbHelper.deleteHabitStatus(habit.id!, normalizedDate);
        statuses.remove(existingStatus);
      }

      _updateCompletedHabitsToday();
      notifyListeners();
    } catch (e) {
      debugPrint('>>> ERROR TOGGLING STATUS: $e');
    }
  }

  bool isHabitCompletedOn(Habit habit, DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final statuses = _habitsWithStatuses[habit] ?? [];
    return statuses.any((status) => status.normalizedDate == normalizedDate);
  }

  /// Get current streak based on habit frequency
  int getCurrentStreak(Habit habit) {
    final statuses = _habitsWithStatuses[habit] ?? [];
    return habit.getCurrentStreakByFrequency(statuses);
  }

  /// Get best streak based on habit frequency
  int getBestStreak(Habit habit) {
    final statuses = _habitsWithStatuses[habit] ?? [];
    return habit.getBestStreakByFrequency(statuses);
  }

  void setCompactView(bool value) {
    _compactView = value;
    notifyListeners();
  }

  /// Reschedule all habit reminders (call this on app start)
  Future<void> rescheduleAllHabitReminders() async {
    debugPrint('>>> RESCHEDULING ALL HABIT REMINDERS');
    for (final habit in habits) {
      if (habit.reminder && habit.id != null) {
        await _scheduleHabitReminder(habit);
      }
    }
  }

  Future<void> _scheduleHabitReminder(Habit habit) async {
    try {
      if (!habit.reminder || _notificationService == null || habit.id == null) {
        debugPrint('>>> REMINDER SKIP: ${habit.title}');
        return;
      }

      debugPrint('>>> SCHEDULING REMINDER: ${habit.title}');

      await _notificationService!.scheduleHabitReminder(
        habitId: habit.id!,
        habitTitle: habit.title,
        description: habit.description,
        reminderTime: habit.time,
        activeDays: habit.days,
      );
    } catch (e) {
      debugPrint('>>> ERROR SCHEDULING REMINDER: $e');
    }
  }
}
