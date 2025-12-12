import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './habits_manager.dart';
import './habit_card.dart';
import './habit_upsert_sheet.dart';
import 'habit_analytics_screen.dart';
import 'overall_analytics_screen.dart';
import '../../../models/habit.dart';

class HabitsListScreen extends StatefulWidget {
  static const routeName = '/habits';

  const HabitsListScreen({super.key});

  @override
  State<HabitsListScreen> createState() => _HabitsListScreenState();
}

class _HabitsListScreenState extends State<HabitsListScreen> {
  bool _isReorderMode = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitsManager>().loadHabits();
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        if (_searchQuery.isNotEmpty && _isReorderMode) {
          _isReorderMode = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddHabitSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => HabitUpsertSheet(
        onSave: (habit) {
          context.read<HabitsManager>().addHabit(habit);
        },
      ),
    );
  }

  void _navigateToAnalytics(Habit habit) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => HabitAnalyticsScreen(habit: habit),
      ),
    );
  }

  void _navigateToOverallAnalytics() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (context) => const OverallAnalyticsScreen()),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search habits...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<HabitsManager>(
          builder: (context, manager, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Habits'),
                Text(
                  '${manager.completedCount}/${manager.totalHabits} completed',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
        actions: [
          Consumer<HabitsManager>(
            builder: (context, manager, child) {
              if (manager.totalHabits == 0) return const SizedBox.shrink();
              return Row(
                children: [
                  IconButton(
                    icon: Icon(
                      manager.compactView
                          ? Icons.view_agenda
                          : Icons.view_compact,
                    ),
                    onPressed: () {
                      manager.setCompactView(!manager.compactView);
                    },
                  ),
                  IconButton(
                    icon: Icon(_isReorderMode ? Icons.done : Icons.reorder),
                    onPressed: _searchQuery.isEmpty
                        ? () {
                            setState(() {
                              _isReorderMode = !_isReorderMode;
                            });
                          }
                        : null,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<HabitsManager>(
        builder: (context, manager, child) {
          if (manager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (manager.totalHabits == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.self_improvement,
                    size: 100,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No habits yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first habit',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          final allHabits = manager.habits;
          final filteredHabits = _searchQuery.isEmpty
              ? allHabits
              : allHabits
                    .where(
                      (habit) => habit.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

          return OrientationBuilder(
            builder: (context, orientation) {
              return Column(
                children: [
                  _buildSearchBar(),

                  if (filteredHabits.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No results found',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              'Try a different search term',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: _isReorderMode
                          ? _buildReorderableList(
                              context,
                              manager,
                              allHabits,
                              filteredHabits,
                              orientation,
                            )
                          : _buildNormalList(
                              context,
                              manager,
                              filteredHabits,
                              orientation,
                            ),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<HabitsManager>(
        builder: (context, manager, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (manager.totalHabits > 0)
                FloatingActionButton.small(
                  heroTag: 'overall_analytics',
                  onPressed: _navigateToOverallAnalytics,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  child: const Icon(Icons.analytics),
                ),
              if (manager.totalHabits > 0) const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'add_habit',
                onPressed: _showAddHabitSheet,
                child: const Icon(Icons.add),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNormalList(
    BuildContext context,
    HabitsManager manager,
    List<Habit> filteredHabits,
    Orientation orientation,
  ) {
    // Landscape: 2 columns grid, Portrait: 1 column list
    if (orientation == Orientation.landscape) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3.5, // Adjust for card height
        ),
        itemCount: filteredHabits.length,
        itemBuilder: (context, index) {
          final habit = filteredHabits[index];
          final statuses = manager.habitsWithStatuses[habit] ?? [];
          final isCompleted = manager.completedHabitsToday.contains(habit);

          return HabitCard(
            habit: habit,
            statuses: statuses,
            isCompleted: isCompleted,
            compactView: true, // Always compact in grid
            onTap: () => manager.toggleHabitStatus(habit),
            onAnalytics: () => _navigateToAnalytics(habit),
          );
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredHabits.length,
        itemBuilder: (context, index) {
          final habit = filteredHabits[index];
          final statuses = manager.habitsWithStatuses[habit] ?? [];
          final isCompleted = manager.completedHabitsToday.contains(habit);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HabitCard(
              habit: habit,
              statuses: statuses,
              isCompleted: isCompleted,
              compactView: manager.compactView,
              onTap: () => manager.toggleHabitStatus(habit),
              onAnalytics: () => _navigateToAnalytics(habit),
            ),
          );
        },
      );
    }
  }

  Widget _buildReorderableList(
    BuildContext context,
    HabitsManager manager,
    List<Habit> allHabits,
    List<Habit> filteredHabits,
    Orientation orientation,
  ) {
    // Reorder mode only works in portrait for now
    if (orientation == Orientation.landscape) {
      return _buildNormalList(context, manager, filteredHabits, orientation);
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredHabits.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        manager.reorderHabits(allHabits, oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final double scale = Tween<double>(begin: 1.0, end: 1.03).evaluate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            );

            return Transform.scale(
              scale: scale,
              child: Opacity(opacity: 0.95, child: child),
            );
          },
        );
      },
      itemBuilder: (context, index) {
        final habit = filteredHabits[index];
        final statuses = manager.habitsWithStatuses[habit] ?? [];
        final isCompleted = manager.completedHabitsToday.contains(habit);

        return Container(
          key: ValueKey(habit.id),
          margin: const EdgeInsets.only(bottom: 12),
          child: HabitCard(
            habit: habit,
            statuses: statuses,
            isCompleted: isCompleted,
            compactView: manager.compactView,
            onTap: () => manager.toggleHabitStatus(habit),
            onAnalytics: () => _navigateToAnalytics(habit),
            reorderHandle: ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.drag_indicator,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
