import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/auth_notifier.dart';
import '../services/validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/common.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _attempted = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _attempted = true);
    final success = await context.read<AuthNotifier>().register(
      _name.text,
      _email.text,
      _phone.text,
      _password.text,
    );
    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      showFeedback(context, 'Conta criada. Bem-vindo ao seu novo começo!');
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _password,
      _confirmation,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return AuthLayout(
      title: 'Seu próximo começo.',
      subtitle: 'Crie uma conta para acompanhar o que faz bem.',
      back: true,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (auth.isDemo) ...[
              const Notice(
                'Cadastro demonstrativo: sua conta ficará na memória até fechar ou recarregar o app.',
              ),
              const SizedBox(height: 20),
            ],
            TextFormField(
              controller: _name,
              validator: Validators.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              validator: Validators.phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Telefone com DDD',
                hintText: '(11) 99999-9999',
              ),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              label: 'Senha (mínimo de 8 caracteres)',
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirmation,
              label: 'Confirmar senha',
              validator: (value) => (value ?? '').isEmpty
                  ? 'Confirme sua senha.'
                  : value != _password.text
                  ? 'As senhas precisam ser iguais.'
                  : null,
            ),
            const SizedBox(height: 24),
            if (_attempted && auth.error != null) ...[
              Notice(auth.error!, error: true),
              const SizedBox(height: 16),
            ],
            BusyButton(
              label: 'Criar conta',
              busy: auth.busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
