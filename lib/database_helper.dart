import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/habit.dart';
import '../../models/habit_status.dart';
import '../../models/task.dart';
import '../../models/category.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('time_management.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // ========== CATEGORIES TABLE ==========
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        "index" INTEGER NOT NULL DEFAULT 0,
        color TEXT NOT NULL DEFAULT 'gray'
      )
    ''');

    // ========== TASKS TABLE ==========
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER NOT NULL,
        title TEXT NOT NULL,
        "index" INTEGER NOT NULL DEFAULT 0,
        status INTEGER NOT NULL DEFAULT 0,
        reminder TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    // ========== HABITS TABLE (UPDATED WITH FREQUENCY) ==========
    await db.execute('''
  CREATE TABLE habits(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    "index" INTEGER NOT NULL DEFAULT 0,
    days TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
    time TEXT NOT NULL,
    reminder INTEGER NOT NULL DEFAULT 0,
    frequency TEXT NOT NULL DEFAULT 'weekly',
    frequencyDays INTEGER NOT NULL DEFAULT 7,
    createdDate TEXT NOT NULL DEFAULT (datetime('now'))
  )
''');

    // ========== HABIT_STATUS TABLE ==========
    await db.execute('''
      CREATE TABLE habit_status(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits(id) ON DELETE CASCADE,
        UNIQUE(habitId, date)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_tasks_categoryId ON tasks(categoryId)');
    await db.execute(
      'CREATE INDEX idx_habit_status_habitId ON habit_status(habitId)',
    );
    await db.execute(
      'CREATE INDEX idx_habit_status_date ON habit_status(date)',
    );

    // Insert default category
    await db.insert('categories', {
      'name': 'General',
      'index': 0,
      'color': 'blue',
    });
  }

  // ========================================
  // CATEGORY OPERATIONS
  // ========================================

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: '"index" ASC');
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Category.fromMap(result.first);
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateCategoryIndex(int id, int newIndex) async {
    final db = await database;
    return await db.update(
      'categories',
      {'index': newIndex},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================================
  // TASK OPERATIONS
  // ========================================

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final result = await db.query('tasks', orderBy: '"index" ASC');
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<Task?> getTaskById(int id) async {
    final db = await database;
    final result = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Task.fromMap(result.first);
  }

  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCompletedTasks() async {
    final db = await database;
    return await db.delete('tasks', where: 'status = ?', whereArgs: [1]);
  }

  // ========================================
  // HABIT OPERATIONS
  // ========================================

  Future<List<Habit>> getAllHabits() async {
    final db = await database;
    final result = await db.query('habits', orderBy: '"index" ASC');
    return result.map((map) => Habit.fromMap(map)).toList();
  }

  Future<Habit?> getHabitById(int id) async {
    final db = await database;
    final result = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Habit.fromMap(result.first);
  }

  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateHabitIndex(int id, int newIndex) async {
    final db = await database;
    return await db.update(
      'habits',
      {'index': newIndex},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========================================
  // HABIT STATUS OPERATIONS
  // ========================================

  Future<List<HabitStatus>> getAllHabitStatuses() async {
    final db = await database;
    final result = await db.query('habit_status', orderBy: 'date DESC');
    return result.map((map) => HabitStatus.fromMap(map)).toList();
  }

  Future<List<HabitStatus>> getStatusesForHabit(int habitId) async {
    final db = await database;
    final result = await db.query(
      'habit_status',
      where: 'habitId = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );
    return result.map((map) => HabitStatus.fromMap(map)).toList();
  }

  Future<List<HabitStatus>> getStatusesForDate(DateTime date) async {
    final db = await database;
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final result = await db.query(
      'habit_status',
      where: 'date = ?',
      whereArgs: [normalizedDate.toIso8601String()],
    );
    return result.map((map) => HabitStatus.fromMap(map)).toList();
  }

  Future<int> insertHabitStatus(HabitStatus status) async {
    final db = await database;
    return await db.insert(
      'habit_status',
      status.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteHabitStatus(int habitId, DateTime date) async {
    final db = await database;
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return await db.delete(
      'habit_status',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, normalizedDate.toIso8601String()],
    );
  }

  Future<int> deleteAllHabitStatuses() async {
    final db = await database;
    return await db.delete('habit_status');
  }

  // ========================================
  // SEED DATA FOR TESTING
  // ========================================

  Future<void> seedDemoData() async {
    final db = await database;

    final categoryCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories'),
    );
    if (categoryCount! > 1) return;

    // Only add 2 more categories (total 3 with default "General")
    await db.insert('categories', {'name': 'Work', 'index': 1, 'color': 'red'});
    await db.insert('categories', {
      'name': 'Personal',
      'index': 2,
      'color': 'green',
    });

    // Add many tasks to each category
    // General category (id: 1) - 6 tasks
    await db.insert('tasks', {
      'categoryId': 1,
      'title': 'Buy groceries for the week',
      'index': 0,
      'status': 0,
    });
    await db.insert('tasks', {
      'categoryId': 1,
      'title': 'Schedule dentist appointment',
      'index': 1,
      'status': 1,
    });
    await db.insert('tasks', {
      'categoryId': 1,
      'title': 'Pay electricity bill',
      'index': 2,
      'status': 0,
    });
    await db.insert('tasks', {
      'categoryId': 1,
      'title': 'Call mom on her birthday',
      'index': 3,
      'status': 1,
    });
    await db.insert('tasks', {
      'categoryId': 1,
      'title': 'Organize closet',
      'index': 4,
      'status': 0,
    });
    await db.insert('tasks', {
      'categoryId': 1,
      'title': 'Water plants',
      'index': 5,
      'status': 0,
    });

    // Work category (id: 2) - 8 tasks
    await db.insert('tasks', {
      'categoryId': 2,
      'title': 'Review project documentation',
      'index': 0,
      'status': 1,
    });
    await db.insert('tasks', {
      'categoryId': 2,
      'title': 'Prepare presentation slides',
      'index': 1,
      'status': 0,
    });
    await db.insert('tasks', {
      'categoryId': 2,
      'title': 'Reply to client emails',
      'index': 2,
      'status': 1,
    });
    await db.insert('tasks', {
      'categoryId': 2,
      'title': 'Update project timeline',
      'index': 3,
      'status': 0,
    });
    await db.insert('tasks', {
      'categoryId': 2,
      'title': 'Submit expense report',
      'index': 4,
      'status': 1,
    });
    await db.insert('tasks', {
      'categoryId': 2,
      'title': 'Team meeting at 3 PM',
      'index': 5,
      'status': 0,
    });
    await db.insert('tasks', {
      'categoryId': 2,
      'title': 'Code review for new feature',
      'index': 6,
      'status': 0,
    });
    await db.insert('tasks', {
      'categoryId': 2,
      'title': 'Fix bug in login page',
      'index': 7,
      'status': 0,
    });

    // Personal category (id: 3) - 7 tasks
    await db.insert('tasks', {
      'categoryId': 3,
      'title': 'Complete Flutter course module 5',
      'index': 0,
      'status': 1,
    });
    await db.insert('tasks', {
      'categoryId': 3,
      'title': 'Finish reading "Atomic Habits"',
      'index': 1,
      'status': 0,
    });
    await db.insert('tasks', {
      'categoryId': 3,
      'title': 'Practice guitar for 30 minutes',
      'index': 2,
      'status': 0,
    });
    await db.insert('tasks', {
      'categoryId': 3,
      'title': 'Learn React basics',
      'index': 3,
      'status': 1,
    });
    await db.insert('tasks', {
      'categoryId': 3,
      'title': 'Update personal website',
      'index': 4,
      'status': 0,
    });
    await db.insert('tasks', {
      'categoryId': 3,
      'title': 'Write blog post about productivity',
      'index': 5,
      'status': 0,
    });
    await db.insert('tasks', {
      'categoryId': 3,
      'title': 'Practice meditation',
      'index': 6,
      'status': 1,
    });

    // ========== HABITS - ĐA DẠNG HƠN VỚI CREATED DATE ==========
    final now = DateTime.now();

    // Habit 1: Morning Exercise - Started 90 days ago
    final exerciseId = await db.insert('habits', {
      'title': 'Morning Exercise',
      'description': '30 min workout',
      'index': 0,
      'days': '1,2,3,4,5',
      'time': now.copyWith(hour: 6, minute: 0).toIso8601String(),
      'reminder': 1,
      'frequency': 'weekly',
      'frequencyDays': 5,
      'createdDate': now.subtract(const Duration(days: 90)).toIso8601String(),
    });

    // Habit 2: Reading - Started 75 days ago
    final readingId = await db.insert('habits', {
      'title': 'Reading',
      'description': 'Read 20 pages',
      'index': 1,
      'days': '1,2,3,4,5,6,7',
      'time': now.copyWith(hour: 21, minute: 0).toIso8601String(),
      'reminder': 1,
      'frequency': 'weekly',
      'frequencyDays': 7,
      'createdDate': now.subtract(const Duration(days: 75)).toIso8601String(),
    });

    // Habit 3: Meditation - Started 60 days ago
    final meditationId = await db.insert('habits', {
      'title': 'Meditation',
      'description': '10 min mindfulness',
      'index': 2,
      'days': '1,2,3,4,5,6,7',
      'time': now.copyWith(hour: 7, minute: 0).toIso8601String(),
      'reminder': 0,
      'frequency': 'weekly',
      'frequencyDays': 5,
      'createdDate': now.subtract(const Duration(days: 60)).toIso8601String(),
    });

    // Habit 4: Drink Water - Started 90 days ago
    final waterId = await db.insert('habits', {
      'title': 'Drink Water',
      'description': '8 glasses per day',
      'index': 3,
      'days': '1,2,3,4,5,6,7',
      'time': now.copyWith(hour: 12, minute: 0).toIso8601String(),
      'reminder': 1,
      'frequency': 'weekly',
      'frequencyDays': 7,
      'createdDate': now.subtract(const Duration(days: 90)).toIso8601String(),
    });

    // Habit 5: Coding Practice - Started 45 days ago
    final codingId = await db.insert('habits', {
      'title': 'Coding Practice',
      'description': 'Practice coding for 1 hour',
      'index': 4,
      'days': '1,2,3,4,5',
      'time': now.copyWith(hour: 19, minute: 0).toIso8601String(),
      'reminder': 1,
      'frequency': 'monthly',
      'frequencyDays': 15,
      'createdDate': now.subtract(const Duration(days: 45)).toIso8601String(),
    });

    // Habit 6: Gym - Started 60 days ago
    final gymId = await db.insert('habits', {
      'title': 'Gym',
      'description': '1 hour workout',
      'index': 5,
      'days': '1,3,5',
      'time': now.copyWith(hour: 17, minute: 30).toIso8601String(),
      'reminder': 1,
      'frequency': 'weekly',
      'frequencyDays': 3,
      'createdDate': now.subtract(const Duration(days: 60)).toIso8601String(),
    });

    // Habit 7: Journal Writing - Started 30 days ago
    final journalId = await db.insert('habits', {
      'title': 'Journal Writing',
      'description': 'Write daily reflections',
      'index': 6,
      'days': '1,2,3,4,5,6,7',
      'time': now.copyWith(hour: 22, minute: 0).toIso8601String(),
      'reminder': 1,
      'frequency': 'weekly',
      'frequencyDays': 7,
      'createdDate': now.subtract(const Duration(days: 30)).toIso8601String(),
    });

    // Habit 8: Learn Spanish - Started 50 days ago
    final spanishId = await db.insert('habits', {
      'title': 'Learn Spanish',
      'description': '15 min Duolingo',
      'index': 7,
      'days': '1,2,3,4,5',
      'time': now.copyWith(hour: 20, minute: 0).toIso8601String(),
      'reminder': 1,
      'frequency': 'weekly',
      'frequencyDays': 5,
      'createdDate': now.subtract(const Duration(days: 50)).toIso8601String(),
    });

    // ========== HABIT STATUSES - DIVERSE PATTERNS ==========

    // Exercise: Perfect last 30 days
    for (int i = 0; i < 90; i++) {
      final date = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (date.weekday <= 5) {
        if (i < 30) {
          await db.insert('habit_status', {
            'habitId': exerciseId,
            'date': normalizedDate.toIso8601String(),
          });
        } else if ((i % 3) != 0) {
          await db.insert('habit_status', {
            'habitId': exerciseId,
            'date': normalizedDate.toIso8601String(),
          });
        }
      }
    }

    // Reading: 5-6 days per week
    for (int i = 0; i < 75; i++) {
      final date = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if ((i % 7) < 5 || (i % 13 == 0)) {
        await db.insert('habit_status', {
          'habitId': readingId,
          'date': normalizedDate.toIso8601String(),
        });
      }
    }

    // Meditation: Improving over time
    for (int i = 0; i < 60; i++) {
      final date = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (i < 14 && (i % 7) < 6) {
        await db.insert('habit_status', {
          'habitId': meditationId,
          'date': normalizedDate.toIso8601String(),
        });
      } else if (i < 45 && (i % 7) < 4) {
        await db.insert('habit_status', {
          'habitId': meditationId,
          'date': normalizedDate.toIso8601String(),
        });
      } else if ((i % 7) < 2) {
        await db.insert('habit_status', {
          'habitId': meditationId,
          'date': normalizedDate.toIso8601String(),
        });
      }
    }

    // Water: 90% completion
    for (int i = 0; i < 90; i++) {
      final date = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if ((i % 10) != 0) {
        await db.insert('habit_status', {
          'habitId': waterId,
          'date': normalizedDate.toIso8601String(),
        });
      }
    }

    // Coding: Weekdays 70%
    for (int i = 0; i < 45; i++) {
      final date = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (date.weekday <= 5 && (i % 10) < 7) {
        await db.insert('habit_status', {
          'habitId': codingId,
          'date': normalizedDate.toIso8601String(),
        });
      }
    }

    // Gym: Mon/Wed/Fri 80%
    for (int i = 0; i < 60; i++) {
      final date = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if ((date.weekday == 1 || date.weekday == 3 || date.weekday == 5) &&
          (i % 5) != 0) {
        await db.insert('habit_status', {
          'habitId': gymId,
          'date': normalizedDate.toIso8601String(),
        });
      }
    }

    // Journal: Last 25 days, 80% completion
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if ((i % 5) != 0) {
        await db.insert('habit_status', {
          'habitId': journalId,
          'date': normalizedDate.toIso8601String(),
        });
      }
    }

    // Spanish: Weekdays, improving from 40% to 80%
    for (int i = 0; i < 50; i++) {
      final date = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (date.weekday <= 5) {
        if (i < 15 && (i % 5) < 4) {
          await db.insert('habit_status', {
            'habitId': spanishId,
            'date': normalizedDate.toIso8601String(),
          });
        } else if ((i % 5) < 2) {
          await db.insert('habit_status', {
            'habitId': spanishId,
            'date': normalizedDate.toIso8601String(),
          });
        }
      }
    }
  }
}
