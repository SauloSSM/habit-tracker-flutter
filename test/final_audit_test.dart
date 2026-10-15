import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/screens/about_screen.dart';
import 'package:habit_tracker/screens/habit_checkin_screen.dart';
import 'package:habit_tracker/screens/habit_history_screen.dart';
import 'package:habit_tracker/screens/habits_list_screen.dart';
import 'package:habit_tracker/screens/home_screen.dart';
import 'package:habit_tracker/screens/login_screen.dart';
import 'package:habit_tracker/screens/profile_screen.dart';
import 'package:habit_tracker/services/local_dates.dart';

import 'screens_test.dart' show openApp, tapText, go;

void main() {
  for (final width in [360.0, 1280.0]) {
    testWidgets('navegação por botões e logout em ${width.toInt()}px', (
      tester,
    ) async {
      final state = await openApp(
        tester,
        loggedIn: true,
        size: Size(width, 900),
      );

      final targets = [
        ('Hábitos', HabitsListScreen),
        ('Registrar', HabitCheckinScreen),
        ('Histórico', HabitHistoryScreen),
        ('Perfil', ProfileScreen),
        ('Início', HomeScreen),
      ];
      for (final (label, screenType) in targets) {
        await tapText(tester, label);
        expect(find.byType(screenType), findsOneWidget);
      }

      await tester.tap(find.byTooltip('Sobre o aplicativo'));
      await tester.pumpAndSettle();
      expect(find.byType(AboutScreen), findsOneWidget);
      await tester.scrollUntilVisible(find.text('[Nome do integrante 1]'), 300);
      expect(find.text('[Nome do integrante 1]'), findsOneWidget);
      final backTooltip = MaterialLocalizations.of(
        tester.element(find.byType(AboutScreen)),
      ).backButtonTooltip;
      await tester.tap(find.byTooltip(backTooltip));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      await tapText(tester, 'Perfil');
      await tapText(tester, 'Sair da conta');
      expect(state.auth.user, isNull);
      expect(state.habits.habits, isEmpty);
      expect(find.byType(LoginScreen), findsOneWidget);
      await go(tester, '/profile');
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'data, desmarcação e filtro do histórico funcionam pela interface',
    (tester) async {
      final state = await openApp(tester, loggedIn: true);
      await state.habits.addDemoExamples(isDemo: true);
      final reading = state.habits.habits.first;
      final original = {...reading.checkins};
      final today = localDay(DateTime.now());
      final yesterday = DateTime(today.year, today.month, today.day - 1);

      await go(tester, '/checkin', id: reading.id);
      await tapText(tester, 'Escolher data');
      final dialog = find.byType(DatePickerDialog);
      expect(dialog, findsOneWidget);
      final localizations = MaterialLocalizations.of(tester.element(dialog));
      await tester.tap(find.byTooltip(localizations.inputDateModeButtonLabel));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(of: dialog, matching: find.byType(TextFormField)),
        displayDate(yesterday),
      );
      await tapText(tester, localizations.okButtonLabel);
      expect(find.text(displayDate(yesterday)), findsOneWidget);

      for (final expectedDone in [true, false, true]) {
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
        final habit = state.habits.find(reading.id)!;
        expect(habit.isDone(yesterday), expectedDone);
        expect(habit.checkins.containsAll(original), isTrue);
        expect(habit.checkins.length, original.length + (expectedDone ? 1 : 0));
      }

      await tapText(tester, 'Ver minhas realizações');
      expect(find.byType(HabitHistoryScreen), findsOneWidget);
      expect(find.text(displayDate(yesterday)), findsOneWidget);

      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tapText(tester, 'Caminhar ao ar livre');
      expect(find.text('Seu histórico começa com um passo'), findsOneWidget);
      expect(find.text(displayDate(yesterday)), findsNothing);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tapText(tester, 'Todos os hábitos');
      expect(find.text(displayDate(yesterday)), findsOneWidget);
      expect(find.text('Seu histórico começa com um passo'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
