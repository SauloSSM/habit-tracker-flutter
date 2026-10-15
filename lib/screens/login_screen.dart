import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/auth_notifier.dart';
import '../repositories/demo_auth_repository.dart';
import '../services/validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _attempted = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _attempted = true);
    final success = await context.read<AuthNotifier>().login(
      _email.text,
      _password.text,
    );
    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return AuthLayout(
      title: 'Bom ter você aqui.',
      subtitle: 'Entre para cuidar dos seus hábitos, no seu ritmo.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (auth.isDemo) ...[
              const Notice(
                'Modo demonstração local. Contas de teste duram apenas nesta execução. Nenhum e-mail real é enviado.',
              ),
              TextButton.icon(
                onPressed: auth.busy
                    ? null
                    : () {
                        _email.text = DemoAuthRepository.demoEmail;
                        _password.text = DemoAuthRepository.demoPassword;
                      },
                icon: const Icon(Icons.science_outlined),
                label: const Text('Preencher conta de exemplo'),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              label: 'Senha',
              validator: Validators.requiredPassword,
              onSubmitted: (_) {
                if (!auth.busy) _submit();
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: auth.busy
                    ? null
                    : () => Navigator.pushNamed(context, '/recovery'),
                child: const Text('Esqueci minha senha'),
              ),
            ),
            if (_attempted && auth.error != null) ...[
              Notice(auth.error!, error: true),
              const SizedBox(height: 16),
            ],
            BusyButton(label: 'Entrar', busy: auth.busy, onPressed: _submit),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: auth.busy
                  ? null
                  : () => Navigator.pushNamed(context, '/register'),
              child: const Text('Criar minha conta'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/about'),
              child: const Text('Conheça o HabitTracker'),
            ),
          ],
        ),
      ),
    );
  }
}
