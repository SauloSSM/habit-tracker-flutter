import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/habits_notifier.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/habit_editor.dart';

class EditHabitScreen extends StatelessWidget {
  const EditHabitScreen({super.key, required this.habitId});
  final String? habitId;

  Future<void> _delete(BuildContext context) async {
    final state = context.read<HabitsNotifier>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir este hábito?'),
        content: const Text(
          'O hábito e todos os seus registros serão excluídos da sua conta. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await state.delete(habitId!);
    if (success && context.mounted) {
      Navigator.pop(context);
      showFeedback(context, 'Hábito excluído.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HabitsNotifier>();
    final habit = state.find(habitId);
    return AppShell(
      title: 'Editar hábito',
      selected: 1,
      formPage: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: habit == null
            ? const EmptyState(
                title: 'Hábito não encontrado',
                description: 'Volte à lista para escolher um hábito existente.',
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PageHeading(
                    'Ajuste o seu ritmo',
                    'Seus hábitos podem mudar junto com você.',
                  ),
                  HabitEditor(
                    key: ValueKey(habit.id),
                    habit: habit,
                    onSave: (title, description, weekdays) =>
                        state.edit(habit.id, title, description, weekdays),
                    footer: OutlinedButton.icon(
                      onPressed: state.canEdit ? () => _delete(context) : null,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Excluir hábito'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
