import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/auth_notifier.dart';
import '../notifiers/habits_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/habit_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final state = context.watch<HabitsNotifier>();
    final today = DateTime.now();
    final planned = state.habits.where((h) => h.isScheduled(today)).toList();
    final done = planned.where((h) => h.isDone(today)).length;
    final total = state.habits.fold(0, (sum, h) => sum + h.checkins.length);
    return AppShell(
      title: 'Visão geral',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            MaterialLocalizations.of(context).formatFullDate(today),
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          PageHeading(
            'Olá, ${auth.user?.name.split(' ').first ?? 'Estudante'} 🌿',
            'Que tal um pequeno passo por você hoje?',
          ),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SEU RITMO, SEU CAMINHO',
                  style: TextStyle(
                    color: AppColors.lime,
                    fontSize: 11,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hoje é um bom dia\npara continuar.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Você não precisa fazer tudo. Cada realização já é uma conquista.',
                  style: TextStyle(color: Color(0xFFDCE6DA), height: 1.6),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.lime,
                    foregroundColor: AppColors.green,
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/checkin'),
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Registrar meu progresso'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, box) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Stat(
                  width: box.maxWidth < 500
                      ? box.maxWidth
                      : (box.maxWidth - 24) / 3,
                  value: '${state.habits.length}',
                  label: 'hábitos cultivados',
                  icon: Icons.spa_outlined,
                ),
                _Stat(
                  width: box.maxWidth < 500
                      ? box.maxWidth
                      : (box.maxWidth - 24) / 3,
                  value: '$done/${planned.length}',
                  label: 'planejados realizados hoje',
                  icon: Icons.check_circle_outline_rounded,
                ),
                _Stat(
                  width: box.maxWidth < 500
                      ? box.maxWidth
                      : (box.maxWidth - 24) / 3,
                  value: '$total',
                  label: 'realizações no seu caminho',
                  icon: Icons.auto_awesome_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Text(
                'Para cuidar hoje',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/habits'),
                label: const Text('Ver todos os hábitos'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (planned.isEmpty)
            EmptyState(
              title: state.habits.isEmpty
                  ? 'Uma pequena semente para começar'
                  : 'Um dia com espaço para você',
              description: state.habits.isEmpty
                  ? 'Escolha seu primeiro hábito. O importante é caber na sua vida.'
                  : 'Não há hábitos planejados para hoje. Você ainda pode registrar uma realização.',
              action: FilledButton.icon(
                onPressed: state.canEdit
                    ? () => Navigator.pushNamed(
                        context,
                        state.habits.isEmpty ? '/habits/create' : '/checkin',
                      )
                    : null,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  state.habits.isEmpty
                      ? 'Criar meu primeiro hábito'
                      : 'Registrar realização',
                ),
              ),
            ),
          for (final habit in planned)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HabitCard(habit: habit),
            ),
          if (auth.isDemo && state.habits.isEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: state.canEdit
                  ? () async {
                      final success = await state.addDemoExamples(
                        isDemo: auth.isDemo,
                      );
                      if (success && context.mounted) {
                        showFeedback(
                          context,
                          'Dois hábitos de exemplo foram adicionados.',
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.science_outlined),
              label: const Text('Adicionar hábitos de exemplo'),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Um dia de pausa também faz parte do caminho.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.width,
    required this.value,
    required this.label,
    required this.icon,
  });
  final double width;
  final String value;
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.green, size: 22),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    ),
  );
}
