import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/category.dart';
import 'tasks_manager.dart';
import 'dart:ui';

class EditCategoriesScreen extends StatefulWidget {
  static const routeName = '/edit-categories';

  const EditCategoriesScreen({super.key});

  @override
  State<EditCategoriesScreen> createState() => _EditCategoriesScreenState();
}

class _EditCategoriesScreenState extends State<EditCategoriesScreen> {
  bool _isEditMode = false;

  bool get _isLandscape {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  void _showEditCategoryDialog(Category category) {
    final controller = TextEditingController(text: category.name);
    String selectedColor = category.color;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          icon: const Icon(Icons.edit),
          title: const Text('Edit Category'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _isLandscape ? 400 : double.infinity,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 20,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  const Text('Choose Color:', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: CategoryColors.allColors.map((color) {
                      final isSelected = color == selectedColor;
                      final colorValue = CategoryColors.fromString(color);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorValue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () {
                      context.read<TasksManager>().updateCategory(
                        category.copyWith(
                          name: controller.text.trim(),
                          color: selectedColor,
                        ),
                      );
                      Navigator.of(ctx).pop();
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCategoryDialog(Category category) {
    final tasksManager = context.read<TasksManager>();
    final taskCount = tasksManager.tasks[category]?.length ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning, size: 64),
        title: const Text('Delete Category?'),
        content: Text(
          taskCount > 0
              ? 'This will delete $taskCount task(s) in this category.'
              : 'Are you sure you want to delete this category?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              tasksManager.deleteCategory(category);
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          Consumer<TasksManager>(
            builder: (ctx, manager, _) {
              if (manager.categories.length < 2) return const SizedBox();

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
            return const Center(child: Text('No categories yet'));
          }

          // LANDSCAPE - GridView 2 columns
          if (_isLandscape) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: tasksManager.categories.length,
              itemBuilder: (ctx, index) {
                final category = tasksManager.categories[index];
                final taskCount = tasksManager.tasks[category]?.length ?? 0;
                final canDelete = tasksManager.categories.length > 1;

                return Card(
                  child: InkWell(
                    onTap: _isEditMode
                        ? null
                        : () => _showEditCategoryDialog(category),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: category.getColor(),
                            radius: 20,
                            child: Text(
                              category.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '$taskCount task${taskCount != 1 ? 's' : ''}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (!_isEditMode) ...[
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: canDelete
                                  ? () => _showDeleteCategoryDialog(category)
                                  : null,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          // PORTRAIT - Original ReorderableListView
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: tasksManager.categories.length,
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
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
            onReorder: (int oldIndex, int newIndex) {
              if (!_isEditMode) return;

              if (newIndex > oldIndex) {
                newIndex -= 1;
              }

              final categories = List<Category>.from(tasksManager.categories);
              final category = categories.removeAt(oldIndex);
              categories.insert(newIndex, category);

              tasksManager.reorderCategories(categories);
            },
            itemBuilder: (ctx, index) {
              final category = tasksManager.categories[index];
              final taskCount = tasksManager.tasks[category]?.length ?? 0;
              final canDelete = tasksManager.categories.length > 1;

              return Container(
                key: ValueKey(category.id),
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: category.getColor(),
                      child: Text(
                        category.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '$taskCount task${taskCount != 1 ? 's' : ''}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isEditMode) ...[
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: canDelete
                                ? () => _showDeleteCategoryDialog(category)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showEditCategoryDialog(category),
                          ),
                        ],
                        if (_isEditMode)
                          ReorderableDragStartListener(
                            index: index,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.drag_indicator,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
