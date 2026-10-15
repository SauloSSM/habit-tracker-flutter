import '../services/local_dates.dart';

class Habit {
  Habit({
    required this.id,
    required this.title,
    required this.description,
    required Iterable<int> weekdays,
    required DateTime createdAt,
    Iterable<String> checkins = const [],
  }) : weekdays = Set.unmodifiable(weekdays),
       createdAt = localDay(createdAt),
       checkins = Set.unmodifiable(checkins);

  final String id;
  final String title;
  final String description;
  final Set<int> weekdays;
  final DateTime createdAt;
  final Set<String> checkins;

  bool isDone(DateTime date) => checkins.contains(dayKey(date));
  bool isScheduled(DateTime date) => weekdays.contains(date.weekday);

  Habit copyWith({
    String? title,
    String? description,
    Iterable<int>? weekdays,
    Iterable<String>? checkins,
  }) => Habit(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    weekdays: weekdays ?? this.weekdays,
    createdAt: createdAt,
    checkins: checkins ?? this.checkins,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'weekdays': weekdays.toList()..sort(),
    'createdAt': dayKey(createdAt),
    'checkins': checkins.toList()..sort(),
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    weekdays: (json['weekdays'] as List).cast<int>(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    checkins: (json['checkins'] as List).cast<String>(),
  );
}
