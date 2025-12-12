import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/habit.dart';
import './habits_manager.dart';
import './habit_streak_card.dart';
import './habit_start_card.dart';
import './weekly_activity_chart.dart';
import './habit_upsert_sheet.dart';
import '../../../models/habit_status.dart';

class HabitAnalyticsScreen extends StatefulWidget {
  final Habit habit;

  const HabitAnalyticsScreen({super.key, required this.habit});

  @override
  State<HabitAnalyticsScreen> createState() => _HabitAnalyticsScreenState();
}

class _HabitAnalyticsScreenState extends State<HabitAnalyticsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => HabitUpsertSheet(
        habit: widget.habit,
        onSave: (updatedHabit) async {
          await context.read<HabitsManager>().updateHabit(updatedHabit);
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Delete Habit'),
        content: const Text(
          'Are you sure you want to delete this habit? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<HabitsManager>().deleteHabit(widget.habit);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitsManager>(
      builder: (context, manager, child) {
        final currentHabit = manager.habits.firstWhere(
          (h) => h.id == widget.habit.id,
          orElse: () => widget.habit,
        );

        final statuses = manager.habitsWithStatuses[currentHabit] ?? [];
        final currentStreak = manager.getCurrentStreak(currentHabit);
        final bestStreak = manager.getBestStreak(currentHabit);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentHabit.title),
                if (currentHabit.description.isNotEmpty)
                  Text(
                    currentHabit.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _showDeleteDialog,
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _showEditSheet,
              ),
            ],
          ),
          body: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                return _buildLandscapeLayout(
                  context,
                  manager,
                  currentHabit,
                  statuses,
                  currentStreak,
                  bestStreak,
                );
              } else {
                return _buildPortraitLayout(
                  context,
                  manager,
                  currentHabit,
                  statuses,
                  currentStreak,
                  bestStreak,
                );
              }
            },
          ),
        );
      },
    );
  }

  // ========== PORTRAIT LAYOUT ==========
  Widget _buildPortraitLayout(
    BuildContext context,
    HabitsManager manager,
    Habit habit,
    List<HabitStatus> statuses,
    int currentStreak,
    int bestStreak,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HabitStartCard(startDate: habit.createdDate),
        const SizedBox(height: 12),
        _buildFrequencyCard(context, habit, statuses),
        const SizedBox(height: 12),
        HabitStreakCard(
          currentStreak: currentStreak,
          bestStreak: bestStreak,
          frequencyType: habit.frequency,
        ),
        const SizedBox(height: 12),
        WeeklyActivityChart(statuses: statuses, habit: habit),
        const SizedBox(height: 12),
        _buildCalendarCard(context, manager, habit, statuses),
        const SizedBox(height: 12),
        _buildWeekdayBreakdown(context, statuses, habit),
      ],
    );
  }

  // ========== LANDSCAPE LAYOUT ==========
  Widget _buildLandscapeLayout(
    BuildContext context,
    HabitsManager manager,
    Habit habit,
    List<HabitStatus> statuses,
    int currentStreak,
    int bestStreak,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Row 1: Info cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    HabitStartCard(startDate: habit.createdDate),
                    const SizedBox(height: 12),
                    _buildFrequencyCard(context, habit, statuses),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HabitStreakCard(
                  currentStreak: currentStreak,
                  bestStreak: bestStreak,
                  frequencyType: habit.frequency,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Chart
          WeeklyActivityChart(statuses: statuses, habit: habit),
          const SizedBox(height: 12),

          // Row 3: Calendar + Weekday breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildCalendarCard(context, manager, habit, statuses),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildWeekdayBreakdown(context, statuses, habit),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyCard(
    BuildContext context,
    Habit habit,
    List<HabitStatus> statuses,
  ) {
    final frequencyText = habit.getFrequencyText();
    final targetReached = habit.isTargetReachedInCurrentPeriod(statuses);

    return Card(
      elevation: 2,
      color: targetReached
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8)
          : Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: targetReached
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                habit.frequency == 'weekly'
                    ? Icons.calendar_view_week
                    : Icons.calendar_month,
                color: targetReached
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSecondary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequency Target',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: targetReached
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      frequencyText,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: targetReached
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                          ),
                    ),
                  ),
                  if (targetReached)
                    Text(
                      'Target reached! ✓',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard(
    BuildContext context,
    HabitsManager manager,
    Habit habit,
    List<HabitStatus> statuses,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Calendar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TableCalendar(
              firstDay: habit.createdDate,
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (selectedDay.isBefore(
                      DateTime.now().add(const Duration(days: 1)),
                    ) &&
                    habit.days.contains(selectedDay.weekday)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  manager.toggleHabitStatus(habit, date: selectedDay);
                }
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                markersMaxCount: 1,
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final isCompleted = manager.isHabitCompletedOn(habit, day);
                  final isValidDay = habit.days.contains(day.weekday);

                  if (isCompleted) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }

                  if (!isValidDay) {
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    );
                  }

                  return null;
                },
                todayBuilder: (context, day, focusedDay) {
                  final isCompleted = manager.isHabitCompletedOn(habit, day);

                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isCompleted
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  final isCompleted = manager.isHabitCompletedOn(habit, day);
                  final isToday = isSameDay(day, DateTime.now());

                  if (isToday) return null;

                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.7)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isCompleted
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
                outsideBuilder: (context, day, focusedDay) {
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.2),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayBreakdown(
    BuildContext context,
    List<HabitStatus> statuses,
    Habit habit,
  ) {
    final Map<int, int> weekdayCount = {};
    for (var status in statuses) {
      final weekday = status.date.weekday;
      weekdayCount[weekday] = (weekdayCount[weekday] ?? 0) + 1;
    }

    final maxCount = weekdayCount.values.isEmpty
        ? 1
        : weekdayCount.values.reduce((a, b) => a > b ? a : b);

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                    'Weekly Breakdown',
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
              final count = weekdayCount[day] ?? 0;
              final percentage = maxCount > 0 ? count / maxCount : 0.0;
              final isScheduledDay = habit.days.contains(day);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        dayNames[index],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isScheduledDay
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isScheduledDay
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
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
                              duration: const Duration(milliseconds: 300),
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
                    if (!isScheduledDay)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.remove_circle_outline,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.3),
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
}
