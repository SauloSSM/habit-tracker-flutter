import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/notifiers/auth_notifier.dart';
import 'package:habit_tracker/notifiers/habits_notifier.dart';
import 'package:habit_tracker/repositories/demo_auth_repository.dart';
import 'package:habit_tracker/repositories/habits_repository.dart';
import 'package:habit_tracker/services/local_dates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  late HabitsNotifier habits;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    now = DateTime(2026, 10, 14, 16);
    habits = HabitsNotifier(HabitsRepository(preferences), now: () => now);
    await habits.bindUser('user-a');
  });

  tearDown(() => habits.dispose());

  test('começa vazio e exige título e frequência válida', () async {
    expect(habits.habits, isEmpty);
    expect(await habits.create('', '', {1}), isFalse);
    expect(await habits.create('Ler', '', {}), isFalse);
    expect(await habits.create('Ler', '', {8}), isFalse);
    expect(habits.habits, isEmpty);
  });

  test('cria, edita sem perder registros e exclui hábito', () async {
    expect(await habits.create('  Ler  ', '', {1, 3}), isTrue);
    final id = habits.habits.single.id;
    expect(habits.habits.single.title, 'Ler');
    await habits.setCheckin(id, now, true);
    expect(await habits.edit(id, 'Ler um livro', 'Uma página', {2}), isTrue);
    expect(habits.find(id)!.checkins, {'2026-10-14'});
    expect(habits.find(id)!.weekdays, {2});
    expect(await habits.delete(id), isTrue);
    expect(habits.habits, isEmpty);
  });

  test('normaliza horários locais e não duplica o mesmo dia', () async {
    await habits.create('Caminhar', '', {3});
    final id = habits.habits.single.id;
    await habits.setCheckin(id, DateTime(2026, 10, 14, 8), true);
    await habits.setCheckin(id, DateTime(2026, 10, 14, 23, 59), true);
    expect(habits.find(id)!.checkins, {'2026-10-14'});
    expect(dayKey(now), '2026-10-14');
    expect(localDay(now).hour, 0);
    await habits.setCheckin(id, now, false);
    expect(habits.find(id)!.checkins, isEmpty);
  });

  test('rejeita futuro e datas anteriores à criação', () async {
    await habits.create('Ler', '', {1});
    final id = habits.habits.single.id;
    expect(await habits.setCheckin(id, DateTime(2026, 10, 15), true), isFalse);
    expect(await habits.setCheckin(id, DateTime(2026, 10, 13), true), isFalse);
    expect(habits.find(id)!.checkins, isEmpty);
  });

  test('pausas preservam as realizações anteriores', () async {
    await habits.create('Ler', '', {1});
    final id = habits.habits.single.id;
    await habits.setCheckin(id, now, true);
    now = DateTime(2026, 10, 17);
    await habits.setCheckin(id, now, true);
    expect(habits.find(id)!.checkins, {'2026-10-14', '2026-10-17'});
  });

  test('serialização JSON restaura hábitos e isola usuários', () async {
    await habits.create('Privado de A', 'Descrição', {1, 7});
    final id = habits.habits.single.id;
    await habits.setCheckin(id, now, true);
    await habits.bindUser('user-b');
    expect(habits.habits, isEmpty);
    await habits.create('Privado de B', '', {2});
    await habits.bindUser('user-a');
    expect(habits.habits.single.title, 'Privado de A');
    expect(habits.habits.single.checkins, {'2026-10-14'});
    final restored = HabitsNotifier(HabitsRepository(preferences));
    addTearDown(restored.dispose);
    await restored.bindUser('user-a');
    expect(restored.habits.single.toJson(), habits.habits.single.toJson());
    await restored.bindUser(null);
    expect(restored.habits, isEmpty);
    expect(restored.canEdit, isFalse);
  });

  test('JSON inválido não é sobrescrito por uma nova gravação', () async {
    final key = HabitsRepository(preferences).keyFor('corrupt');
    await preferences.setString(key, '{inválido');
    await habits.bindUser('corrupt');
    expect(habits.error, isNotNull);
    expect(habits.canEdit, isFalse);
    expect(await habits.create('Teste', '', {1}), isFalse);
    expect(preferences.getString(key), '{inválido');
  });

  test('exemplos exigem modo demo e lista vazia', () async {
    expect(await habits.addDemoExamples(isDemo: false), isFalse);
    expect(await habits.addDemoExamples(isDemo: true), isTrue);
    expect(habits.habits.length, 2);
    expect(await habits.addDemoExamples(isDemo: true), isFalse);
  });

  test('gravação antiga não vaza após trocar de conta', () async {
    final repository = _DelayedRepository(preferences);
    final state = HabitsNotifier(repository, now: () => now);
    addTearDown(state.dispose);
    await state.bindUser('a');
    final pending = state.create('Só de A', '', {1});
    await state.bindUser('b');
    repository.gate.complete();
    expect(await pending, isFalse);
    expect(state.habits, isEmpty);
    await state.bindUser('a');
    expect(state.habits.single.title, 'Só de A');
  });

  test(
    'login valida credenciais e perfil notifica alteração de nome',
    () async {
      final auth = AuthNotifier(DemoAuthRepository());
      addTearDown(auth.dispose);
      var notifications = 0;
      auth.addListener(() => notifications++);
      expect(await auth.login('errado', ''), isFalse);
      expect(await auth.login(DemoAuthRepository.demoEmail, 'errada'), isFalse);
      expect(
        await auth.login(
          DemoAuthRepository.demoEmail,
          DemoAuthRepository.demoPassword,
        ),
        isTrue,
      );
      expect(await auth.updateName('ab'), isFalse);
      expect(await auth.updateName('Novo Nome'), isTrue);
      expect(auth.user!.name, 'Novo Nome');
      expect(notifications, greaterThan(0));
      await auth.logout();
      expect(auth.user, isNull);
    },
  );

  test(
    'cadastro acessa conta, valida duplicação e não persiste senhas',
    () async {
      final auth = AuthNotifier(DemoAuthRepository());
      addTearDown(auth.dispose);
      expect(
        await auth.register(
          'Pessoa',
          'pessoa@teste.com',
          '11999999999',
          'Senha123!',
        ),
        isTrue,
      );
      expect(auth.user!.name, 'Pessoa');
      await auth.logout();
      expect(
        await auth.register(
          'Pessoa',
          'pessoa@teste.com',
          '11999999999',
          'Senha123!',
        ),
        isFalse,
      );
      expect(await auth.login('PESSOA@TESTE.COM', 'Senha123!'), isTrue);
      expect(preferences.getKeys(), isEmpty);
      expect(await auth.recover('pessoa@teste.com'), isTrue);
      expect(auth.recoveryMessage, contains('Nenhum e-mail foi enviado'));
    },
  );
}

class _DelayedRepository extends HabitsRepository {
  _DelayedRepository(super.preferences);
  final gate = Completer<void>();
  @override
  Future<void> save(String userId, List<Habit> habits) async {
    await gate.future;
    await super.save(userId, habits);
  }
}
