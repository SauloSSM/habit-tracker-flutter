import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.back = false,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final bool back;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            if (constraints.maxWidth >= 1000 && constraints.maxHeight >= 760)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CULTIVE O QUE FAZ BEM',
                        style: TextStyle(
                          color: AppColors.lime,
                          fontSize: 12,
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.spa_outlined,
                        size: 96,
                        color: AppColors.lime,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Pequenos passos.\nProgresso de verdade.',
                        style: TextStyle(
                          fontSize: 44,
                          height: 1.1,
                          letterSpacing: -1.6,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Um dia difícil não apaga tudo o que você já construiu. Recomece quantas vezes precisar.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFFDCE6DA),
                          height: 1.6,
                        ),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < 7; i++)
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: i == 3
                                  ? const Color(0xFF436659)
                                  : AppColors.lime,
                              child: Icon(
                                i == 3 ? Icons.remove : Icons.check_rounded,
                                color: AppColors.green,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Consistência também tem espaço para pausas.',
                        style: TextStyle(color: Color(0xFFDCE6DA)),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (back)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/login',
                                    (_) => false,
                                  ),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Voltar para entrar'),
                            ),
                          ),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Brand(),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 28),
                        child,
                        const SizedBox(height: 24),
                        const Text(
                          'Projeto acadêmico · Desenvolvimento Mobile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
