import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/habits_notifier.dart';
import '../services/local_dates.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

class HabitHistoryScreen extends StatefulWidget {
  const HabitHistoryScreen({super.key, this.habitId});
  final String? habitId;
  @override
  State<HabitHistoryScreen> createState() => _HabitHistoryScreenState();
}

class _HabitHistoryScreenState extends State<HabitHistoryScreen> {
  late String? _filter = widget.habitId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HabitsNotifier>();
    final selected = state.find(_filter) == null ? null : _filter;
    final habits = state.habits.where(
      (h) => selected == null || h.id == selected,
    );
    final entries = [
      for (final h in habits)
        for (final day in h.checkins) (title: h.title, date: day),
    ]..sort((a, b) => b.date.compareTo(a.date));
    final days = entries.map((e) => e.date).toSet();
    final today = localDay(DateTime.now());
    return AppShell(
      title: 'Histórico',
      selected: 3,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(
            'Tudo o que você já cultivou',
            'Seu progresso é a soma dos seus passos, incluindo os recomeços.',
          ),
          DropdownButtonFormField<String>(
            key: ValueKey(selected),
            initialValue: selected ?? '',
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Visualizar hábito'),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Todos os hábitos'),
              ),
              for (final h in state.habits)
                DropdownMenuItem(
                  value: h.id,
                  child: Text(h.title, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) =>
                setState(() => _filter = value == '' ? null : value),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Summary(
                value: '${entries.length}',
                label: 'realizações acumuladas',
              ),
              _Summary(value: '${days.length}', label: 'dias com realizações'),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Seus últimos 7 dias',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  for (var offset = 6; offset >= 0; offset--)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final date = DateTime(
                            today.year,
                            today.month,
                            today.day - offset,
                          );
                          final count = entries
                              .where((e) => e.date == dayKey(date))
                              .length;
                          return Tooltip(
                            message: '${displayDate(date)}: $count realizações',
                            child: Column(
                              children: [
                                Text(
                                  weekdayLabels[date.weekday - 1],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: count > 0
                                      ? AppColors.lime
                                      : AppColors.cream,
                                  child: Icon(
                                    count > 0
                                        ? Icons.check_rounded
                                        : Icons.remove_rounded,
                                    size: 18,
                                    color: AppColors.green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${date.day}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '✓ Dia com realização   ·   — Dia sem registro',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          const Notice(
            'Consistência é voltar ao que importa. Um dia sem registro não reduz o total que você já conquistou.',
          ),
          const SizedBox(height: 28),
          Text(
            'Registros anteriores',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            const EmptyState(
              title: 'Seu histórico começa com um passo',
              description:
                  'Quando você registrar uma realização, ela aparecerá aqui.',
              icon: Icons.history_rounded,
            ),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.green,
                  ),
                  title: Text(entry.title),
                  subtitle: Text(displayDate(DateTime.parse(entry.date))),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineLarge),
          Text(label),
        ],
      ),
    ),
  );
}
