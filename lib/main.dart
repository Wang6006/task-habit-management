import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Tasks
import 'ui/tasks/tasks_manager.dart';
import 'ui/tasks/task_screen.dart';
import 'ui/tasks/edit_categories_screen.dart';
import 'ui/tasks/task_statistics_screen.dart';

// Habits
import 'ui/habits/habits_manager.dart';
import 'ui/habits/habits_list_screen.dart';

// Settings
import 'services/notifications.dart';
import 'ui/settings/settings_manager.dart';
import 'ui/settings/settings_screen.dart';
import './ui/shared/theme_manager.dart';
import './ui/shared/app_theme.dart';
import './ui/shared/main_nav_scaffold.dart';

import 'database_helper.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/tasks',
  routes: [
    // ========== MAIN SCREENS  ==========
    ShellRoute(
      builder: (context, state, child) {
        return MainNavScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/tasks',
          name: TaskScreen.routeName,
          pageBuilder: (context, state) =>
              NoTransitionPage(child: const TaskScreen()),
        ),
        GoRoute(
          path: '/habits',
          name: HabitsListScreen.routeName,
          pageBuilder: (context, state) =>
              NoTransitionPage(child: const HabitsListScreen()),
        ),
        GoRoute(
          path: '/settings',
          name: SettingsScreen.routeName,
          pageBuilder: (context, state) =>
              NoTransitionPage(child: const SettingsScreen()),
        ),
      ],
    ),

    // ========== SECONDARY SCREENS  ==========
    GoRoute(
      path: '/task-statistics',
      name: TaskStatisticsScreen.routeName,
      builder: (context, state) => const TaskStatisticsScreen(),
    ),
    GoRoute(
      path: '/edit-categories',
      name: EditCategoriesScreen.routeName,
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const EditCategoriesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      },
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.seedDemoData();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(
          create: (_) => SettingsManager()..loadSettings(),
        ),
        Provider<NotificationService>(create: (_) => NotificationService()),

        ChangeNotifierProxyProvider2<
          NotificationService,
          SettingsManager,
          TasksManager
        >(
          create: (_) => TasksManager(),
          update: (_, notificationService, settingsManager, manager) {
            manager ??= TasksManager();
            manager.setNotificationService(notificationService);
            manager.setSettingsManager(settingsManager);
            return manager;
          },
        ),

        ChangeNotifierProxyProvider2<
          NotificationService,
          SettingsManager,
          HabitsManager
        >(
          create: (_) => HabitsManager(),
          update: (_, notificationService, settingsManager, manager) {
            manager ??= HabitsManager();
            manager.setNotificationService(notificationService);
            manager.setSettingsManager(settingsManager);
            return manager;
          },
        ),
      ],
      child: Consumer2<ThemeManager, SettingsManager>(
        builder: (context, themeManager, settingsManager, child) {
          final multiplier = settingsManager.fontSizeMultiplier;
          final seedColor = settingsManager.themeColor.color;

          return MaterialApp.router(
            title: 'Time Management',
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            theme: AppTheme.getLightTheme(multiplier, seedColor),
            darkTheme: AppTheme.getDarkTheme(multiplier, seedColor),
            themeMode: themeManager.themeMode,
          );
        },
      ),
    );
  }
}
