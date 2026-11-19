import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/notifiers/auth_notifier.dart';
import 'package:habit_tracker/notifiers/habits_notifier.dart';
import 'package:habit_tracker/repositories/demo_auth_repository.dart';
import 'package:habit_tracker/repositories/habits_repository.dart';
import 'package:habit_tracker/screens/create_habit_screen.dart';
import 'package:habit_tracker/screens/edit_habit_screen.dart';
import 'package:habit_tracker/screens/habit_checkin_screen.dart';
import 'package:habit_tracker/screens/habit_history_screen.dart';
import 'package:habit_tracker/screens/habits_list_screen.dart';
import 'package:habit_tracker/screens/login_screen.dart';

Future<({AuthNotifier auth, HabitsNotifier habits})> openApp(
  WidgetTester tester, {
  bool loggedIn = false,
  Size size = const Size(1200, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final auth = AuthNotifier(DemoAuthRepository());
  if (loggedIn) {
    await auth.login(
      DemoAuthRepository.demoEmail,
      DemoAuthRepository.demoPassword,
    );
  }
  final habits = HabitsNotifier(LocalHabitsRepository(prefs));
  await tester.pumpWidget(HabitTrackerApp(auth: auth, habits: habits));
  await tester.pumpAndSettle();
  return (auth: auth, habits: habits);
}

Future<void> tapText(WidgetTester tester, String label) async {
  final controls = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate(
      (widget) => widget is ButtonStyleButton || widget is FilterChip,
    ),
  );
  final finder = controls.evaluate().isNotEmpty
      ? controls.last
      : find.text(label).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> go(WidgetTester tester, String route, {String? id}) async {
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .pushNamed(route, arguments: id);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'login valida obrigatórios, e-mail e credenciais; conta exemplo entra',
    (tester) async {
      await openApp(tester);
      await tapText(tester, 'Entrar');
      expect(find.text('Informe seu e-mail.'), findsOneWidget);
      expect(find.text('Informe sua senha.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'invalido');
      await tester.enterText(find.byType(TextFormField).last, 'errada');
      await tapText(tester, 'Entrar');
      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'teste@teste.com',
      );
      await tapText(tester, 'Entrar');
      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
      await tapText(tester, 'Preencher conta de exemplo');
      await tapText(tester, 'Entrar');
      expect(find.text('Olá, Estudante 🌿'), findsOneWidget);
    },
  );

  testWidgets(
    'cadastro valida campos e senhas iguais antes de permitir acesso',
    (tester) async {
      await openApp(tester);
      await tapText(tester, 'Criar minha conta');
      await tapText(tester, 'Criar conta');
      expect(
        find.text('Informe um nome com pelo menos 3 caracteres.'),
        findsOneWidget,
      );
      expect(find.text('Informe seu e-mail.'), findsOneWidget);
      expect(
        find.text('Informe um telefone com DDD (10 a 13 dígitos).'),
        findsOneWidget,
      );
      expect(find.text('Use pelo menos 8 caracteres.'), findsOneWidget);
      expect(find.text('Confirme sua senha.'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Pessoa Teste');
      await tester.enterText(fields.at(1), 'email-invalido');
      await tester.enterText(fields.at(2), '123');
      await tester.enterText(fields.at(3), 'curta');
      await tapText(tester, 'Criar conta');
      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      expect(
        find.text('Informe um telefone com DDD (10 a 13 dígitos).'),
        findsOneWidget,
      );
      expect(find.text('Use pelo menos 8 caracteres.'), findsOneWidget);
      await tester.enterText(fields.at(1), 'pessoa@teste.com');
      await tester.enterText(fields.at(2), '11999999999');
      await tester.enterText(fields.at(3), 'Senha123!');
      await tester.enterText(fields.at(4), 'Outra123!');
      await tapText(tester, 'Criar conta');
      expect(find.text('As senhas precisam ser iguais.'), findsOneWidget);
      await tester.enterText(fields.at(4), 'Senha123!');
      await tapText(tester, 'Criar conta');
      expect(find.text('Olá, Pessoa 🌿'), findsOneWidget);
    },
  );

  testWidgets(
    'recuperação é simulação, valida e-mail e explica ausência de envio',
    (tester) async {
      await openApp(tester);
      await tapText(tester, 'Esqueci minha senha');
      await tapText(tester, 'Simular solicitação');
      expect(find.text('Informe seu e-mail.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'email-invalido');
      await tapText(tester, 'Simular solicitação');
      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'pessoa@teste.com');
      await tapText(tester, 'Simular solicitação');
      expect(
        find.textContaining('Simulação concluída. Nenhum e-mail foi enviado.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('perfil é protegido e novo nome aparece na saudação', (
    tester,
  ) async {
    final state = await openApp(tester);
    await go(tester, '/profile');
    expect(find.byType(LoginScreen), findsOneWidget);
    await state.auth.login(
      DemoAuthRepository.demoEmail,
      DemoAuthRepository.demoPassword,
    );
    await tester.pumpAndSettle();
    expect(find.text(DemoAuthRepository.demoEmail), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '');
    await tapText(tester, 'Salvar nome');
    expect(
      find.text('Informe um nome com pelo menos 3 caracteres.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), 'ab');
    await tapText(tester, 'Salvar nome');
    expect(
      find.text('Informe um nome com pelo menos 3 caracteres.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), 'Nome Editado');
    await tapText(tester, 'Salvar nome');
    expect(find.text('Nome atualizado com sucesso.'), findsOneWidget);
    expect(state.auth.user!.email, DemoAuthRepository.demoEmail);
    await go(tester, '/home');
    expect(find.text('Olá, Nome 🌿'), findsOneWidget);
  });

  testWidgets(
    'cinco telas: criar, listar, editar, registrar, histórico e excluir',
    (tester) async {
      final state = await openApp(tester, loggedIn: true);
      await go(tester, '/habits');
      expect(find.byType(HabitsListScreen), findsOneWidget);
      expect(find.text('Todo começo tem espaço'), findsOneWidget);
      await tapText(tester, 'Novo hábito');
      expect(find.byType(CreateHabitScreen), findsOneWidget);
      await tapText(tester, 'Criar hábito');
      expect(find.text('Dê um título ao hábito.'), findsOneWidget);
      expect(
        find.text('Selecione pelo menos um dia da semana.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextFormField).first,
        'Ler um capítulo',
      );
      await tapText(tester, 'Seg');
      await tapText(tester, 'Criar hábito');
      expect(find.byType(HabitsListScreen), findsOneWidget);
      expect(find.text('Ler um capítulo'), findsOneWidget);
      final id = state.habits.habits.single.id;
      await tester.tap(find.byTooltip('Editar Ler um capítulo'));
      await tester.pumpAndSettle();
      expect(find.byType(EditHabitScreen), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Ler duas páginas',
      );
      await tapText(tester, 'Salvar alterações');
      expect(find.text('Ler duas páginas'), findsOneWidget);
      await tapText(tester, 'Registrar realização');
      expect(find.byType(HabitCheckinScreen), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(state.habits.habits.single.checkins.length, 1);
      await tapText(tester, 'Ver minhas realizações');
      expect(find.byType(HabitHistoryScreen), findsOneWidget);
      expect(find.text('realizações acumuladas'), findsOneWidget);
      expect(find.text('Ler duas páginas'), findsWidgets);
      await go(tester, '/habits/edit', id: id);
      await tapText(tester, 'Excluir hábito');
      await tapText(tester, 'Cancelar');
      expect(state.habits.habits.length, 1);
      await tapText(tester, 'Excluir hábito');
      await tapText(tester, 'Excluir');
      expect(state.habits.habits, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(360, 800), const Size(1280, 900)]) {
    testWidgets('layout e rotas em ${size.width.toInt()}px sem overflow', (
      tester,
    ) async {
      final state = await openApp(tester, loggedIn: true, size: size);
      await state.habits.addDemoExamples(isDemo: true);
      await tester.pumpAndSettle();
      for (final route in [
        '/habits',
        '/habits/create',
        '/habits/edit',
        '/checkin',
        '/history',
        '/profile',
        '/about',
      ]) {
        await go(
          tester,
          route,
          id: route == '/habits/edit' ? state.habits.habits.first.id : null,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'Falha em $route com largura ${size.width}',
        );
      }
    });
  }
}
