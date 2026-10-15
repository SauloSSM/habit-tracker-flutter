import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

class HabitsRepository {
  HabitsRepository(this.preferences);
  final SharedPreferences preferences;

  String keyFor(String userId) => 'habittracker.v1.habits.$userId';

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

  Future<void> save(String userId, List<Habit> habits) async {
    final success = await preferences.setString(
      keyFor(userId),
      jsonEncode({
        'version': 1,
        'habits': habits.map((h) => h.toJson()).toList(),
      }),
    );
    if (!success) throw StateError('Falha ao gravar hábitos');
  }
}
