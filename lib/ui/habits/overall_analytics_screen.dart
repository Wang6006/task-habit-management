import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import './habits_manager.dart';

class OverallAnalyticsScreen extends StatefulWidget {
  const OverallAnalyticsScreen({super.key});

  @override
  State<OverallAnalyticsScreen> createState() => _OverallAnalyticsScreenState();
}

class _OverallAnalyticsScreenState extends State<OverallAnalyticsScreen> {
  int _selectedMonths = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overall Analytics')),
      body: Consumer<HabitsManager>(
        builder: (context, manager, child) {
          final heatMapData = _prepareHeatMapData(manager);
          final weekdayData = _prepareWeekdayData(manager);
          final totalCompletions = heatMapData.values.fold(
            0,
            (sum, val) => sum + val,
          );
          final completionRate = _calculateCompletionRate(manager);
          final currentStreak = _getCurrentOverallStreak(manager);

          return OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                return _buildLandscapeLayout(
                  context,
                  manager,
                  totalCompletions,
                  completionRate,
                  currentStreak,
                  heatMapData,
                  weekdayData,
                );
              } else {
                return _buildPortraitLayout(
                  context,
                  manager,
                  totalCompletions,
                  completionRate,
                  currentStreak,
                  heatMapData,
                  weekdayData,
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    HabitsManager manager,
    int totalCompletions,
    double completionRate,
    int currentStreak,
    Map<DateTime, int> heatMapData,
    Map<int, int> weekdayData,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsGrid(
          context,
          manager,
          totalCompletions,
          completionRate,
          currentStreak,
        ),
        const SizedBox(height: 12),
        _buildHeatMap(context, heatMapData),
        const SizedBox(height: 12),
        _buildWeekdayChart(context, weekdayData),
        const SizedBox(height: 12),
        _buildHabitsList(context, manager),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    HabitsManager manager,
    int totalCompletions,
    double completionRate,
    int currentStreak,
    Map<DateTime, int> heatMapData,
    Map<int, int> weekdayData,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildStatsGrid(
                      context,
                      manager,
                      totalCompletions,
                      completionRate,
                      currentStreak,
                    ),
                    const SizedBox(height: 12),
                    _buildWeekdayChart(context, weekdayData),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildHeatMap(context, heatMapData),
                    const SizedBox(height: 12),
                    _buildHabitsList(context, manager),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    HabitsManager manager,
    int totalCompletions,
    double completionRate,
    int currentStreak,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            context,
                            'Total Habits',
                            '${manager.totalHabits}',
                            Icons.self_improvement,
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            context,
                            'Completions',
                            '$totalCompletions',
                            Icons.check_circle,
                            Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            context,
                            'Success Rate',
                            '${completionRate.toStringAsFixed(0)}%',
                            Icons.trending_up,
                            Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            context,
                            'Current Streak',
                            '$currentStreak days',
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatMap(BuildContext context, Map<DateTime, int> data) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: 30 * _selectedMonths));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grid_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Activity Heatmap',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                _buildMonthChip(3),
                _buildMonthChip(6),
                _buildMonthChip(12),
              ],
            ),
            const SizedBox(height: 16),
            HeatMap(
              datasets: data,
              colorMode: ColorMode.opacity,
              showText: false,
              scrollable: true,
              size: 28,
              fontSize: 10,
              colorsets: {1: Theme.of(context).colorScheme.primary},
              startDate: startDate,
              endDate: now,
              showColorTip: false,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Less', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                ...List.generate(5, (index) {
                  return Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.2 + (index * 0.2)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                Text('More', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthChip(int months) {
    final isSelected = _selectedMonths == months;
    return FilterChip(
      label: Text('$months months'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedMonths = months;
        });
      },
    );
  }

  Widget _buildWeekdayChart(BuildContext context, Map<int, int> weekdayData) {
    final maxCount = weekdayData.values.isEmpty
        ? 1
        : weekdayData.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Weekly Distribution',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(7, (index) {
              final day = index + 1;
              final count = weekdayData[day] ?? 0;
              final percentage = maxCount > 0 && count > 0
                  ? count / maxCount
                  : 0.0;
              final dayNames = [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun',
              ];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        dayNames[index],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: count > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          if (count > 0)
                            AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                              widthFactor: percentage,
                              child: Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsList(BuildContext context, HabitsManager manager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Habits Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...manager.habits.map((habit) {
              final currentStreak = manager.getCurrentStreak(habit);
              final bestStreak = manager.getBestStreak(habit);
              final statuses = manager.habitsWithStatuses[habit] ?? [];
              final completion = statuses.length;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_fire_department,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    habit.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Current: $currentStreak • Best: $bestStreak',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$completion',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<DateTime, int> _prepareHeatMapData(HabitsManager manager) {
    final Map<DateTime, int> heatMap = {};

    for (var entry in manager.habitsWithStatuses.entries) {
      for (var status in entry.value) {
        final normalizedDate = status.normalizedDate;
        heatMap[normalizedDate] = (heatMap[normalizedDate] ?? 0) + 1;
      }
    }

    return heatMap;
  }

  Map<int, int> _prepareWeekdayData(HabitsManager manager) {
    final Map<int, int> weekdayCount = {};

    for (var entry in manager.habitsWithStatuses.entries) {
      for (var status in entry.value) {
        final weekday = status.date.weekday;
        weekdayCount[weekday] = (weekdayCount[weekday] ?? 0) + 1;
      }
    }

    return weekdayCount;
  }

  double _calculateCompletionRate(HabitsManager manager) {
    if (manager.totalHabits == 0) return 0;

    int totalExpected = 0;
    int totalCompleted = 0;

    for (var entry in manager.habitsWithStatuses.entries) {
      final habit = entry.key;
      final statuses = entry.value;

      final daysSinceCreation =
          DateTime.now().difference(habit.createdDate).inDays + 1;

      for (int i = 0; i < daysSinceCreation; i++) {
        final date = habit.createdDate.add(Duration(days: i));
        if (habit.days.contains(date.weekday)) {
          totalExpected++;
        }
      }

      totalCompleted += statuses.length;
    }

    return totalExpected > 0 ? (totalCompleted / totalExpected * 100) : 0;
  }

  int _getCurrentOverallStreak(HabitsManager manager) {
    if (manager.habits.isEmpty) return 0;

    final now = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(
        checkDate.year,
        checkDate.month,
        checkDate.day,
      );

      bool hasAnyCompletion = false;

      for (var entry in manager.habitsWithStatuses.entries) {
        final habit = entry.key;
        final statuses = entry.value;

        if (habit.days.contains(checkDate.weekday)) {
          if (statuses.any((s) => s.normalizedDate == normalizedDate)) {
            hasAnyCompletion = true;
            break;
          }
        }
      }

      if (hasAnyCompletion) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }
}
