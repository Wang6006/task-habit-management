import 'package:flutter/material.dart';

class HabitStreakCard extends StatefulWidget {
  final int currentStreak;
  final int bestStreak;
  final String frequencyType;

  const HabitStreakCard({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
    this.frequencyType = 'weekly',
  });

  @override
  State<HabitStreakCard> createState() => _HabitStreakCardState();
}

class _HabitStreakCardState extends State<HabitStreakCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void didUpdateWidget(HabitStreakCard oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.bestStreak > 0
        ? (widget.currentStreak / widget.bestStreak).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      child: Stack(
        children: [
          // Progress background
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              tween: Tween(begin: 0.0, end: progress),
              builder: (context, value, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [value, value],
                      colors: [
                        Theme.of(context).colorScheme.tertiaryContainer,
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Fire icon
                RotationTransition(
                  turns: _rotationAnimation,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_fire_department,
                      color: Theme.of(context).colorScheme.onTertiary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Current Streak',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onTertiaryContainer,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.tertiary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.frequencyType == 'weekly'
                                  ? 'Weekly'
                                  : 'Monthly',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onTertiaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${widget.currentStreak} ${widget.currentStreak == 1 ? 'day' : 'days'}',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onTertiaryContainer,
                            ),
                      ),
                      Text(
                        'Best: ${widget.bestStreak} ${widget.bestStreak == 1 ? 'day' : 'days'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onTertiaryContainer.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
