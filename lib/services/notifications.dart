import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone data
    tz_data.initializeTimeZones();

    // Set default timezone to Vietnam
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    debugPrint('>>> TIMEZONE: Asia/Ho_Chi_Minh');
    debugPrint('>>> CURRENT TIME: ${tz.TZDateTime.now(tz.local)}');

    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@drawable/icon_splash',
    );
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        debugPrint('>>> NOTIFICATION TAPPED: ${response.payload}');
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'habit_reminder_channel',
      'Habit Reminders',
      description: 'Daily habit completion reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
      'task_reminder_channel',
      'Task Reminders',
      description: 'Task deadline reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(taskChannel);

    debugPrint('>>> NOTIFICATION SERVICE INITIALIZED');
  }

  // ========== PERMISSION HANDLING ==========

  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    try {
      debugPrint('>>> REQUESTING NOTIFICATION PERMISSIONS');

      // Request POST_NOTIFICATIONS permission (Android 13+)
      final notificationStatus = await Permission.notification.request();
      debugPrint('>>> NOTIFICATION PERMISSION: ${notificationStatus.name}');

      if (!notificationStatus.isGranted) {
        debugPrint('>>> NOTIFICATION PERMISSION DENIED');
        return false;
      }

      // Check and request SCHEDULE_EXACT_ALARM permission
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final canSchedule = await androidPlugin.canScheduleExactNotifications();
        debugPrint('>>> CAN SCHEDULE EXACT ALARMS: $canSchedule');

        if (canSchedule == false) {
          debugPrint('>>> NEED TO REQUEST EXACT ALARM PERMISSION');
          // This will open system settings
          await androidPlugin.requestExactAlarmsPermission();

          // Check again after user returns
          await Future.delayed(const Duration(milliseconds: 500));
          final canScheduleNow = await androidPlugin
              .canScheduleExactNotifications();

          if (canScheduleNow == false) {
            debugPrint('>>> EXACT ALARM PERMISSION STILL NOT GRANTED');
            return false;
          }
        }
      }

      debugPrint('>>> ALL PERMISSIONS GRANTED');
      return true;
    } catch (e) {
      debugPrint('>>> ERROR REQUESTING PERMISSIONS: $e');
      return false;
    }
  }

  /// Check if all required permissions are granted
  Future<bool> hasNotificationPermissions() async {
    try {
      // Check notification permission
      final notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        return false;
      }

      // Check exact alarm permission
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final canSchedule = await androidPlugin.canScheduleExactNotifications();
        return canSchedule ?? true;
      }

      return true;
    } catch (e) {
      debugPrint('>>> ERROR CHECKING PERMISSIONS: $e');
      return false;
    }
  }

  // ========== TASK NOTIFICATIONS ==========

  /// Schedule task reminder (one-time notification)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      debugPrint('>>> SCHEDULING TASK REMINDER: $title');
      debugPrint('    Scheduled for: $scheduledDate');
      debugPrint('    Current time: ${DateTime.now()}');

      // Convert to TZDateTime
      tz.TZDateTime scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);
      tz.TZDateTime now = tz.TZDateTime.now(tz.local);

      // Add 1 minute buffer to prevent immediate past time
      if (scheduledTZ.difference(now).inMinutes < 1) {
        debugPrint(
          '>>> ERROR: Scheduled time must be at least 1 minute in the future',
        );
        debugPrint('    Scheduled: $scheduledTZ');
        debugPrint('    Now: $now');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'task_reminder_channel',
        'Task Reminders',
        channelDescription: 'Task deadline reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        autoCancel: true,
        icon: '@drawable/icon_splash',
        largeIcon: FilePathAndroidBitmap('assets/icon/icon.png'),
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'task_$id',
      );

      debugPrint('>>> TASK REMINDER SCHEDULED SUCCESSFULLY');
      debugPrint('    ID: $id');
      debugPrint('    Time: $scheduledTZ');
      await _debugPendingNotifications();
    } catch (e) {
      debugPrint('>>> ERROR SCHEDULING TASK REMINDER: $e');
      rethrow;
    }
  }

  // ========== HABIT NOTIFICATIONS ==========

  /// Schedule habit reminder - finds next valid date based on active days
  /// NOTE: This schedules ONE notification. After it fires, you need to reschedule
  /// for the next occurrence (handle this in your app's notification response)
  Future<void> scheduleHabitReminder({
    required int habitId,
    required String habitTitle,
    required String description,
    required DateTime reminderTime,
    required Set<int> activeDays,
  }) async {
    try {
      debugPrint('>>> SCHEDULING HABIT REMINDER: $habitTitle');

      // No need to check permission here - already checked before calling

      // Find next valid date
      tz.TZDateTime nextScheduleDate = tz.TZDateTime.from(
        reminderTime,
        tz.local,
      );
      tz.TZDateTime now = tz.TZDateTime.now(tz.local);

      // Set to reminder time
      nextScheduleDate = tz.TZDateTime(
        tz.local,
        nextScheduleDate.year,
        nextScheduleDate.month,
        nextScheduleDate.day,
        reminderTime.hour,
        reminderTime.minute,
        0,
      );

      // If time already passed today, start from tomorrow
      if (nextScheduleDate.isBefore(now) ||
          nextScheduleDate.difference(now).inMinutes < 1) {
        nextScheduleDate = nextScheduleDate.add(const Duration(days: 1));
      }

      // Find next active day (max 7 days search)
      bool foundValidDay = false;
      for (int i = 0; i < 7; i++) {
        if (activeDays.contains(nextScheduleDate.weekday)) {
          foundValidDay = true;
          debugPrint(
            '>>> FOUND VALID DAY: ${_getDayName(nextScheduleDate.weekday)} at $nextScheduleDate',
          );
          break;
        }
        nextScheduleDate = nextScheduleDate.add(const Duration(days: 1));
      }

      if (!foundValidDay) {
        debugPrint('>>> ERROR: No valid day found within 7 days');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'habit_reminder_channel',
        'Habit Reminders',
        channelDescription: 'Daily habit completion reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        autoCancel: false,
        icon: '@drawable/icon_splash',
        largeIcon: FilePathAndroidBitmap('assets/icon/icon.png'),
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _plugin.zonedSchedule(
        habitId,
        habitTitle,
        description.isEmpty ? 'Time to complete your habit!' : description,
        nextScheduleDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'habit_$habitId',
      );

      debugPrint(
        '>>> HABIT REMINDER SCHEDULED: $habitTitle for $nextScheduleDate',
      );
      await _debugPendingNotifications();
    } catch (e) {
      debugPrint('>>> ERROR SCHEDULING HABIT REMINDER: $e');
      rethrow;
    }
  }

  // ========== COMMON METHODS ==========

  /// Cancel notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
      debugPrint('>>> NOTIFICATION CANCELLED: ID $id');
      await _debugPendingNotifications();
    } catch (e) {
      debugPrint('>>> ERROR CANCELLING NOTIFICATION: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
      debugPrint('>>> ALL NOTIFICATIONS CANCELLED');
    } catch (e) {
      debugPrint('>>> ERROR CANCELLING ALL: $e');
    }
  }

  /// Debug: Show all pending notifications
  Future<void> _debugPendingNotifications() async {
    try {
      final pendingNotifications = await _plugin.pendingNotificationRequests();
      debugPrint('>>> PENDING NOTIFICATIONS: ${pendingNotifications.length}');
      for (final notif in pendingNotifications) {
        debugPrint('    - ID: ${notif.id}, Title: ${notif.title}');
      }
    } catch (e) {
      debugPrint('>>> ERROR GETTING PENDING NOTIFICATIONS: $e');
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Future<void> debugPendingNotifications() async {
    await _debugPendingNotifications();
  }
}
