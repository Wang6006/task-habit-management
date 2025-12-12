import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HabitStartCard extends StatelessWidget {
  final DateTime startDate;

  const HabitStartCard({super.key, required this.startDate});

  String _formatDate(DateTime date) {
    final day = date.day;
    String suffix = 'th';
    if (day == 1 || day == 21 || day == 31) {
      suffix = 'st';
    } else if (day == 2 || day == 22) {
      suffix = 'nd';
    } else if (day == 3 || day == 23) {
      suffix = 'rd';
    }

    return '$day$suffix ${DateFormat('MMMM yyyy').format(date)}';
  }

  int _daysSinceStart() {
    final now = DateTime.now();
    return now.difference(startDate).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flag,
                color: Theme.of(context).colorScheme.onSecondary,
                size: 36,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Started on',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    _formatDate(startDate),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    '${_daysSinceStart()} days ago',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSecondaryContainer.withOpacity(0.7),
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
}
