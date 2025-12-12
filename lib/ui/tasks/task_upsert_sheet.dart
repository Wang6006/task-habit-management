import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/task.dart';
import '../../../models/category.dart';

import '../../services/notifications.dart';
import 'package:provider/provider.dart';

class TaskUpsertSheet extends StatefulWidget {
  final Task task;
  final List<Category> categories;
  final bool isEdit;

  const TaskUpsertSheet({
    super.key,
    required this.task,
    required this.categories,
    this.isEdit = false,
  });

  @override
  State<TaskUpsertSheet> createState() => _TaskUpsertSheetState();
}

class _TaskUpsertSheetState extends State<TaskUpsertSheet> {
  late Task _editedTask;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editedTask = widget.task;
    _titleController.text = widget.task.title;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _titleController.text.trim().isNotEmpty &&
        _titleController.text.length <= 100;
  }

  bool get _isLandscape {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  Future<void> _selectDateTime() async {
    final notificationService = context.read<NotificationService>();
    final hasPermissions = await notificationService
        .hasNotificationPermissions();

    if (!hasPermissions && mounted) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.notifications_active, size: 48),
          title: const Text('Enable Notifications'),
          content: const Text(
            'To send you reminders, this app needs permission to:\n\n'
            '• Show notifications\n'
            '• Schedule exact alarms\n\n'
            'You will be taken to settings to grant these permissions.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (shouldRequest != true || !mounted) {
        return;
      }

      final granted = await notificationService
          .requestNotificationPermissions();

      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permissions are required for reminders',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    final now = DateTime.now();
    final initialDate =
        _editedTask.reminder != null && _editedTask.reminder!.isAfter(now)
        ? _editedTask.reminder!
        : now;

    if (!mounted) return;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date == null || !mounted) return;

    final initialTime = _editedTask.reminder != null
        ? TimeOfDay.fromDateTime(_editedTask.reminder!)
        : TimeOfDay.now();

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time == null || !mounted) return;

    final newReminder = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (newReminder.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a future date and time'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _editedTask = Task(
        id: _editedTask.id,
        categoryId: _editedTask.categoryId,
        title: _editedTask.title,
        index: _editedTask.index,
        status: _editedTask.status,
        reminder: newReminder,
      );
    });
  }

  void _clearReminder() {
    setState(() {
      if (widget.isEdit && _editedTask.id != null) {
        context.read<NotificationService>().cancelNotification(_editedTask.id!);
      }
      _editedTask = Task(
        id: _editedTask.id,
        categoryId: _editedTask.categoryId,
        title: _editedTask.title,
        index: _editedTask.index,
        status: _editedTask.status,
        reminder: null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape = _isLandscape;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: isLandscape
          ? _buildLandscapeLayout(theme)
          : _buildPortraitLayout(theme),
    );
  }

  // PORTRAIT LAYOUT - 2 COLUMNS (Left: Category, Right: Form)
  Widget _buildPortraitLayout(ThemeData theme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    widget.isEdit ? Icons.edit : Icons.add,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isEdit ? 'Edit Task' : 'Add Task',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // CATEGORY - Horizontal chips
              Text('Category', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.categories.length,
                  itemBuilder: (context, index) {
                    final category = widget.categories[index];
                    final isSelected = category.id == _editedTask.categoryId;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(
                          category.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _editedTask = _editedTask.copyWith(
                              categoryId: category.id,
                            );
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // TITLE INPUT
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) => setState(() {}),
              ),

              const SizedBox(height: 12),

              // REMINDER SECTION
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Add Reminder'),
                value: _editedTask.reminder != null,
                onChanged: (value) {
                  if (value) {
                    _selectDateTime();
                  } else {
                    _clearReminder();
                  }
                },
              ),

              // Reminder Display
              if (_editedTask.reminder != null) ...[
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.alarm, size: 20),
                  title: Text(
                    DateFormat(
                      'MMM d, y • HH:mm',
                    ).format(_editedTask.reminder!),
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: _selectDateTime,
                    child: const Text('Change'),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // SUBMIT BUTTON
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isValid
                          ? () {
                              Navigator.of(context).pop(
                                _editedTask.copyWith(
                                  title: _titleController.text.trim(),
                                ),
                              );
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(
                          widget.isEdit ? 'Save' : 'Add',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(ThemeData theme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.isEdit ? Icons.edit : Icons.add,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.isEdit ? 'Edit Task' : 'Add Task',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (value) => setState(() {}),
                    ),

                    const SizedBox(height: 12),

                    // BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: _isValid
                                ? () {
                                    Navigator.of(context).pop(
                                      _editedTask.copyWith(
                                        title: _titleController.text.trim(),
                                      ),
                                    );
                                  }
                                : null,
                            child: Text(widget.isEdit ? 'Save' : 'Add'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // RIGHT - Category & Reminder
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // CATEGORY
                    Text('Category', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: widget.categories.map((category) {
                        final isSelected =
                            category.id == _editedTask.categoryId;

                        return FilterChip(
                          selected: isSelected,
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            category.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _editedTask = _editedTask.copyWith(
                                categoryId: category.id,
                              );
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    // REMINDER
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      title: const Text('Reminder'),
                      value: _editedTask.reminder != null,
                      onChanged: (value) {
                        if (value) {
                          _selectDateTime();
                        } else {
                          _clearReminder();
                        }
                      },
                    ),

                    // Reminder Display
                    if (_editedTask.reminder != null) ...[
                      const SizedBox(height: 6),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat(
                                  'MMM d, HH:mm',
                                ).format(_editedTask.reminder!),
                                style: theme.textTheme.labelSmall,
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _selectDateTime,
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Change'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
