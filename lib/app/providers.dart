import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../models/app_settings.dart';
import '../models/journal_entry.dart';
import '../models/journal_stats.dart';
import '../repositories/journal_repository.dart';
import '../services/backup_service.dart';
import '../services/backup_storage.dart';
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

final backupStorageProvider = Provider<BackupStorage>(
  (ref) => const BackupStorage(),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(backupStorageProvider)),
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

  Future<void> setBackupFolder(BackupFolder folder) async {
    state = state.copyWith(
      backupEnabled: true,
      backupFolderUri: folder.uri,
      backupFolderName: folder.name,
    );
    await _prefs.setBackupFolder(folder.uri, folder.name);
  }

  Future<void> markBackupRun(DateTime at) async {
    state = state.copyWith(backupLastRunAt: at);
    await _prefs.setBackupLastRun(at);
  }

  Future<void> clearBackup() async {
    state = state.withoutBackup();
    await _prefs.clearBackup();
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

enum BackupPhase { idle, running, done, failed }

@immutable
class BackupState {
  const BackupState({this.phase = BackupPhase.idle, this.message});

  final BackupPhase phase;

  final String? message;

  bool get isRunning => phase == BackupPhase.running;
}

class BackupController extends Notifier<BackupState> {
  static const Duration _settleDelay = Duration(seconds: 4);

  Timer? _debounce;
  String? _signature;
  bool _rerun = false;

  @override
  BackupState build() {
    ref.keepAlive();
    ref.onDispose(() => _debounce?.cancel());

    ref.listen<List<JournalEntry>>(entryListProvider, (_, next) {
      if (!ref.read(settingsProvider).backupReady) return;
      _debounce?.cancel();
      _debounce = Timer(_settleDelay, () => unawaited(run(silent: true)));
    });

    return const BackupState();
  }

  Future<void> chooseFolder() async {
    try {
      final folder = await ref.read(backupStorageProvider).pickFolder();
      if (folder == null) return;

      await ref.read(settingsProvider.notifier).setBackupFolder(folder);
      _signature = null;
      await run(full: true);
    } on BackupStorageException catch (e) {
      state = BackupState(phase: BackupPhase.failed, message: e.message);
    }
  }

  Future<void> disable() async {
    final uri = ref.read(settingsProvider).backupFolderUri;

    _debounce?.cancel();
    _signature = null;
    _rerun = false;
    state = const BackupState();
    await ref.read(settingsProvider.notifier).clearBackup();

    if (uri == null) return;
    try {
      await ref.read(backupStorageProvider).release(uri);
    } on BackupStorageException {
      return;
    }
  }

  void onAppLifecycle() => unawaited(run(silent: true));

  Future<void> run({bool full = false, bool silent = false}) async {
    final settings = ref.read(settingsProvider);
    final uri = settings.backupFolderUri;
    if (!settings.backupEnabled || uri == null) return;

    if (state.isRunning) {
      _rerun = true;
      return;
    }

    // An unresolved stream reads as an empty journal, which would prune every
    // file in the backup folder. Wait for the real rows instead.
    final loaded = ref.read(entriesProvider);
    if (!loaded.hasValue) return;

    final entries = loaded.requireValue;
    final signature = _signatureOf(entries);
    if (silent && !full && signature == _signature) return;

    _debounce?.cancel();
    state = const BackupState(phase: BackupPhase.running);

    try {
      if (!await ref.read(backupStorageProvider).hasAccess(uri)) {
        state = const BackupState(
          phase: BackupPhase.failed,
          message: 'still no longer has access to that folder. Choose it again.',
        );
        return;
      }

      final outcome = await ref
          .read(backupServiceProvider)
          .run(folderUri: uri, entries: entries, full: full);

      _signature = signature;
      await ref.read(settingsProvider.notifier).markBackupRun(DateTime.now());
      state = BackupState(phase: BackupPhase.done, message: _summary(outcome));
    } on BackupStorageException catch (e) {
      state = BackupState(phase: BackupPhase.failed, message: e.message);
    } catch (e) {
      state = const BackupState(
        phase: BackupPhase.failed,
        message: 'Could not write to the backup folder.',
      );
    } finally {
      if (_rerun) {
        _rerun = false;
        unawaited(run(silent: true));
      }
    }
  }

  static String _signatureOf(List<JournalEntry> entries) {
    var newest = 0;
    for (final e in entries) {
      final updated = e.updatedAt.millisecondsSinceEpoch;
      if (updated > newest) newest = updated;
    }
    return '${entries.length}:$newest';
  }

  static String _summary(BackupOutcome outcome) {
    if (!outcome.changed) return 'Already up to date.';

    final written = outcome.written;
    final removed = outcome.removed;
    final parts = <String>[
      if (written > 0) 'backed up $written ${written == 1 ? 'entry' : 'entries'}',
      if (removed > 0) 'removed $removed ${removed == 1 ? 'file' : 'files'}',
    ];
    final sentence = parts.join(', ');
    return '${sentence[0].toUpperCase()}${sentence.substring(1)}.';
  }
}

final backupControllerProvider =
    NotifierProvider<BackupController, BackupState>(BackupController.new);

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
