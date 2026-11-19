import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/habit.dart';
import '../services/local_dates.dart';
import 'habits_repository.dart';

/// Production persistence. Local repository remains available only for Part 1
/// fixtures; production never reads shared_preferences.
class FirestoreHabitsRepository implements HabitsRepository {
  FirestoreHabitsRepository({FirebaseFirestore? firestore})
    : db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore db;

  Query<Map<String, dynamic>> _query(String collection, String uid) =>
      db.collection(collection).where('uid', isEqualTo: uid);

  Habit _habit(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Habit(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      weekdays: (data['weekdays'] as List).cast<int>(),
      createdAt: DateTime.parse(data['createdDay'] as String),
      checkins: (data['checkins'] as List).cast<String>(),
    );
  }

  @override
  Stream<List<Habit>> watchHabits(String uid) => _query('habitos', uid)
      .snapshots(includeMetadataChanges: true)
      .map(
        (s) =>
            s.docs.map(_habit).toList()..sort((a, b) => a.id.compareTo(b.id)),
      );

  @override
  Stream<List<Habit>> watchRealizations(
    String uid,
  ) => _query('realizacoes', uid)
      .snapshots(includeMetadataChanges: true)
      .map(
        (s) => s.docs.map((doc) {
          final data = doc.data();
          // History joins the current habit title in the screen; editing a title
          // never creates a stale copy in realizacoes.
          return Habit(
            id: data['habitId'] as String,
            title: '',
            description: '',
            weekdays: const [],
            createdAt: DateTime.parse(data['createdDay'] as String),
            checkins: (data['datas'] as List).cast<String>(),
          );
        }).toList(),
      );

  @override
  Future<List<Habit>> load(String userId) async =>
      (await _query('habitos', userId).get()).docs.map(_habit).toList();

  @override
  Future<void> save(String userId, List<Habit> habits) =>
      throw UnsupportedError(
        'Use operações por documento, sem sobrescrever listas.',
      );

  @override
  Future<void> put(String uid, Habit habit, {required bool create}) async {
    final ref = db.collection('habitos').doc(habit.id);
    final history = db.collection('realizacoes').doc(habit.id);
    await db.runTransaction((tx) async {
      final old = await tx.get(ref);
      if (old.exists && old.data()!['uid'] != uid) {
        throw StateError('Acesso negado');
      }
      if (create && old.exists || !create && !old.exists) {
        throw StateError(
          'Hábito alterado em outra sessão. Recarregue os dados.',
        );
      }
      final fields = <String, dynamic>{
        'title': habit.title,
        'description': habit.description,
        'weekdays': habit.weekdays.toList()..sort(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (create) {
        tx.set(ref, {
          ...fields,
          'uid': uid,
          'createdDay': dayKey(habit.createdAt),
          'createdAt': FieldValue.serverTimestamp(),
          'checkins': <String>[],
        });
        tx.set(history, {
          'uid': uid,
          'habitId': habit.id,
          'createdDay': dayKey(habit.createdAt),
          'datas': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Only metadata changes: concurrent check-ins are preserved.
        tx.update(ref, fields);
      }
    });
  }

  @override
  Future<void> remove(String uid, String id) => db.runTransaction((tx) async {
    final ref = db.collection('habitos').doc(id);
    final habit = await tx.get(ref);
    if (!habit.exists || habit.data()!['uid'] != uid) {
      throw StateError('Hábito indisponível');
    }
    tx.delete(ref);
    tx.delete(db.collection('realizacoes').doc(id));
  });

  @override
  Future<void> checkin(String uid, String id, DateTime date, bool done) =>
      db.runTransaction((tx) async {
        final ref = db.collection('habitos').doc(id);
        final doc = await tx.get(ref);
        if (!doc.exists || doc.data()!['uid'] != uid) {
          throw StateError('Hábito indisponível');
        }
        final habit = _habit(doc);
        final day = localDay(date);
        if (day.isBefore(habit.createdAt) ||
            day.isAfter(localDay(DateTime.now()))) {
          throw StateError('Data inválida');
        }
        final dates = {...habit.checkins};
        done ? dates.add(dayKey(day)) : dates.remove(dayKey(day));
        final values = dates.toList()..sort();
        tx.update(ref, {
          'checkins': values,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        tx.update(db.collection('realizacoes').doc(id), {
          'datas': values,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
}
