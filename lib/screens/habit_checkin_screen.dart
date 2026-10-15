import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/habits_notifier.dart';
import '../services/local_dates.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

class HabitCheckinScreen extends StatefulWidget {
  const HabitCheckinScreen({super.key, this.habitId});
  final String? habitId;
  @override
  State<HabitCheckinScreen> createState() => _HabitCheckinScreenState();
}

class _HabitCheckinScreenState extends State<HabitCheckinScreen> {
  DateTime _date = localDay(DateTime.now());

  Future<void> _pickDate() async {
    final habits = context.read<HabitsNotifier>().habits;
    final first = habits
        .map((h) => h.createdAt)
        .fold(localDay(DateTime.now()), (a, b) => a.isBefore(b) ? a : b);
    final date = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(first) ? first : _date,
      firstDate: first,
      lastDate: localDay(DateTime.now()),
      helpText: 'Data da realização',
    );
    if (date != null && mounted) setState(() => _date = localDay(date));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HabitsNotifier>();
    final habits = state.habits
        .where((h) => widget.habitId == null || h.id == widget.habitId)
        .toList();
    return AppShell(
      title: 'Registrar realização',
      selected: 2,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(
            'Celebre um pequeno passo',
            'Marque o que você fez. Cada realização tem valor.',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 20,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DATA DO REGISTRO',
                        style: TextStyle(fontSize: 11, letterSpacing: 1.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayDate(_date),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: habits.isEmpty ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: const Text('Escolher data'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (habits.isEmpty)
            EmptyState(
              title: 'Vamos começar?',
              description: 'Crie um hábito antes de registrar uma realização.',
              action: FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/habits/create'),
                child: const Text('Criar hábito'),
              ),
            ),
          for (final habit in habits)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  title: Text(
                    habit.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _date.isBefore(habit.createdAt)
                        ? 'Este hábito ainda não existia nesta data.'
                        : habit.isDone(_date)
                        ? 'Realização registrada. Toque para desmarcar.'
                        : habit.isScheduled(_date)
                        ? 'Planejado para este dia.'
                        : 'Fora da frequência prevista. Você também pode registrar.',
                  ),
                  value: habit.isDone(_date),
                  onChanged: !state.canEdit || _date.isBefore(habit.createdAt)
                      ? null
                      : (done) async {
                          final success = await state.setCheckin(
                            habit.id,
                            _date,
                            done ?? false,
                          );
                          if (success && context.mounted) {
                            showFeedback(
                              context,
                              done == true
                                  ? 'Realização registrada. Seu progresso conta!'
                                  : 'Registro desmarcado. As outras realizações continuam salvas.',
                            );
                          }
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Notice(
            'Você pode marcar ou desmarcar uma vez por hábito e data. Dias de pausa não apagam o seu progresso.',
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/history',
              arguments: widget.habitId,
            ),
            icon: const Icon(Icons.history_rounded),
            label: const Text('Ver minhas realizações'),
          ),
        ],
      ),
    );
  }
}
