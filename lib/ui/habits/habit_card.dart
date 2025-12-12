import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/habit.dart';
import '../../../models/habit_status.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final List<HabitStatus> statuses;
  final bool isCompleted;
  final bool compactView;
  final VoidCallback onTap;
  final VoidCallback onAnalytics;
  final Widget? reorderHandle;

  const HabitCard({
    super.key,
    required this.habit,
    required this.statuses,
    required this.isCompleted,
    required this.compactView,
    required this.onTap,
    required this.onAnalytics,
    this.reorderHandle,
  });

  int _getCurrentStreak() {
    if (statuses.isEmpty) return 0;
    final sortedDates = statuses.map((s) => s.normalizedDate).toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime expectedDate = DateTime.now();
    expectedDate = DateTime(
      expectedDate.year,
      expectedDate.month,
      expectedDate.day,
    );

    for (var date in sortedDates) {
      while (!habit.days.contains(expectedDate.weekday)) {
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      }

      if (date == expectedDate) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Color _getCardColor(BuildContext context, bool canCompleteToday) {
    if (isCompleted) {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    return Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(
      canCompleteToday ? 1.0 : 0.7,
    );
  }

  Color _getContentColor(BuildContext context, bool canCompleteToday) {
    if (isCompleted) {
      return Theme.of(context).colorScheme.onPrimaryContainer;
    }
    return Theme.of(
      context,
    ).colorScheme.onSurface.withOpacity(canCompleteToday ? 1.0 : 0.7);
  }

  @override
  Widget build(BuildContext context) {
    final canCompleteToday = habit.isActiveToday();
    final cardColor = _getCardColor(context, canCompleteToday);
    final contentColor = _getContentColor(context, canCompleteToday);
    final streak = habit.getCurrentStreakByFrequency(statuses);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: InkWell(
          onTap: canCompleteToday ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        key: ValueKey(isCompleted),
                        color: contentColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: contentColor,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (habit.reminder)
                            Text(
                              DateFormat('hh:mm a').format(habit.time),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: contentColor.withOpacity(0.7),
                                  ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: contentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$streak',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: contentColor,
                              ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.analytics_outlined, color: contentColor),
                      onPressed: onAnalytics,
                    ),
                    if (reorderHandle != null) reorderHandle!,
                  ],
                ),
                if (!compactView) ...[
                  const SizedBox(height: 12),
                  _buildWeekView(context, contentColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekView(BuildContext context, Color contentColor) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return SizedBox(
      height: 60,
      child: Row(
        children: List.generate(7, (index) {
          final date = startOfWeek.add(Duration(days: index));
          final normalizedDate = DateTime(date.year, date.month, date.day);
          final isCompleted = statuses.any(
            (s) => s.normalizedDate == normalizedDate,
          );
          final isValidDay = habit.days.contains(date.weekday);
          final isToday =
              normalizedDate == DateTime(now.year, now.month, now.day);

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isToday
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isCompleted
                          ? Theme.of(context).colorScheme.onPrimary
                          : isValidDay
                          ? contentColor
                          : contentColor.withOpacity(0.3),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    DateFormat('EEE').format(date).substring(0, 3),
                    style: TextStyle(
                      fontSize: 10,
                      color: isCompleted
                          ? Theme.of(context).colorScheme.onPrimary
                          : isValidDay
                          ? contentColor
                          : contentColor.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
