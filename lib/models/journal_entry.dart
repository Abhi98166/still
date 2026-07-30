import 'package:flutter/foundation.dart';

@immutable
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  final String date;

  final String title;

  final String content;

  final DateTime createdAt;
  final DateTime updatedAt;

  String get snippet => content.replaceAll(RegExp(r'\s+'), ' ').trim();

  int get wordCount {
    final t = content.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;

  DateTime get dateTime => parseDateKey(date);

  JournalEntry copyWith({String? title, String? content, DateTime? updatedAt}) {
    return JournalEntry(
      id: id,
      date: date,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime parseDateKey(String key) {
    final p = key.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static String todayKey() => dateKey(DateTime.now());

  static int daysBetween(String a, String b) =>
      parseDateKey(b).difference(parseDateKey(a)).inDays;
}
