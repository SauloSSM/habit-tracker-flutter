import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/habits_notifier.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/habit_card.dart';

class HabitsListScreen extends StatelessWidget {
  const HabitsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HabitsNotifier>();
    return AppShell(
      title: 'Meus hábitos',
      selected: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeading(
              'Seu jardim de hábitos',
              'Pequenas escolhas que crescem com você.',
              action: FilledButton.icon(
                onPressed: state.canEdit
                    ? () => Navigator.pushNamed(context, '/habits/create')
                    : null,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Novo hábito'),
              ),
            ),
            Expanded(
              child: state.habits.isEmpty
                  ? ListView(
                      children: const [
                        EmptyState(
                          title: 'Todo começo tem espaço',
                          description:
                              'Crie seu primeiro hábito pelo botão acima. Escolha algo pequeno e possível.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: state.habits.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: HabitCard(habit: state.habits[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
