import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/notifiers/auth_notifier.dart';
import 'package:habit_tracker/notifiers/habits_notifier.dart';
import 'package:habit_tracker/repositories/firebase_auth_repository.dart';
import 'package:habit_tracker/repositories/firestore_habits_repository.dart';
import 'package:habit_tracker/services/local_dates.dart';

import 'screens_test.dart' show go;

void main() {
  testWidgets(
    'telas Firebase exibem streams de hábitos e realizações e edição externa',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = FakeFirebaseFirestore();
      final firebaseAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'real-uid',
          email: 'pessoa@teste.com',
          displayName: 'Pessoa',
        ),
      );
      final auth = AuthNotifier(
        FirebaseAuthRepository(auth: firebaseAuth, firestore: db),
      );
      final repository = FirestoreHabitsRepository(firestore: db);
      final state = HabitsNotifier(repository);
      await tester.pumpWidget(HabitTrackerApp(auth: auth, habits: state));
      await tester.pumpAndSettle();
      expect(find.text('Demo'), findsNothing);
      await go(tester, '/habits');
      expect(find.text('Todo começo tem espaço'), findsOneWidget);
      final today = localDay(DateTime.now());
      final habit = Habit(
        id: 'external',
        title: 'Ler na nuvem',
        description: '',
        weekdays: {1},
        createdAt: today,
      );
      await repository.put('real-uid', habit, create: true);
      await tester.pumpAndSettle();
      expect(find.text('Ler na nuvem'), findsOneWidget);
      expect(find.byType(StreamBuilder<List<Habit>>), findsOneWidget);
      await repository.checkin('real-uid', habit.id, today, true);
      await go(tester, '/history');
      expect(find.text(displayDate(today)), findsOneWidget);
      expect(find.byType(StreamBuilder<List<Habit>>), findsOneWidget);
      await repository.put(
        'real-uid',
        habit.copyWith(title: 'Nome atualizado na nuvem'),
        create: false,
      );
      await tester.pumpAndSettle();
      expect(find.text('Nome atualizado na nuvem'), findsWidgets);
      await repository.remove('real-uid', habit.id);
      await tester.pumpAndSettle();
      expect(find.text('Seu histórico começa com um passo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
