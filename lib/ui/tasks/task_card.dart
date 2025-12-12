import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool isDragMode;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isCompact; 

  const TaskCard({
    super.key,
    required this.task,
    this.isDragMode = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.status;

    if (isDragMode) {
      return _buildCard(context, theme, isCompleted);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Dismissible(
        key: ValueKey('dismissible_${task.id}'),
        direction: DismissDirection.horizontal,
        movementDuration: const Duration(milliseconds: 200),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            if (onDelete != null) {
              final shouldDelete = await _showDeleteConfirmation(context);
              if (shouldDelete == true) {
                onDelete!();
              }
              return false;
            }
          } else if (direction == DismissDirection.endToStart) {
            if (onEdit != null && !isCompleted) {
              onEdit!();
            }
            return false;
          }
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 28),
          color: Colors.red.shade400,
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 28),
          color: isCompleted ? Colors.grey : Colors.blue.shade400,
          child: Icon(
            isCompleted ? Icons.block : Icons.edit_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        child: _buildCard(context, theme, isCompleted, inDismissible: true),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ThemeData theme,
    bool isCompleted, {
    bool inDismissible = false,
  }) {
    return Container(
      width: double.infinity,
      height: isCompact ? 70 : null,
      constraints: isCompact ? null : const BoxConstraints(minHeight: 70),
      decoration: BoxDecoration(
        color: isCompleted
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: inDismissible ? null : BorderRadius.circular(24),
        boxShadow: inDismissible
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(isCompleted ? 0.05 : 0.1),
                  blurRadius: isCompleted ? 4 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: inDismissible ? null : BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 16.0 : 16.0,
              vertical: isCompact ? 12.0 : 16.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        task.title,
                        style:
                            (isCompact
                                    ? theme.textTheme.bodyMedium
                                    : theme.textTheme.bodyLarge)
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: isCompleted
                                      ? theme.colorScheme.onSurface.withOpacity(
                                          0.5,
                                        )
                                      : theme.colorScheme.onSurface,
                                ),
                        maxLines: isCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.reminder != null) ...[
                        SizedBox(height: isCompact ? 2 : 4),
                        Row(
                          children: [
                            Icon(
                              Icons.alarm,
                              size: isCompact ? 11 : 14,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                isCompact ? 'MMM d, HH:mm' : 'MMM d, y HH:mm',
                              ).format(task.reminder!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: isCompact ? 9 : 11,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning, size: 64),
        title: const Text('Delete Task?'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
