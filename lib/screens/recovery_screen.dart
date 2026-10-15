import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/auth_notifier.dart';
import '../services/validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/common.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _attempted = false;
  String? _message;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _attempted = true;
      _message = null;
    });
    final auth = context.read<AuthNotifier>();
    final success = await auth.recover(_email.text);
    if (success && mounted) setState(() => _message = auth.recoveryMessage);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return AuthLayout(
      title: 'Vamos recomeçar.',
      subtitle: 'Informe o e-mail da sua conta para solicitar a recuperação.',
      back: true,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (auth.isDemo) ...[
              const Notice(
                'Modo demonstração: esta solicitação será apenas simulada. Nenhum e-mail será enviado.',
              ),
              const SizedBox(height: 20),
            ],
            TextFormField(
              controller: _email,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 24),
            BusyButton(
              label: auth.isDemo
                  ? 'Simular solicitação'
                  : 'Solicitar recuperação',
              busy: auth.busy,
              onPressed: _submit,
              icon: Icons.mail_outline_rounded,
            ),
            if (_attempted && auth.error != null) ...[
              const SizedBox(height: 20),
              Notice(auth.error!, error: true),
            ],
            if (_message != null) ...[
              const SizedBox(height: 20),
              Notice(_message!),
            ],
          ],
        ),
      ),
    );
  }
}
