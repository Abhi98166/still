import 'package:flutter/foundation.dart';

import 'journal_entry.dart';

@immutable
class JournalStats {
  const JournalStats({
    required this.total,
    required this.currentStreak,
    required this.longestStreak,
    required this.thisMonth,
    required this.thisYear,
    required this.firstEntryDate,
  });

  final int total;
  final int currentStreak;
  final int longestStreak;
  final int thisMonth;
  final int thisYear;

  final String? firstEntryDate;

  static const empty = JournalStats(
    total: 0,
    currentStreak: 0,
    longestStreak: 0,
    thisMonth: 0,
    thisYear: 0,
    firstEntryDate: null,
  );

  factory JournalStats.from(List<JournalEntry> entries, {DateTime? today}) {
    if (entries.isEmpty) return empty;

    final now = today ?? DateTime.now();
    final todayKey = JournalEntry.dateKey(now);
    final dates = entries.map((e) => e.date).toSet();
    final sorted = dates.toList()..sort();

    final monthPrefix =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final yearPrefix = now.year.toString().padLeft(4, '0');

    return JournalStats(
      total: dates.length,
      currentStreak: _currentStreak(dates, now, todayKey),
      longestStreak: _longestStreak(sorted),
      thisMonth: dates.where((d) => d.startsWith(monthPrefix)).length,
      thisYear: dates.where((d) => d.startsWith('$yearPrefix-')).length,
      firstEntryDate: sorted.first,
    );
  }

  static int _currentStreak(Set<String> dates, DateTime now, String todayKey) {
    var cursor = DateTime(now.year, now.month, now.day);
    if (!dates.contains(todayKey)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (dates.contains(JournalEntry.dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int _longestStreak(List<String> ascending) {
    var best = 0;
    var run = 0;
    String? prev;
    for (final key in ascending) {
      if (prev == null) {
        run = 1;
      } else {
        run = JournalEntry.daysBetween(prev, key) == 1 ? run + 1 : 1;
      }
      prev = key;
      if (run > best) best = run;
    }
    return best;
  }

  static List<bool> heatmap(
    List<JournalEntry> entries, {
    DateTime? today,
    int days = 84,
  }) {
    final dates = entries.map((e) => e.date).toSet();
    final now = today ?? DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    return List.generate(days, (i) {
      final d = base.subtract(Duration(days: days - 1 - i));
      return dates.contains(JournalEntry.dateKey(d));
    });
  }
}
