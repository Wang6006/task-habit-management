import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'tasks_manager.dart';

class TaskStatisticsScreen extends StatelessWidget {
  static const routeName = '/task-statistics';

  const TaskStatisticsScreen({super.key});

  bool _isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape = _isLandscape(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Task Statistics')),
      body: Consumer<TasksManager>(
        builder: (ctx, tasksManager, _) {
          if (tasksManager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalTasks = tasksManager.totalTasks;
          final completedTasks = tasksManager.completedTasks.length;
          final pendingTasks = totalTasks - completedTasks;
          final completionRate = totalTasks > 0
              ? (completedTasks / totalTasks * 100).toStringAsFixed(1)
              : '0.0';

          if (isLandscape) {
            // LANDSCAPE LAYOUT - 2 columns
            return Row(
              children: [
                // Left column - Overview & Stats
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Circular progress
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Overall Progress',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 120,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        height: 120,
                                        child: CircularProgressIndicator(
                                          value: totalTasks > 0
                                              ? completedTasks / totalTasks
                                              : 0,
                                          strokeWidth: 10,
                                          backgroundColor: theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$completionRate%',
                                            style: theme.textTheme.headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            'Completed',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Stats grid 2x2
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: [
                            _StatCard(
                              title: 'Total',
                              value: totalTasks.toString(),
                              icon: Icons.task_alt,
                              color: theme.colorScheme.primary,
                              compact: true,
                            ),
                            _StatCard(
                              title: 'Categories',
                              value: tasksManager.categories.length.toString(),
                              icon: Icons.category,
                              color: theme.colorScheme.secondary,
                              compact: true,
                            ),
                            _StatCard(
                              title: 'Completed',
                              value: completedTasks.toString(),
                              icon: Icons.check_circle,
                              color: Colors.green,
                              compact: true,
                            ),
                            _StatCard(
                              title: 'Pending',
                              value: pendingTasks.toString(),
                              icon: Icons.pending,
                              color: Colors.orange,
                              compact: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Right column - Category breakdown
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tasks by Category',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ...tasksManager.categories.map((category) {
                          final categoryTasks =
                              tasksManager.tasks[category] ?? [];
                          final completed = categoryTasks
                              .where((t) => t.status)
                              .length;
                          final total = categoryTasks.length;
                          final percentage = total > 0
                              ? completed / total
                              : 0.0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: category.getColor(),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            category.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '$completed/$total',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percentage,
                                      minHeight: 6,
                                      backgroundColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        category.getColor(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (tasksManager.categories.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                'No data available',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // PORTRAIT LAYOUT - Original
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Overall Progress',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 150,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: CircularProgressIndicator(
                                  value: totalTasks > 0
                                      ? completedTasks / totalTasks
                                      : 0,
                                  strokeWidth: 12,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$completionRate%',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Completed',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Tasks',
                        value: totalTasks.toString(),
                        icon: Icons.task_alt,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Categories',
                        value: tasksManager.categories.length.toString(),
                        icon: Icons.category,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Completed',
                        value: completedTasks.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Pending',
                        value: pendingTasks.toString(),
                        icon: Icons.pending,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Tasks by Category', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                ...tasksManager.categories.map((category) {
                  final categoryTasks = tasksManager.tasks[category] ?? [];
                  final completed = categoryTasks.where((t) => t.status).length;
                  final total = categoryTasks.length;
                  final percentage = total > 0 ? completed / total : 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
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
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: category.getColor(),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$completed/$total',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              minHeight: 8,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                category.getColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (tasksManager.categories.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No data available yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.secondary.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool compact;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: compact ? 24 : 32),
            SizedBox(height: compact ? 4 : 8),
            Text(
              value,
              style:
                  (compact
                          ? theme.textTheme.headlineSmall
                          : theme.textTheme.headlineMedium)
                      ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
