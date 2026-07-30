import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable;

import '../database/database.dart';
import '../models/journal_entry.dart';

class JournalRepository {
  JournalRepository(this._db);

  final StillDatabase _db;

  Stream<List<JournalEntry>> watchAll() {
    final q = _db.select(_db.journalEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    return q.watch().map((rows) => rows.map(_toModel).toList());
  }

  Future<List<JournalEntry>> getAll() async {
    final q = _db.select(_db.journalEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    return (await q.get()).map(_toModel).toList();
  }

  Stream<JournalEntry?> watchByDate(String dateKey) {
    final q = _db.select(_db.journalEntries)
      ..where((t) => t.date.equals(dateKey))
      ..limit(1);
    return q.watchSingleOrNull().map((r) => r == null ? null : _toModel(r));
  }

  Future<JournalEntry?> getByDate(String dateKey) async {
    final q = _db.select(_db.journalEntries)
      ..where((t) => t.date.equals(dateKey))
      ..limit(1);
    final row = await q.getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Stream<List<JournalEntry>> watchSearch(
    String query, {
    int emptyQueryLimit = 8,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      final q = _db.select(_db.journalEntries)
        ..orderBy([(t) => OrderingTerm.desc(t.date)])
        ..limit(emptyQueryLimit);
      return q.watch().map((rows) => rows.map(_toModel).toList());
    }

    final pattern = '%${_escapeLike(trimmed.toLowerCase())}%';
    final q = _db.select(_db.journalEntries)
      ..where(
        (t) => t.title.lower().like(pattern) | t.content.lower().like(pattern),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    return q.watch().map((rows) => rows.map(_toModel).toList());
  }

  Future<void> save({
    required String dateKey,
    required String title,
    required String content,
  }) async {
    if (title.trim().isEmpty && content.trim().isEmpty) {
      await deleteByDate(dateKey);
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await getByDate(dateKey);

    if (existing == null) {
      await _db
          .into(_db.journalEntries)
          .insert(
            JournalEntryRow(
              id: _idFor(dateKey),
              date: dateKey,
              title: title,
              content: content,
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (_db.update(
        _db.journalEntries,
      )..where((t) => t.date.equals(dateKey))).write(
        JournalEntriesCompanion(
          title: Value(title),
          content: Value(content),
          updatedAt: Value(now),
        ),
      );
    }
  }

  Future<void> deleteByDate(String dateKey) async {
    await (_db.delete(
      _db.journalEntries,
    )..where((t) => t.date.equals(dateKey))).go();
  }

  Future<ImportOutcome> mergeImport(List<JournalEntry> incoming) async {
    final existing = (await getAll()).map((e) => e.date).toSet();
    final toInsert = incoming.where((e) => !existing.contains(e.date)).toList();
    final conflicts = incoming
        .where((e) => existing.contains(e.date))
        .map((e) => e.date)
        .toList();

    if (toInsert.isNotEmpty) {
      await _db.batch((b) {
        b.insertAll(
          _db.journalEntries,
          toInsert.map(
            (e) => JournalEntryRow(
              id: e.id.isEmpty ? _idFor(e.date) : e.id,
              date: e.date,
              title: e.title,
              content: e.content,
              createdAt: e.createdAt.millisecondsSinceEpoch,
              updatedAt: e.updatedAt.millisecondsSinceEpoch,
            ),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      });
    }

    return ImportOutcome(imported: toInsert.length, conflicts: conflicts);
  }

  Future<int> overwrite(List<JournalEntry> incoming) async {
    if (incoming.isEmpty) return 0;
    await _db.batch((b) {
      for (final e in incoming) {
        b.insert(
          _db.journalEntries,
          JournalEntryRow(
            id: e.id.isEmpty ? _idFor(e.date) : e.id,
            date: e.date,
            title: e.title,
            content: e.content,
            createdAt: e.createdAt.millisecondsSinceEpoch,
            updatedAt: e.updatedAt.millisecondsSinceEpoch,
          ),
          onConflict: DoUpdate(
            (_) => JournalEntriesCompanion(
              title: Value(e.title),
              content: Value(e.content),
              updatedAt: Value(e.updatedAt.millisecondsSinceEpoch),
            ),
            target: [_db.journalEntries.date],
          ),
        );
      }
    });
    return incoming.length;
  }

  static String _idFor(String dateKey) => 'entry-$dateKey';

  static String _escapeLike(String input) => input
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');

  static JournalEntry _toModel(JournalEntryRow r) => JournalEntry(
    id: r.id,
    date: r.date,
    title: r.title,
    content: r.content,
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
  );
}

@immutable
class ImportOutcome {
  const ImportOutcome({required this.imported, required this.conflicts});

  final int imported;

  final List<String> conflicts;

  bool get hasConflicts => conflicts.isNotEmpty;
}
