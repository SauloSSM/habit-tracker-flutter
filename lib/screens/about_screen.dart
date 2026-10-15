import 'package:flutter/material.dart';

import '../config/project_info.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sobre o HabitTracker')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Brand(),
            const SizedBox(height: 36),
            const PageHeading(
              'Consistência com gentileza.',
              'Pequenos passos, progresso que permanece.',
            ),
            const Text(
              'O HabitTracker ajuda você a criar hábitos, registrar realizações e reconhecer o seu progresso ao longo do tempo. Falhar um dia não elimina o que já foi construído.',
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sobre este projeto',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Parte 1 de um projeto acadêmico da disciplina Desenvolvimento Mobile. Desenvolvido com Flutter, Dart, Material 3 e gerenciamento de estado com ChangeNotifier e provider.',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Esta versão é uma demonstração independente, com autenticação simulada e persistência local de hábitos. A recuperação de senha não envia e-mails.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Integrante', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final member in teamMembers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.lime,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.green,
                  ),
                ),
                title: Text(member),
              ),
            const SizedBox(height: 16),
            const Text(
              'Integrante responsável pelo projeto acadêmico.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            const Notice(
              'Sem sequências punitivas. Sem progresso zerado por uma pausa. Um novo dia é uma nova oportunidade.',
            ),
          ],
        ),
      ),
    ),
  );
}
