import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/habit.dart';
import '../../services/notifications.dart';

class HabitUpsertSheet extends StatefulWidget {
  final Habit? habit;
  final Function(Habit) onSave;

  const HabitUpsertSheet({super.key, this.habit, required this.onSave});

  @override
  State<HabitUpsertSheet> createState() => _HabitUpsertSheetState();
}

class _HabitUpsertSheetState extends State<HabitUpsertSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late Set<int> _selectedDays;
  late DateTime _selectedTime;
  late bool _reminderEnabled;
  late String _frequency;
  late int _frequencyDays;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.habit?.description ?? '',
    );
    _selectedDays = widget.habit?.days ?? {1, 2, 3, 4, 5, 6, 7};
    _selectedTime = widget.habit?.time ?? DateTime.now();
    _reminderEnabled = widget.habit?.reminder ?? true;
    _frequency = widget.habit?.frequency ?? 'weekly';
    _frequencyDays = widget.habit?.frequencyDays ?? 7;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );

    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _selectedTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) {
          _selectedDays.remove(day);
        }
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _handleReminderToggle(bool value) async {
    if (value) {
      // User wants to enable reminder - check permissions
      final notificationService = context.read<NotificationService>();

      // Check if already has permissions
      final hasPermissions = await notificationService
          .hasNotificationPermissions();

      if (!hasPermissions) {
        // Show dialog explaining why we need permission
        if (!mounted) return;

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

        // Request permissions
        final granted = await notificationService
            .requestNotificationPermissions();

        if (!granted && mounted) {
          // Show error if permission denied
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

      // Permissions granted - enable reminder
      setState(() {
        _reminderEnabled = true;
      });
    } else {
      // Disable reminder
      setState(() {
        _reminderEnabled = false;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final habit = Habit(
        id: widget.habit?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        index: widget.habit?.index ?? 0,
        days: _selectedDays,
        time: _selectedTime,
        reminder: _reminderEnabled,
        frequency: _frequency,
        frequencyDays: _frequencyDays,
        createdDate: widget.habit?.createdDate,
      );
      widget.onSave(habit);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.habit != null;
    final maxFrequencyDays = _frequency == 'weekly' ? 7 : 30;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Edit Habit' : 'Add Habit',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.length > 20) {
                      return 'Title must be 20 characters or less';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  validator: (value) {
                    if (value != null && value.length > 50) {
                      return 'Description must be 50 characters or less';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Add Reminder'),
                  value: _reminderEnabled,
                  onChanged: _handleReminderToggle,
                ),
                if (_reminderEnabled) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.alarm),
                    title: Text(DateFormat('HH:mm').format(_selectedTime)),
                    trailing: FilledButton.tonal(
                      onPressed: _selectTime,
                      child: const Text('Change'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Active Days',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      final isSelected = _selectedDays.contains(day);
                      return FilterChip(
                        label: Text(Habit.getDayName(day)),
                        selected: isSelected,
                        onSelected: (_) => _toggleDay(day),
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Habit Frequency Target',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const <ButtonSegment<String>>[
                          ButtonSegment<String>(
                            value: 'weekly',
                            label: Text('Weekly'),
                            icon: Icon(Icons.calendar_view_week),
                          ),
                          ButtonSegment<String>(
                            value: 'monthly',
                            label: Text('Monthly'),
                            icon: Icon(Icons.calendar_month),
                          ),
                        ],
                        selected: <String>{_frequency},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _frequency = newSelection.first;
                            _frequencyDays = _frequency == 'weekly' ? 7 : 30;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Target: $_frequencyDays days per ${_frequency == 'weekly' ? 'week' : 'month'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Slider(
                  value: _frequencyDays.toDouble(),
                  min: 1,
                  max: maxFrequencyDays.toDouble(),
                  divisions: maxFrequencyDays - 1,
                  label: '$_frequencyDays',
                  onChanged: (double value) {
                    setState(() {
                      _frequencyDays = value.toInt();
                    });
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(isEditing ? 'Update' : 'Add Habit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
