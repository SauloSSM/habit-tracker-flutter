import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/auth_notifier.dart';
import '../notifiers/habits_notifier.dart';
import '../theme/app_theme.dart';
import 'common.dart';

const destinations = [
  (route: '/home', label: 'Início', icon: Icons.grid_view_rounded),
  (route: '/habits', label: 'Hábitos', icon: Icons.spa_outlined),
  (
    route: '/checkin',
    label: 'Registrar',
    icon: Icons.check_circle_outline_rounded,
  ),
  (route: '/history', label: 'Histórico', icon: Icons.calendar_month_outlined),
  (route: '/profile', label: 'Perfil', icon: Icons.person_outline_rounded),
];

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.selected = 0,
    this.formPage = false,
  });
  final String title;
  final Widget child;
  final int selected;
  final bool formPage;

  void _navigate(BuildContext context, int index) {
    if (index != selected || formPage) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        destinations[index].route,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final habits = context.watch<HabitsNotifier>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: formPage,
        title: wide
            ? Text(title, style: const TextStyle(fontSize: 16))
            : const Brand(compact: true),
        actions: [
          if (context.watch<AuthNotifier>().isDemo)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                label: Text('Demo'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          IconButton(
            tooltip: 'Sobre o aplicativo',
            onPressed: () => Navigator.pushNamed(context, '/about'),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            Container(
              width: 228,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFE0E5DB))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 16, 12, 32),
                    child: Brand(compact: true),
                  ),
                  for (var i = 0; i < destinations.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ListTile(
                        selected: selected == i,
                        selectedTileColor: AppColors.lime,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: Icon(destinations[i].icon),
                        title: Text(destinations[i].label),
                        onTap: () => _navigate(context, i),
                      ),
                    ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Um pouco a cada dia.\nNo seu ritmo.',
                      style: TextStyle(color: AppColors.muted, height: 1.7),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  if (habits.loading) const LinearProgressIndicator(),
                  if (habits.error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        children: [
                          Notice(habits.error!, error: true),
                          TextButton(
                            onPressed: habits.retry,
                            child: const Text('Recarregar dados'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide || formPage
          ? null
          : NavigationBar(
              selectedIndex: selected.clamp(0, 4),
              onDestinationSelected: (index) => _navigate(context, index),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(icon: Icon(d.icon), label: d.label),
              ],
            ),
    );
  }
}
