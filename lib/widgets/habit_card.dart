import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../services/local_dates.dart';
import '../theme/app_theme.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({super.key, required this.habit});
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final done = habit.isDone(DateTime.now());
    final days = habit.weekdays.toList()..sort();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: done ? AppColors.lime : AppColors.cream,
              child: Icon(
                done ? Icons.check_rounded : Icons.spa_outlined,
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (habit.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      habit.description,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    days.length == 7
                        ? 'Todos os dias'
                        : days.map((day) => weekdayLabels[day - 1]).join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/checkin',
                          arguments: habit.id,
                        ),
                        icon: Icon(
                          done
                              ? Icons.check_circle_rounded
                              : Icons.add_task_rounded,
                          size: 18,
                        ),
                        label: Text(
                          done ? 'Realizado hoje' : 'Registrar realização',
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/history',
                          arguments: habit.id,
                        ),
                        child: const Text('Histórico'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar ${habit.title}',
              onPressed: () => Navigator.pushNamed(
                context,
                '/habits/edit',
                arguments: habit.id,
              ),
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
