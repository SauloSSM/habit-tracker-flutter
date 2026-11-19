import 'dart:async';
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
  StreamSubscription<List<Habit>>? _subscription;
  StreamSubscription<List<Habit>>? _historySubscription;
  final _habitEvents = StreamController<List<Habit>>.broadcast();
  final _historyEvents = StreamController<List<Habit>>.broadcast();
  List<Habit> realizations = [];
  Stream<List<Habit>> get habitStream => _habitEvents.stream;
  Stream<List<Habit>> get realizationStream => _historyEvents.stream;

  List<Habit> _habits = [];
  List<Habit> get habits => List.unmodifiable(_habits);
  String? _userId;
  String? get userId => _userId;
  int _generation = 0;
  bool loading = false;
  bool historyLoading = false;
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
    final previous = _subscription;
    final previousHistory = _historySubscription;
    _subscription = null;
    _historySubscription = null;
    _userId = userId;
    realizations = [];
    _habits = [];
    _loaded = false;
    error = null;
    saving = false;
    loading = userId != null;
    historyLoading = userId != null;
    _habitEvents.add([]);
    _historyEvents.add([]);
    notifyListeners();
    await previous?.cancel();
    await previousHistory?.cancel();
    if (generation != _generation) return;
    if (userId == null) return;
    try {
      final first = Completer<void>();
      _subscription = repository
          .watchHabits(userId)
          .listen(
            (data) {
              if (generation != _generation) return;
              _habits = data;
              _loaded = true;
              loading = false;
              error = null;
              _habitEvents.add(data);
              if (!first.isCompleted) first.complete();
              notifyListeners();
            },
            onError: (Object e, StackTrace stack) {
              if (generation != _generation) return;
              _loaded = false;
              loading = false;
              error = 'Não foi possível ler os hábitos. Tente novamente.';
              _habitEvents.addError(e, stack);
              if (!first.isCompleted) first.completeError(e, stack);
              notifyListeners();
            },
          );
      _historySubscription = repository
          .watchRealizations(userId)
          .listen(
            (data) {
              if (generation != _generation) return;
              realizations = data;
              historyLoading = false;
              _historyEvents.add(data);
              notifyListeners();
            },
            onError: (Object e, StackTrace stack) {
              if (generation != _generation) return;
              error = 'Não foi possível ler as realizações. Tente novamente.';
              historyLoading = false;
              _historyEvents.addError(e, stack);
              notifyListeners();
            },
          );
      await first.future;
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

  Future<bool> _commit(
    List<Habit> next, {
    Future<void> Function(String)? action,
  }) async {
    if (!canEdit) return false;
    final userId = _userId!;
    final generation = _generation;
    saving = true;
    error = null;
    notifyListeners();
    try {
      await (action != null ? action(userId) : repository.save(userId, next));
      if (generation != _generation) return false;
      final data = await repository.load(userId);
      if (generation != _generation) return false;
      _habits = data;
      _habitEvents.add(data);
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
    final habit = Habit(
      // Bitwise shifts truncate to 32 bits on Web: 1 << 32 becomes zero.
      id: '${_now().microsecondsSinceEpoch}-${Random.secure().nextInt(0x100000000)}',
      title: title.trim(),
      description: description.trim(),
      weekdays: weekdays,
      createdAt: _now(),
    );
    return _commit([
      ..._habits,
      habit,
    ], action: (uid) => repository.put(uid, habit, create: true));
  }

  Future<bool> edit(
    String id,
    String title,
    String description,
    Set<int> weekdays,
  ) async {
    if (!_validate(title, weekdays) || find(id) == null) return false;
    final habit = find(id)!.copyWith(
      title: title.trim(),
      description: description.trim(),
      weekdays: weekdays,
    );
    return _commit([
      for (final h in _habits)
        if (h.id == id) habit else h,
    ], action: (uid) => repository.put(uid, habit, create: false));
  }

  Future<bool> delete(String id) => _commit(
    _habits.where((h) => h.id != id).toList(),
    action: (uid) => repository.remove(uid, id),
  );

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
    ], action: (uid) => repository.checkin(uid, id, day, done));
  }

  @override
  void dispose() {
    ++_generation;
    unawaited(_subscription?.cancel());
    unawaited(_historySubscription?.cancel());
    unawaited(_habitEvents.close());
    unawaited(_historyEvents.close());
    super.dispose();
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
