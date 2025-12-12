import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../tasks/tasks_manager.dart';
import '../shared/theme_manager.dart';
import 'settings_manager.dart';
import '../../services/notifications.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsManager = context.watch<SettingsManager>();
    final tasksManager = context.watch<TasksManager>();
    final themeManager = context.watch<ThemeManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: false),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return _buildLandscapeLayout(
              context,
              theme,
              settingsManager,
              tasksManager,
              themeManager,
            );
          } else {
            return _buildPortraitLayout(
              context,
              theme,
              settingsManager,
              tasksManager,
              themeManager,
            );
          }
        },
      ),
    );
  }

  // ========== PORTRAIT LAYOUT ==========
  Widget _buildPortraitLayout(
    BuildContext context,
    ThemeData theme,
    SettingsManager settingsManager,
    TasksManager tasksManager,
    ThemeManager themeManager,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildAppearanceSection(context, theme, settingsManager, themeManager),
        const SizedBox(height: 8),
        _buildNotificationsSection(context, theme, settingsManager),
        const SizedBox(height: 8),
        _buildTaskSettingsSection(context, theme, tasksManager),
        const SizedBox(height: 8),
        _buildAdvancedSection(context, theme, settingsManager),
        const SizedBox(height: 8),
        _buildAboutSection(context, theme),
        const SizedBox(height: 24),
      ],
    );
  }

  // ========== LANDSCAPE LAYOUT ==========
  Widget _buildLandscapeLayout(
    BuildContext context,
    ThemeData theme,
    SettingsManager settingsManager,
    TasksManager tasksManager,
    ThemeManager themeManager,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            child: Column(
              children: [
                _buildAppearanceSection(
                  context,
                  theme,
                  settingsManager,
                  themeManager,
                ),
                const SizedBox(height: 10),
                _buildAdvancedSection(context, theme, settingsManager),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right Column
          Expanded(
            child: Column(
              children: [
                _buildNotificationsSection(context, theme, settingsManager),
                const SizedBox(height: 10),
                _buildTaskSettingsSection(context, theme, tasksManager),
                const SizedBox(height: 10),
                _buildAboutSection(context, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =================== APPEARANCE SECTION ===================
  Widget _buildAppearanceSection(
    BuildContext context,
    ThemeData theme,
    SettingsManager settingsManager,
    ThemeManager themeManager,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Appearance'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme Mode
                Text(
                  'Theme',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Auto'),
                        icon: Icon(Icons.brightness_auto, size: 18),
                      ),
                    ],
                    selected: {themeManager.themeMode},
                    onSelectionChanged: (newSelection) {
                      themeManager.setThemeMode(newSelection.first);
                    },
                  ),
                ),

                const Divider(height: 32),

                // Theme Color
                Text(
                  'Theme Color',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: AppThemeColor.values.map((color) {
                      final isSelected = settingsManager.themeColor == color;
                      return GestureDetector(
                        onTap: () => settingsManager.setThemeColor(color),
                        child: Tooltip(
                          message: color.label,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: theme.colorScheme.onSurface,
                                      width: 3,
                                    )
                                  : Border.all(
                                      color: Colors.transparent,
                                      width: 3,
                                    ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.color.withOpacity(0.5),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                      ),
                                    ],
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check_rounded,
                                    color: _getContrastColor(color.color),
                                    size: 24,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const Divider(height: 32),

                // Font Size
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Font Size',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        settingsManager.fontSizeLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(
                    context,
                  ).copyWith(showValueIndicator: ShowValueIndicator.always),
                  child: Slider(
                    value: settingsManager.fontSizeStep,
                    min: 0.0,
                    max: 2.0,
                    divisions: 2,
                    label: settingsManager.fontSizeLabel,
                    onChanged: (newValue) {
                      settingsManager.setFontSizeStep(newValue);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===================  NOTIFICATIONS SECTION ===================
  Widget _buildNotificationsSection(
    BuildContext context,
    ThemeData theme,
    SettingsManager settingsManager,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Notifications'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive reminders for tasks and habits'),
            secondary: Icon(
              Icons.notifications_outlined,
              color: theme.colorScheme.primary,
            ),
            value: settingsManager.allNotificationsEnabled,
            onChanged: (value) {
              context.read<SettingsManager>().setAllNotifications(value);
              if (!value) {
                context.read<NotificationService>().cancelAllNotifications();
              }
            },
          ),
        ),
      ],
    );
  }

  // ===================  TASK SETTINGS SECTION ===================
  Widget _buildTaskSettingsSection(
    BuildContext context,
    ThemeData theme,
    TasksManager tasksManager,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Task Settings'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SwitchListTile(
            title: const Text('Auto-reorder Completed Tasks'),
            subtitle: const Text('Move completed tasks to the bottom'),
            secondary: Icon(
              Icons.low_priority_outlined,
              color: theme.colorScheme.primary,
            ),
            value: tasksManager.reorderTasksOnComplete,
            onChanged: (value) {
              tasksManager.setReorderOnComplete(value);
            },
          ),
        ),
      ],
    );
  }

  // ===================  ADVANCED SECTION ===================
  Widget _buildAdvancedSection(
    BuildContext context,
    ThemeData theme,
    SettingsManager settingsManager,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Advanced'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // START WEEK - RESPONSIVE LAYOUT
              isSmallScreen
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Start Week',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<StartDay>(
                            segments: const [
                              ButtonSegment(
                                value: StartDay.monday,
                                label: Text('Monday'),
                              ),
                              ButtonSegment(
                                value: StartDay.sunday,
                                label: Text('Sunday'),
                              ),
                            ],
                            selected: {settingsManager.startDay},
                            onSelectionChanged: (newSelection) {
                              settingsManager.setStartDay(newSelection.first);
                            },
                          ),
                        ],
                      ),
                    )
                  : ListTile(
                      leading: Icon(
                        Icons.calendar_today_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Start Week'),
                      trailing: SegmentedButton<StartDay>(
                        segments: const [
                          ButtonSegment(
                            value: StartDay.monday,
                            label: Text('Mon'),
                          ),
                          ButtonSegment(
                            value: StartDay.sunday,
                            label: Text('Sun'),
                          ),
                        ],
                        selected: {settingsManager.startDay},
                        onSelectionChanged: (newSelection) {
                          settingsManager.setStartDay(newSelection.first);
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
              const Divider(height: 1),

              // COMPLETION SOUNDS
              SwitchListTile(
                title: const Text('Completion Sounds'),
                subtitle: const Text('Play a sound when completing a task'),
                secondary: Icon(
                  Icons.volume_up_outlined,
                  color: theme.colorScheme.primary,
                ),
                value: settingsManager.completionSoundsEnabled,
                onChanged: (value) {
                  settingsManager.setCompletionSounds(value);
                },
              ),
              const Divider(height: 1),

              // HAPTIC FEEDBACK
              SwitchListTile(
                title: const Text('Haptic Feedback'),
                subtitle: const Text('Vibrate on interactions'),
                secondary: Icon(
                  Icons.vibration_outlined,
                  color: theme.colorScheme.primary,
                ),
                value: settingsManager.hapticsEnabled,
                onChanged: (value) {
                  settingsManager.setHaptics(value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================  ABOUT SECTION ===================
  Widget _buildAboutSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'About'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.code_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Developer'),
                subtitle: const Text('Built with Flutter & Material Design 3'),
                onTap: () {
                  // Optional: Link to GitHub
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- HELPER: Section Header ---
  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // --- HELPER: Get Contrast Color ---
  Color _getContrastColor(Color background) {
    final luminance =
        (0.299 * background.red +
            0.587 * background.green +
            0.114 * background.blue) /
        255;
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
