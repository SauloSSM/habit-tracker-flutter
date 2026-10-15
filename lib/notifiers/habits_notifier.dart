import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import '../repositories/habits_repository.dart';
import '../services/local_dates.dart';
import '../services/validators.dart';

class HabitsNotifier extends ChangeNotifier {
  HabitsNotifier(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final HabitsRepository repository;
  final DateTime Function() _now;
  List<Habit> _habits = [];
  List<Habit> get habits => List.unmodifiable(_habits);
  String? _userId;
  int _generation = 0;
  bool loading = false;
  bool saving = false;
  bool _loaded = false;
  String? error;
  bool get canEdit => _userId != null && _loaded && !loading && !saving;

  Habit? find(String? id) {
    for (final habit in _habits) {
      if (habit.id == id) return habit;
    }
    return null;
  }

  Future<void> bindUser(String? userId, {bool force = false}) async {
    if (!force && userId == _userId) return;
    final generation = ++_generation;
    _userId = userId;
    _habits = [];
    _loaded = false;
    error = null;
    saving = false;
    loading = userId != null;
    notifyListeners();
    if (userId == null) return;
    try {
      final data = await repository.load(userId);
      if (generation != _generation) return;
      _habits = data;
      _loaded = true;
    } catch (_) {
      if (generation != _generation) return;
      error =
          'Não foi possível ler os hábitos. Os dados salvos foram preservados.';
    } finally {
      if (generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> retry() => bindUser(_userId, force: true);

  Future<bool> _commit(List<Habit> next) async {
    if (!canEdit) return false;
    final userId = _userId!;
    final generation = _generation;
    saving = true;
    error = null;
    notifyListeners();
    try {
      await repository.save(userId, next);
      if (generation != _generation) return false;
      _habits = next;
      return true;
    } catch (_) {
      if (generation == _generation) {
        error = 'Não foi possível salvar. Tente novamente.';
      }
      return false;
    } finally {
      if (generation == _generation) {
        saving = false;
        notifyListeners();
      }
    }
  }

  bool _validate(String title, Set<int> weekdays) {
    error = Validators.title(title);
    if (weekdays.isEmpty || weekdays.any((day) => day < 1 || day > 7)) {
      error = 'Selecione pelo menos um dia da semana.';
    }
    if (error != null) notifyListeners();
    return error == null;
  }

  Future<bool> create(
    String title,
    String description,
    Set<int> weekdays,
  ) async {
    if (!_validate(title, weekdays)) return false;
    return _commit([
      ..._habits,
      Habit(
        id: '${_now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
        title: title.trim(),
        description: description.trim(),
        weekdays: weekdays,
        createdAt: _now(),
      ),
    ]);
  }

  Future<bool> edit(
    String id,
    String title,
    String description,
    Set<int> weekdays,
  ) async {
    if (!_validate(title, weekdays) || find(id) == null) return false;
    return _commit([
      for (final h in _habits)
        if (h.id == id)
          h.copyWith(
            title: title.trim(),
            description: description.trim(),
            weekdays: weekdays,
          )
        else
          h,
    ]);
  }

  Future<bool> delete(String id) =>
      _commit(_habits.where((h) => h.id != id).toList());

  Future<bool> setCheckin(String id, DateTime date, bool done) async {
    final habit = find(id);
    if (habit == null || !canEdit) return false;
    final day = localDay(date);
    if (day.isAfter(localDay(_now())) || day.isBefore(habit.createdAt)) {
      error = 'Escolha uma data entre a criação do hábito e hoje.';
      notifyListeners();
      return false;
    }
    final entries = {...habit.checkins};
    if (done) {
      entries.add(dayKey(day));
    } else {
      entries.remove(dayKey(day));
    }
    return _commit([
      for (final h in _habits)
        if (h.id == id) h.copyWith(checkins: entries) else h,
    ]);
  }

  /// Só deve ser chamado pelo botão explícito exibido no modo demonstração.
  Future<bool> addDemoExamples({required bool isDemo}) async {
    if (!isDemo || _habits.isNotEmpty) return false;
    final today = localDay(_now());
    return _commit([
      Habit(
        id: 'demo-reading',
        title: 'Ler algumas páginas',
        description: 'Uma pausa para descobrir novas ideias.',
        weekdays: {1, 2, 3, 4, 5, 6, 7},
        createdAt: DateTime(today.year, today.month, today.day - 6),
        checkins: [
          dayKey(DateTime(today.year, today.month, today.day - 2)),
          dayKey(DateTime(today.year, today.month, today.day - 4)),
        ],
      ),
      Habit(
        id: 'demo-walk',
        title: 'Caminhar ao ar livre',
        description: 'Movimento no meu ritmo, sem cobrança.',
        weekdays: {1, 3, 5},
        createdAt: today,
      ),
    ]);
  }
}
