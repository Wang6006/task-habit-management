import 'package:flutter/foundation.dart' hide Category;
import '../../models/task.dart';
import '../../models/category.dart';
import '../../database_helper.dart';
import '../../services/notifications.dart';
import '../../services/sound_service.dart';
import '../settings/settings_manager.dart';

class TasksManager extends ChangeNotifier {
  NotificationService? _notificationService;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  SettingsManager? _settingsManager;
  Map<Category, List<Task>> _tasks = {};
  Category? _currentCategory;
  bool _isLoading = false;
  bool _reorderTasksOnComplete = true;

  // Getters
  Map<Category, List<Task>> get tasks => _tasks;
  Category? get currentCategory => _currentCategory;
  bool get isLoading => _isLoading;
  bool get reorderTasksOnComplete => _reorderTasksOnComplete;
  void setSettingsManager(SettingsManager manager) {
    _settingsManager = manager;
  }
  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  List<Category> get categories =>
      _tasks.keys.toList()..sort((a, b) => a.index.compareTo(b.index));

  List<Task> get currentCategoryTasks =>
      _currentCategory != null ? _tasks[_currentCategory]! : [];

  List<Task> get completedTasks {
    return _tasks.values
        .expand((tasks) => tasks)
        .where((task) => task.status)
        .toList();
  }

  int get totalTasks {
    return _tasks.values.expand((tasks) => tasks).length;
  }

  // Initialize and load data
  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final categories = await _dbHelper.getAllCategories();
      final allTasks = await _dbHelper.getAllTasks();

      _tasks = {};
      for (var category in categories) {
        final categoryTasks =
            allTasks.where((task) => task.categoryId == category.id).toList()
              ..sort((a, b) => a.index.compareTo(b.index));
        _tasks[category] = categoryTasks;
      }

      if (_currentCategory == null && categories.isNotEmpty) {
        _currentCategory = categories.first;
      } else if (_currentCategory != null) {
        _currentCategory = categories.firstWhere(
          (cat) => cat.id == _currentCategory!.id,
          orElse: () => categories.first,
        );
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Category operations
  Future<void> addCategory(Category category) async {
    try {
      final maxIndex = categories.isEmpty
          ? 0
          : categories.map((c) => c.index).reduce((a, b) => a > b ? a : b);

      final newCategory = category.copyWith(index: maxIndex + 1);
      final id = await _dbHelper.insertCategory(newCategory);

      final insertedCategory = newCategory.copyWith(id: id);
      _tasks[insertedCategory] = [];

      _currentCategory ??= insertedCategory;

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding category: $e');
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _dbHelper.updateCategory(category);
      await loadTasks();
    } catch (e) {
      debugPrint('Error updating category: $e');
    }
  }

  Future<void> deleteCategory(Category category) async {
    if (categories.length <= 1) return;

    try {
      // Cancel notifications for all tasks in this category
      final tasksToCancel = _tasks[category] ?? [];
      for (final task in tasksToCancel) {
        if (task.id != null) {
          _notificationService?.cancelNotification(task.id!);
        }
      }

      // Store if we need to change current category
      final needsNewCategory = _currentCategory?.id == category.id;

      // Delete from database
      await _dbHelper.deleteCategory(category.id!);

      // Remove from local state immediately
      _tasks.remove(category);

      // Update current category if needed
      if (needsNewCategory) {
        _currentCategory = categories.isNotEmpty ? categories.first : null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting category: $e');
      // Reload on error to ensure consistency
      await loadTasks();
    }
  }

  Future<void> reorderCategories(List<Category> newOrder) async {
    try {
      // Create new categories with updated index
      final updatedCategories = <Category>[];
      for (int i = 0; i < newOrder.length; i++) {
        updatedCategories.add(newOrder[i].copyWith(index: i));
      }

      // Update local state immediately with new categories
      final newTasksMap = <Category, List<Task>>{};
      for (final newCategory in updatedCategories) {
        final oldCategory = _tasks.keys.firstWhere(
          (c) => c.id == newCategory.id,
          orElse: () => newCategory,
        );
        newTasksMap[newCategory] = _tasks[oldCategory] ?? [];
      }
      _tasks = newTasksMap;

      // Update current category reference
      if (_currentCategory != null) {
        _currentCategory = updatedCategories.firstWhere(
          (cat) => cat.id == _currentCategory!.id,
          orElse: () => updatedCategories.first,
        );
      }

      notifyListeners();

      // Update database in background
      for (int i = 0; i < updatedCategories.length; i++) {
        await _dbHelper.updateCategoryIndex(updatedCategories[i].id!, i);
      }
    } catch (e) {
      debugPrint('Error reordering categories: $e');
      await loadTasks();
    }
  }

  void setCurrentCategory(Category category) {
    _currentCategory = category;
    notifyListeners();
  }

  // Task operations
  Future<void> addTask(Task task) async {
    try {
      final categoryTasks = _tasks[_currentCategory] ?? [];
      final maxIndex = categoryTasks.isEmpty
          ? 0
          : categoryTasks.map((t) => t.index).reduce((a, b) => a > b ? a : b);

      final newTask = task.copyWith(index: maxIndex + 1);
      final int id = await _dbHelper.insertTask(newTask);

      final insertedTask = newTask.copyWith(id: id);
      _tasks[_currentCategory]!.add(insertedTask);

      // Schedule notification if reminder is set
      if (insertedTask.reminder != null && insertedTask.id != null) {
        debugPrint('>>> SCHEDULING NOTIFICATION FOR TASK:');
        debugPrint('    ID: ${insertedTask.id}');
        debugPrint('    Title: ${insertedTask.title}');
        debugPrint('    Reminder: ${insertedTask.reminder}');
        debugPrint('    Now: ${DateTime.now()}');

        await _notificationService?.scheduleNotification(
          id: insertedTask.id!,
          title: insertedTask.title,
          body: 'Task "${insertedTask.title}" is due soon!',
          scheduledDate: insertedTask.reminder!,
        );

        debugPrint('>>> NOTIFICATION SCHEDULED FOR TASK ${insertedTask.id}');
      } else {
        debugPrint(
          '>>> NO NOTIFICATION: reminder=${insertedTask.reminder}, id=${insertedTask.id}',
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding task: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _dbHelper.updateTask(task);

      // Handle notifications
      if (task.id != null) {
        // Cancel existing notification first
        await _notificationService?.cancelNotification(task.id!);

        // Schedule new notification if reminder is set
        if (task.reminder != null) {
          await _notificationService?.scheduleNotification(
            id: task.id!,
            title: task.title,
            body: 'Task "${task.title}" is due soon!',
            scheduledDate: task.reminder!,
          );
        }
      }

      // Update local state
      for (var category in _tasks.keys) {
        final index = _tasks[category]!.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          if (task.categoryId != category.id!) {
            _tasks[category]!.removeAt(index);
            final newCategory = categories.firstWhere(
              (cat) => cat.id == task.categoryId,
            );
            _tasks[newCategory]!.add(task);
          } else {
            _tasks[category]![index] = task;
          }
          break;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating task: $e');
    }
  }

  Future<void> toggleTaskStatus(Task task) async {
    final updatedTask = task.copyWith(
      status: !task.status,
      // Remove reminder when completing task
      reminder: !task.status ? null : task.reminder,
    );

    await updateTask(updatedTask);
    if (updatedTask.status) { 
      debugPrint('>>> Cài đặt Âm thanh: ${_settingsManager?.completionSoundsEnabled}');
       if (_settingsManager?.completionSoundsEnabled ?? true) {
         SoundService.playCompletionSound();
       }
    }
    if (_reorderTasksOnComplete && updatedTask.status) {
      final categoryTasks = _tasks[_currentCategory]!;
      final taskIndex = categoryTasks.indexWhere((t) => t.id == task.id);

      if (taskIndex != -1) {
        final task = categoryTasks.removeAt(taskIndex);
        categoryTasks.add(task);
        await reorderTasks(categoryTasks);
      }
    }
  }

  Future<void> deleteTask(Task task) async {
    try {
      await _dbHelper.deleteTask(task.id!);

      // Cancel notification
      if (task.id != null) {
        _notificationService?.cancelNotification(task.id!);
      }

      for (var category in _tasks.keys) {
        _tasks[category]!.removeWhere((t) => t.id == task.id);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  Future<void> deleteCompletedTasks() async {
    try {
      await _dbHelper.deleteCompletedTasks();

      for (var category in _tasks.keys) {
        _tasks[category]!.removeWhere((task) => task.status);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting completed tasks: $e');
    }
  }

  Future<void> reorderTasks(List<Task> newOrder) async {
    try {
      if (_currentCategory != null) {
        _tasks[_currentCategory!] = List.from(newOrder);
        notifyListeners();
      }

      for (int i = 0; i < newOrder.length; i++) {
        final updatedTask = newOrder[i].copyWith(index: i);
        await _dbHelper.updateTask(updatedTask);
        newOrder[i] = updatedTask;
      }

      if (_currentCategory != null) {
        _tasks[_currentCategory!] = newOrder;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error reordering tasks: $e');
      await loadTasks();
    }
  }

  void setReorderOnComplete(bool value) {
    _reorderTasksOnComplete = value;
    notifyListeners();
  }
}
