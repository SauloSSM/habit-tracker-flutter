import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notifiers/auth_notifier.dart';
import 'notifiers/habits_notifier.dart';
import 'repositories/demo_auth_repository.dart';
import 'repositories/habits_repository.dart';
import 'screens/about_screen.dart';
import 'screens/create_habit_screen.dart';
import 'screens/edit_habit_screen.dart';
import 'screens/habit_checkin_screen.dart';
import 'screens/habit_history_screen.dart';
import 'screens/habits_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/recovery_screen.dart';
import 'screens/register_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final preferences = await SharedPreferences.getInstance();
    runApp(
      HabitTrackerApp(
        auth: AuthNotifier(DemoAuthRepository()),
        habits: HabitsNotifier(HabitsRepository(preferences)),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Não foi possível abrir o armazenamento local. Verifique as permissões do navegador ou dispositivo.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: main,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key, required this.auth, required this.habits});
  final AuthNotifier auth;
  final HabitsNotifier habits;
  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  void _syncUser() => unawaited(widget.habits.bindUser(widget.auth.user?.id));

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_syncUser);
    _syncUser();
  }

  @override
  void dispose() {
    widget.auth.removeListener(_syncUser);
    widget.auth.dispose();
    widget.habits.dispose();
    super.dispose();
  }

  Route<dynamic> _route(RouteSettings settings) {
    final id = settings.arguments is String
        ? settings.arguments as String
        : null;
    final screen = switch (settings.name) {
      '/login' => const LoginScreen(),
      '/register' => const RegisterScreen(),
      '/recovery' => const RecoveryScreen(),
      '/about' => const AboutScreen(),
      '/' || '/home' => const _Protected(child: HomeScreen()),
      '/profile' => const _Protected(child: ProfileScreen()),
      '/habits' => const _Protected(child: HabitsListScreen()),
      '/habits/create' => const _Protected(child: CreateHabitScreen()),
      '/habits/edit' => _Protected(child: EditHabitScreen(habitId: id)),
      '/checkin' => _Protected(child: HabitCheckinScreen(habitId: id)),
      '/history' => _Protected(child: HabitHistoryScreen(habitId: id)),
      _ => const _NotFound(),
    };
    return MaterialPageRoute(builder: (_) => screen, settings: settings);
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: widget.auth),
      ChangeNotifierProvider.value(value: widget.habits),
    ],
    child: MaterialApp(
      title: 'HabitTracker',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      initialRoute: widget.auth.user == null ? '/login' : '/home',
      onGenerateRoute: _route,
    ),
  );
}

class _Protected extends StatelessWidget {
  const _Protected({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      context.watch<AuthNotifier>().user == null ? const LoginScreen() : child;
}

class _NotFound extends StatelessWidget {
  const _NotFound();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Página não encontrada')),
    body: Center(
      child: FilledButton(
        onPressed: () =>
            Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
        child: const Text('Voltar ao início'),
      ),
    ),
  );
}
