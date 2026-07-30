import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../models/app_settings.dart';
import '../models/journal_entry.dart';
import '../models/journal_stats.dart';
import '../repositories/journal_repository.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';

final preferencesServiceProvider = Provider<PreferencesService>(
  (ref) =>
      throw UnimplementedError('preferencesServiceProvider must be overridden'),
);

final databaseProvider = Provider<StillDatabase>((ref) {
  final db = StillDatabase();
  ref.onDispose(db.close);
  return db;
});

final journalRepositoryProvider = Provider<JournalRepository>(
  (ref) => JournalRepository(ref.watch(databaseProvider)),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(preferencesServiceProvider).load();

  PreferencesService get _prefs => ref.read(preferencesServiceProvider);

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setThemeMode(mode);
  }

  Future<void> setAccent(String accentId) async {
    state = state.copyWith(accentId: accentId);
    await _prefs.setAccentId(accentId);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(hasOnboarded: true);
    await _prefs.setOnboarded(true);
  }

  Future<void> setReminderEnabled(bool value) async {
    state = state.copyWith(reminderEnabled: value);
    await _prefs.setReminderEnabled(value);
  }

  Future<void> setReminderTime(String id) async {
    state = state.copyWith(reminderTimeId: id, reminderEnabled: true);
    await _prefs.setReminderTimeId(id);
    await _prefs.setReminderEnabled(true);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

final entriesProvider = StreamProvider<List<JournalEntry>>(
  (ref) => ref.watch(journalRepositoryProvider).watchAll(),
);

final entryListProvider = Provider<List<JournalEntry>>(
  (ref) => ref.watch(entriesProvider).value ?? const [],
);

final entriesByDateProvider = Provider<Map<String, JournalEntry>>((ref) {
  return {for (final e in ref.watch(entryListProvider)) e.date: e};
});

final todayKeyProvider = Provider<String>((ref) => JournalEntry.todayKey());

final todayEntryProvider = Provider<JournalEntry?>(
  (ref) => ref.watch(entriesByDateProvider)[ref.watch(todayKeyProvider)],
);

final statsProvider = Provider<JournalStats>(
  (ref) => JournalStats.from(ref.watch(entryListProvider)),
);

final heatmapProvider = Provider<List<bool>>(
  (ref) => JournalStats.heatmap(ref.watch(entryListProvider)),
);

final searchQueryProvider = NotifierProvider<SearchQueryController, String>(
  SearchQueryController.new,
);

class SearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;

  void clear() => state = '';
}

final searchResultsProvider = StreamProvider<List<JournalEntry>>((ref) {
  final query = ref.watch(searchQueryProvider);
  return ref.watch(journalRepositoryProvider).watchSearch(query);
});

final visibleMonthProvider = NotifierProvider<VisibleMonthController, DateTime>(
  VisibleMonthController.new,
);

class VisibleMonthController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previous() => state = DateTime(state.year, state.month - 1);

  void next() => state = DateTime(state.year, state.month + 1);

  void jumpTo(DateTime month) => state = DateTime(month.year, month.month);
}
