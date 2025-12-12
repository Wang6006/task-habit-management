import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task.dart';
import '../../../models/category.dart';
import 'tasks_manager.dart';
import 'task_card.dart';
import 'task_upsert_sheet.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../tasks/add_category_dialog.dart';

class TaskScreen extends StatefulWidget {
  static const routeName = '/tasks';

  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  bool _isEditMode = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksManager>().loadTasks();
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddTaskSheet() {
    final tasksManager = context.read<TasksManager>();
    if (tasksManager.currentCategory == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => TaskUpsertSheet(
        task: Task(
          categoryId: tasksManager.currentCategory!.id!,
          title: '',
          index: tasksManager.currentCategoryTasks.length,
        ),
        categories: tasksManager.categories,
      ),
    ).then((result) {
      if (result != null && result is Task) {
        tasksManager.addTask(result);
      }
    });
  }

  void _showEditTaskSheet(Task task) {
    final tasksManager = context.read<TasksManager>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => TaskUpsertSheet(
        task: task,
        categories: tasksManager.categories,
        isEdit: true,
      ),
    ).then((result) {
      if (result != null && result is Task) {
        tasksManager.updateTask(result);
      }
    });
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddCategoryDialog(
        onAdd: (name, color) {
          context.read<TasksManager>().addCategory(
            Category(name: name, color: color),
          );
        },
      ),
    );
  }

  void _showDeleteCompletedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning, size: 64),
        title: const Text('Delete Completed Tasks?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<TasksManager>().deleteCompletedTasks();
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
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

  bool get _isLandscape {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tasks'),
            Consumer<TasksManager>(
              builder: (ctx, manager, _) => Text(
                '${manager.completedTasks.length} items completed',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<TasksManager>(
            builder: (ctx, manager, _) {
              if (manager.completedTasks.isEmpty) return const SizedBox();

              return IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _showDeleteCompletedDialog,
              );
            },
          ),
          Consumer<TasksManager>(
            builder: (ctx, manager, _) {
              if (manager.currentCategoryTasks.isEmpty ||
                  _searchQuery.isNotEmpty) {
                return const SizedBox();
              }

              return IconButton(
                icon: Icon(_isEditMode ? Icons.check : Icons.reorder),
                onPressed: () {
                  setState(() {
                    _isEditMode = !_isEditMode;
                  });
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<TasksManager>(
        builder: (ctx, tasksManager, _) {
          if (tasksManager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (tasksManager.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: theme.colorScheme.secondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text('No categories yet', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _showAddCategoryDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
                ],
              ),
            );
          }

          final allTasks = tasksManager.currentCategoryTasks;
          final filteredTasks = _searchQuery.isEmpty
              ? allTasks
              : allTasks
                    .where(
                      (task) => task.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

          // LANDSCAPE LAYOUT - 2 columns
          if (_isLandscape) {
            return Column(
              children: [
                // Compact header with categories and search
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: theme.colorScheme.surface,
                  child: Row(
                    children: [
                      // Categories in a row
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: tasksManager.categories.map((category) {
                              final isSelected =
                                  category.id ==
                                  tasksManager.currentCategory?.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  selected: isSelected,
                                  label: Text(category.name),
                                  backgroundColor: category
                                      .getColor()
                                      .withOpacity(0.2),
                                  selectedColor: category.getColor(),
                                  visualDensity: VisualDensity.compact,
                                  onSelected: !_isEditMode
                                      ? (selected) {
                                          tasksManager.setCurrentCategory(
                                            category,
                                          );
                                        }
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      // Action buttons
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: !_isEditMode ? _showAddCategoryDialog : null,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: !_isEditMode
                            ? () => context.push('/edit-categories')
                            : null,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      // Compact search
                      if (tasksManager.currentCategoryTasks.isNotEmpty)
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 40,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                        },
                                        visualDensity: VisualDensity.compact,
                                      )
                                    : null,
                                filled: true,
                                fillColor: theme
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 0,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: tasksManager.currentCategoryTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_outlined,
                                size: 64,
                                color: theme.colorScheme.secondary.withOpacity(
                                  0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks yet',
                                style: theme.textTheme.titleLarge,
                              ),
                            ],
                          ),
                        )
                      : filteredTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks found',
                                style: theme.textTheme.titleLarge,
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent:
                                    70, 
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: filteredTasks.length,
                          itemBuilder: (ctx, index) {
                            final task = filteredTasks[index];
                            return TaskCard(
                              task: task,
                              isDragMode: false,
                              isCompact:
                                  true, 
                              onTap: !_isEditMode
                                  ? () => tasksManager.toggleTaskStatus(task)
                                  : null,
                              onEdit: !_isEditMode && !task.status
                                  ? () => _showEditTaskSheet(task)
                                  : null,
                              onDelete: !_isEditMode
                                  ? () => tasksManager.deleteTask(task)
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            );
          }

          // PORTRAIT LAYOUT 
          return Column(
            children: [
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        children: tasksManager.categories.map((category) {
                          final isSelected =
                              category.id == tasksManager.currentCategory?.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              selected: isSelected,
                              label: Text(category.name),
                              backgroundColor: category.getColor().withOpacity(
                                0.2,
                              ),
                              selectedColor: category.getColor(),
                              onSelected: !_isEditMode
                                  ? (selected) {
                                      tasksManager.setCurrentCategory(category);
                                    }
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            theme.colorScheme.surface.withOpacity(0.0),
                            theme.colorScheme.surface,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: !_isEditMode
                                ? _showAddCategoryDialog
                                : null,
                            tooltip: 'Add Category',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: !_isEditMode
                                ? () {
                                    context.push('/edit-categories');
                                  }
                                : null,
                            tooltip: 'Edit Categories',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (tasksManager.currentCategoryTasks.isNotEmpty)
                _buildSearchBar(),

              // Tasks list
              Expanded(
                child: tasksManager.currentCategoryTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_outlined,
                              size: 64,
                              color: theme.colorScheme.secondary.withOpacity(
                                0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks yet',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add a new task',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks found',
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filteredTasks.length,
                        buildDefaultDragHandles: false,
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              final scale = lerpDouble(
                                1,
                                1.02,
                                Curves.easeInOut.transform(animation.value),
                              );
                              return Transform.scale(
                                scale: scale,
                                child: Material(
                                  elevation: 8,
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                  child: child,
                                ),
                              );
                            },
                            child: child,
                          );
                        },
                        onReorder: (int oldIndex, int newIndex) {
                          if (_isEditMode && _searchQuery.isEmpty) {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final tasks = List<Task>.from(
                              tasksManager.currentCategoryTasks,
                            );
                            final task = tasks.removeAt(oldIndex);
                            tasks.insert(newIndex, task);
                            tasksManager.reorderTasks(tasks);
                          }
                        },
                        itemBuilder: (ctx, index) {
                          final task = filteredTasks[index];
                          return Container(
                            key: ValueKey(task.id),
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TaskCard(
                                    task: task,
                                    isDragMode: _isEditMode,
                                    onTap: !_isEditMode
                                        ? () => tasksManager.toggleTaskStatus(
                                            task,
                                          )
                                        : null,
                                    onEdit: !_isEditMode && !task.status
                                        ? () => _showEditTaskSheet(task)
                                        : null,
                                    onDelete: !_isEditMode
                                        ? () => tasksManager.deleteTask(task)
                                        : null,
                                  ),
                                ),
                                if (_isEditMode)
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 12.0),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.drag_indicator,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _isLandscape
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (context.watch<TasksManager>().totalTasks > 0)
                  FloatingActionButton.small(
                    heroTag: 'task-statistics',
                    onPressed: () => context.push('/task-statistics'),
                    child: const Icon(Icons.analytics),
                  ),
                if (context.watch<TasksManager>().totalTasks > 0)
                  const SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: 'add_task',
                  onPressed: _showAddTaskSheet,
                  child: const Icon(Icons.add),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (context.watch<TasksManager>().totalTasks > 0)
                  FloatingActionButton.small(
                    heroTag: 'task-statistics',
                    onPressed: () => context.push('/task-statistics'),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    child: const Icon(Icons.analytics),
                  ),
                if (context.watch<TasksManager>().totalTasks > 0)
                  const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'add_task',
                  onPressed: _showAddTaskSheet,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
    );
  }
}
