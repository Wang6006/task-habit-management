import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../tasks/tasks_manager.dart';
import '../habits/habits_manager.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCard(context),
            const SizedBox(height: 16),
            _buildTasksSection(context),
            const SizedBox(height: 16),
            _buildHabitsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    return Consumer2<TasksManager, HabitsManager>(
      builder: (context, tasksManager, habitsManager, child) {
        final totalTasks = tasksManager.totalTasks;
        final completedTasks = tasksManager.completedTasks.length;
        final totalHabits = habitsManager.totalHabits;
        final completedHabitsToday = habitsManager.completedCount;

        return Card(
          elevation: 4,
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
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Tasks',
                        '$completedTasks / $totalTasks',
                        Icons.task_alt,
                        totalTasks > 0 ? completedTasks / totalTasks : 0.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Habits Today',
                        '$completedHabitsToday / $totalHabits',
                        Icons.self_improvement,
                        totalHabits > 0
                            ? completedHabitsToday / totalHabits
                            : 0.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection(BuildContext context) {
    return Consumer<TasksManager>(
      builder: (context, manager, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.task_alt,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tasks',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/tasks');
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric(context, 'Total', '${manager.totalTasks}'),
                    _buildMetric(
                      context,
                      'Completed',
                      '${manager.completedTasks.length}',
                    ),
                    _buildMetric(
                      context,
                      'Categories',
                      '${manager.categories.length}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHabitsSection(BuildContext context) {
    return Consumer<HabitsManager>(
      builder: (context, manager, child) {
        final totalStreaks = manager.habits.fold(
          0,
          (sum, habit) => sum + manager.getCurrentStreak(habit),
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.self_improvement,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Habits',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/habits');
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric(context, 'Total', '${manager.totalHabits}'),
                    _buildMetric(context, 'Today', '${manager.completedCount}'),
                    _buildMetric(context, 'Streaks', '$totalStreaks'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
