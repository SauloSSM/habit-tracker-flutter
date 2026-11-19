import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/notifiers/auth_notifier.dart';
import 'package:habit_tracker/notifiers/habits_notifier.dart';
import 'package:habit_tracker/repositories/firebase_auth_repository.dart';
import 'package:habit_tracker/repositories/firestore_habits_repository.dart';
import 'package:habit_tracker/services/local_dates.dart';

class RetryRepository extends FirestoreHabitsRepository {
  RetryRepository(FirebaseFirestore db) : super(firestore: db);
  bool failRead = true;
  bool failWrite = false;
  @override
  Stream<List<Habit>> watchHabits(String uid) => failRead
      ? Stream.error(StateError('Sem conexão'))
      : super.watchHabits(uid);
  @override
  Future<void> put(String uid, Habit habit, {required bool create}) async {
    if (failWrite) throw StateError('Gravação negada');
    await super.put(uid, habit, create: create);
  }
}

class RecordingAuth extends MockFirebaseAuth {
  RecordingAuth()
    : super(
        mockUser: MockUser(
          uid: 'firebase-uid',
          email: 'pessoa@teste.com',
          displayName: 'Pessoa',
        ),
      );
  String? resetEmail;
  String? failure;
  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    if (failure != null) throw FirebaseAuthException(code: failure!);
    resetEmail = email;
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (failure != null) throw FirebaseAuthException(code: failure!);
    return super.signInWithEmailAndPassword(email: email, password: password);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeFirebaseFirestore db;
  late FirestoreHabitsRepository repository;
  late DateTime today;
  setUp(() {
    db = FakeFirebaseFirestore();
    repository = FirestoreHabitsRepository(firestore: db);
    today = localDay(DateTime.now());
  });
  Habit habit(String id) => Habit(
    id: id,
    title: 'Ler',
    description: 'Uma página',
    weekdays: {1, 3},
    createdAt: today,
  );

  test(
    'cadastro persiste perfil com UID Firebase, telefone e datas sem senha',
    () async {
      final auth = RecordingAuth();
      final notifier = AuthNotifier(
        FirebaseAuthRepository(auth: auth, firestore: db),
      );
      addTearDown(notifier.dispose);
      expect(
        await notifier.register(
          'Pessoa',
          'pessoa@teste.com',
          '11999999999',
          'Senha123!',
        ),
        isTrue,
      );
      final user = notifier.user!;
      final data = (await db.collection('usuarios').doc(user.id).get()).data()!;
      expect(data.keys.toSet(), {
        'uid',
        'nome',
        'telefone',
        'email',
        'createdAt',
        'updatedAt',
      });
      expect(data['uid'], auth.currentUser!.uid);
      expect(data['telefone'], '11999999999');
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
      expect(user.phone, '11999999999');
      expect(await notifier.updateName('Outro nome'), isTrue);
      expect(
        (await db.collection('usuarios').doc(user.id).get())['nome'],
        'Outro nome',
      );
      expect(await notifier.logout(), isTrue);
      expect(notifier.user, isNull);
    },
  );

  test(
    'login usa UID real e traduz erros Firebase; recuperação chama envio SDK',
    () async {
      final auth = RecordingAuth();
      final notifier = AuthNotifier(
        FirebaseAuthRepository(auth: auth, firestore: db),
      );
      addTearDown(notifier.dispose);
      auth.failure = 'invalid-credential';
      expect(await notifier.login('pessoa@teste.com', 'errada'), isFalse);
      expect(notifier.error, 'E-mail ou senha incorretos.');
      expect(notifier.user, isNull);
      auth.failure = null;
      expect(await notifier.login('pessoa@teste.com', 'Senha123!'), isTrue);
      expect(notifier.user!.id, 'firebase-uid');
      expect(notifier.isDemo, isFalse);
      expect(await notifier.recover(' PESSOA@TESTE.COM '), isTrue);
      expect(auth.resetEmail, 'pessoa@teste.com');
      expect(notifier.recoveryMessage, contains('instruções de recuperação'));
      auth.failure = 'too-many-requests';
      expect(await notifier.recover('pessoa@teste.com'), isFalse);
      expect(notifier.recoveryMessage, isNull);
      expect(notifier.error, contains('Muitas tentativas'));
    },
  );

  test(
    'CRUD e check-ins mantêm as duas coleções consistentes e não duplicam',
    () async {
      await repository.put('a', habit('h1'), create: true);
      expect(
        (await db.collection('habitos').doc('h1').get()).data()!.length,
        greaterThanOrEqualTo(5),
      );
      final stale = (await repository.load('a')).single;
      await repository.checkin('a', 'h1', today, true);
      await repository.checkin('a', 'h1', today, true);
      await repository.put(
        'a',
        stale.copyWith(title: 'Novo título'),
        create: false,
      );
      expect((await repository.load('a')).single.checkins, {dayKey(today)});
      expect((await db.collection('realizacoes').doc('h1').get())['datas'], [
        dayKey(today),
      ]);
      await repository.checkin('a', 'h1', today, false);
      expect((await repository.load('a')).single.checkins, isEmpty);
      expect(
        (await db.collection('realizacoes').doc('h1').get())['datas'],
        isEmpty,
      );
      await repository.remove('a', 'h1');
      expect((await db.collection('habitos').doc('h1').get()).exists, isFalse);
      expect(
        (await db.collection('realizacoes').doc('h1').get()).exists,
        isFalse,
      );
      await expectLater(
        repository.put('a', stale, create: false),
        throwsStateError,
      );
      await expectLater(
        repository.checkin('a', 'h1', today, true),
        throwsStateError,
      );
    },
  );

  test(
    'streams independentes consultam habitos e realizacoes pelo UID',
    () async {
      await repository.put('a', habit('a1'), create: true);
      await repository.put('b', habit('b1'), create: true);
      final habits = await repository.watchHabits('a').first;
      final history = await repository.watchRealizations('a').first;
      expect(habits.single.id, 'a1');
      expect(history.single.id, 'a1');
      final next = repository
          .watchRealizations('a')
          .firstWhere((list) => list.single.checkins.isNotEmpty);
      await repository.checkin('a', 'a1', today, true);
      expect((await next).single.checkins, {dayKey(today)});
      await expectLater(repository.remove('b', 'a1'), throwsStateError);
    },
  );

  test(
    'notifier reage a alterações externas e limpa dados ao trocar UID',
    () async {
      final state = HabitsNotifier(repository);
      addTearDown(state.dispose);
      await state.bindUser('a');
      final received = state.habitStream.firstWhere(
        (items) => items.isNotEmpty,
      );
      await repository.put('a', habit('external'), create: true);
      await received;
      expect(state.habits.single.id, 'external');
      await state.bindUser('b');
      expect(state.habits, isEmpty);
      await state.bindUser(null);
      expect(state.realizations, isEmpty);
      expect(state.canEdit, isFalse);
    },
  );

  test(
    'falhas de leitura e gravação permitem tentar novamente sem perder dados',
    () async {
      final repo = RetryRepository(db);
      final state = HabitsNotifier(repo);
      addTearDown(state.dispose);
      await state.bindUser('a');
      expect(state.loading, isFalse);
      expect(state.error, isNotNull);
      expect(state.canEdit, isFalse);
      repo.failRead = false;
      await state.retry();
      expect(state.canEdit, isTrue);
      repo.failWrite = true;
      expect(await state.create('Ler', '', {1}), isFalse);
      expect(state.habits, isEmpty);
      expect(state.error, isNotNull);
      repo.failWrite = false;
      expect(await state.create('Ler', '', {1}), isTrue);
      expect(state.habits, hasLength(1));
    },
  );

  test('falha ao persistir cadastro não deixa sessão autenticada', () async {
    final denied = FakeFirebaseFirestore(
      securityRules: '''
      service cloud.firestore {
        match /databases/{database}/documents {
          match /{document=**} { allow read, write: if false; }
        }
      }
    ''',
    );
    final auth = RecordingAuth();
    final notifier = AuthNotifier(
      FirebaseAuthRepository(auth: auth, firestore: denied),
    );
    addTearDown(notifier.dispose);
    expect(
      await notifier.register(
        'Pessoa',
        'pessoa@teste.com',
        '11999999999',
        'Senha123!',
      ),
      isFalse,
    );
    expect(notifier.user, isNull);
    expect(auth.currentUser, isNull);
    // FakeFirestore denies with a plain Exception; SDK error translation is
    // exercised separately and security itself is tested in the real emulator.
    expect(notifier.error, isNotNull);
  });

  test(
    'datas futuras e anteriores à criação são rejeitadas no repositório',
    () async {
      await repository.put('a', habit('h1'), create: true);
      for (final day in [
        today.add(const Duration(days: 1)),
        today.subtract(const Duration(days: 1)),
      ]) {
        await expectLater(
          repository.checkin('a', 'h1', day, true),
          throwsStateError,
        );
      }
      expect((await repository.load('a')).single.checkins, isEmpty);
    },
  );
}
