import 'package:flutter_test/flutter_test.dart';
import 'package:still/models/journal_entry.dart';
import 'package:still/models/journal_stats.dart';

JournalEntry _entry(String date, {String title = '', String content = 'x'}) {
  final at = DateTime(2026, 1, 1);
  return JournalEntry(
    id: 'entry-$date',
    date: date,
    title: title,
    content: content,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  final today = DateTime(2026, 7, 30);

  group('current streak', () {
    test('is zero with no entries', () {
      expect(JournalStats.from(const [], today: today).currentStreak, 0);
    });

    test('counts an unbroken run ending today', () {
      final stats = JournalStats.from([
        _entry('2026-07-30'),
        _entry('2026-07-29'),
        _entry('2026-07-28'),
      ], today: today);
      expect(stats.currentStreak, 3);
    });

    test('survives an unwritten today by counting back from yesterday', () {
      final stats = JournalStats.from([
        _entry('2026-07-29'),
        _entry('2026-07-28'),
      ], today: today);
      expect(stats.currentStreak, 2);
    });

    test('stops at a gap', () {
      final stats = JournalStats.from([
        _entry('2026-07-30'),
        _entry('2026-07-29'),
        _entry('2026-07-27'),
      ], today: today);
      expect(stats.currentStreak, 2);
    });

    test('is zero when the most recent entry is older than yesterday', () {
      final stats = JournalStats.from([_entry('2026-07-20')], today: today);
      expect(stats.currentStreak, 0);
    });
  });

  group('longest streak', () {
    test('finds the longest run anywhere in history', () {
      final stats = JournalStats.from([
        _entry('2026-06-01'),
        _entry('2026-06-02'),
        _entry('2026-06-03'),
        _entry('2026-06-04'),

        _entry('2026-07-29'),
        _entry('2026-07-30'),
      ], today: today);
      expect(stats.longestStreak, 4);
      expect(stats.currentStreak, 2);
    });

    test('is one for a single entry', () {
      final stats = JournalStats.from([_entry('2026-07-30')], today: today);
      expect(stats.longestStreak, 1);
    });

    test('handles a month boundary as consecutive', () {
      final stats = JournalStats.from([
        _entry('2026-06-30'),
        _entry('2026-07-01'),
      ], today: today);
      expect(stats.longestStreak, 2);
    });

    test('handles a leap-year boundary as consecutive', () {
      final stats = JournalStats.from([
        _entry('2024-02-28'),
        _entry('2024-02-29'),
        _entry('2024-03-01'),
      ], today: DateTime(2024, 3, 1));
      expect(stats.longestStreak, 3);
    });
  });

  group('counts', () {
    test('month and year totals only include the current period', () {
      final stats = JournalStats.from([
        _entry('2026-07-30'),
        _entry('2026-07-01'),
        _entry('2026-06-30'),
        _entry('2025-07-30'),
      ], today: today);
      expect(stats.total, 4);
      expect(stats.thisMonth, 2);
      expect(stats.thisYear, 3);
      expect(stats.firstEntryDate, '2025-07-30');
    });
  });

  group('heatmap', () {
    test('returns 84 cells ending today, oldest first', () {
      final heat = JournalStats.heatmap([_entry('2026-07-30')], today: today);
      expect(heat.length, 84);
      expect(heat.last, isTrue, reason: 'the final cell is today');
      expect(heat.take(83).every((v) => v == false), isTrue);
    });

    test('marks the correct offset for an older entry', () {
      final heat = JournalStats.heatmap([_entry('2026-07-24')], today: today);
      expect(heat[84 - 1 - 6], isTrue);
    });
  });

  group('date keys', () {
    test('round-trip through parse and format', () {
      expect(JournalEntry.dateKey(DateTime(2026, 7, 5)), '2026-07-05');
      expect(JournalEntry.parseDateKey('2026-07-05'), DateTime(2026, 7, 5));
    });

    test('daysBetween is signed and DST-safe across a month', () {
      expect(JournalEntry.daysBetween('2026-03-28', '2026-03-29'), 1);
      expect(JournalEntry.daysBetween('2026-07-30', '2026-07-29'), -1);
      expect(JournalEntry.daysBetween('2026-06-30', '2026-07-01'), 1);
    });
  });
}
