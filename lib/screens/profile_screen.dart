import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/auth_notifier.dart';
import '../services/validators.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _attempted = false;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: context.read<AuthNotifier>().user?.name,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _attempted = true);
    final success = await context.read<AuthNotifier>().updateName(_name.text);
    if (success && mounted) {
      showFeedback(context, 'Nome atualizado com sucesso.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return AppShell(
      title: 'Meu perfil',
      selected: 4,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(
            'Um espaço seu',
            'Mantenha seu nome do jeito que você gosta.',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.lime,
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.green,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    auth.user?.name ?? '',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'E-mail da conta',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  SelectableText(auth.user?.email ?? ''),
                  const SizedBox(height: 28),
                  Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _name,
                          validator: Validators.name,
                          maxLength: 80,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Nome'),
                        ),
                        const SizedBox(height: 20),
                        if (_attempted && auth.error != null) ...[
                          Notice(auth.error!, error: true),
                          const SizedBox(height: 16),
                        ],
                        BusyButton(
                          label: 'Salvar nome',
                          icon: Icons.check_rounded,
                          busy: auth.busy,
                          onPressed: _save,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Notice(
            'Demonstração acadêmica: o nome e as contas criadas ficam na memória desta execução. Seus hábitos são salvos neste dispositivo.',
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: auth.busy
                ? null
                : () async {
                    final success = await auth.logout();
                    if (success && context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (_) => false,
                      );
                    }
                  },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sair da conta'),
          ),
        ],
      ),
    );
  }
}
