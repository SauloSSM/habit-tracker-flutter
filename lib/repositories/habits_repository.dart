import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

abstract class HabitsRepository {
  Future<List<Habit>> load(String uid);
  Stream<List<Habit>> watchHabits(String uid);
  Stream<List<Habit>> watchRealizations(String uid);
  Future<void> put(String uid, Habit habit, {required bool create});
  Future<void> remove(String uid, String id);
  Future<void> checkin(String uid, String id, DateTime date, bool done);
  Future<void> save(String uid, List<Habit> habits);
}

/// Legacy Part 1 storage for regression fixtures only.
class LocalHabitsRepository implements HabitsRepository {
  LocalHabitsRepository(this.preferences);
  final SharedPreferences preferences;
  final _changes = <String, StreamController<List<Habit>>>{};

  @override
  Stream<List<Habit>> watchHabits(String uid) async* {
    final controller = _changes.putIfAbsent(
      uid,
      () => StreamController<List<Habit>>.broadcast(),
    );
    yield await load(uid);
    yield* controller.stream;
  }

  @override
  Stream<List<Habit>> watchRealizations(String uid) => watchHabits(uid);

  @override
  Future<void> put(String uid, Habit habit, {required bool create}) async {
    final list = await load(uid);
    await save(uid, [...list.where((h) => h.id != habit.id), habit]);
  }

  @override
  Future<void> remove(String uid, String id) async {
    await save(uid, (await load(uid)).where((h) => h.id != id).toList());
  }

  @override
  Future<void> checkin(String uid, String id, DateTime date, bool done) async {
    final list = await load(uid);
    final h = list.firstWhere((h) => h.id == id);
    final days = {...h.checkins};
    final key = date.toIso8601String().substring(0, 10);
    done ? days.add(key) : days.remove(key);
    await put(uid, h.copyWith(checkins: days), create: false);
  }

  String keyFor(String userId) => 'habittracker.v1.habits.$userId';

  @override
  Future<List<Habit>> load(String userId) async {
    final raw = preferences.getString(keyFor(userId));
    if (raw == null) return [];
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['version'] != 1) {
      throw const FormatException('Versão desconhecida');
    }
    return (json['habits'] as List)
        .map((item) => Habit.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<void> save(String userId, List<Habit> habits) async {
    final success = await preferences.setString(
      keyFor(userId),
      jsonEncode({
        'version': 1,
        'habits': habits.map((h) => h.toJson()).toList(),
      }),
    );
    if (!success) throw StateError('Falha ao gravar hábitos');
    _changes[userId]?.add(habits);
  }
}
