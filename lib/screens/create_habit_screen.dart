import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/habits_notifier.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/habit_editor.dart';

class CreateHabitScreen extends StatelessWidget {
  const CreateHabitScreen({super.key});
  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Criar hábito',
    selected: 1,
    formPage: true,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeading(
            'Plante um novo hábito',
            'Comece com algo que caiba no seu dia.',
          ),
          HabitEditor(onSave: context.read<HabitsNotifier>().create),
        ],
      ),
    ),
  );
}
