import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/journal_entry.dart';
import 'backup_storage.dart';
import 'export_service.dart';

@immutable
class BackupOutcome {
  const BackupOutcome({
    required this.written,
    required this.removed,
    required this.total,
  });

  const BackupOutcome.upToDate(this.total) : written = 0, removed = 0;

  final int written;

  final int removed;

  final int total;

  bool get changed => written > 0 || removed > 0;
}

class BackupService {
  const BackupService([this._storage = const BackupStorage()]);

  final BackupStorage _storage;

  static const int formatVersion = 1;
  static const String root = 'still';
  static const String manifestPath = '$root/manifest.json';

  static String pathFor(String date) =>
      '$root/entries/${date.substring(0, 4)}/$date.md';

  Future<BackupOutcome> run({
    required String folderUri,
    required List<JournalEntry> entries,
    bool full = false,
  }) async {
    final stored = await _readManifest(folderUri);
    final baseline = full ? const <String, int>{} : stored;

    final current = <String, int>{};
    for (final e in entries) {
      current[e.date] = e.updatedAt.millisecondsSinceEpoch;
    }

    final stale = [
      for (final date in stored.keys)
        if (!current.containsKey(date)) pathFor(date),
    ];

    final export = const ExportService();
    final files = [
      for (final e in entries)
        if (baseline[e.date] != current[e.date])
          BackupFile(pathFor(e.date), export.entryDocument(e)),
    ];

    if (files.isEmpty && stale.isEmpty) {
      return BackupOutcome.upToDate(current.length);
    }

    final removed = await _storage.delete(folderUri, stale);
    final written = await _storage.write(folderUri, files);
    await _storage.write(folderUri, [
      BackupFile(manifestPath, _encodeManifest(current)),
    ]);

    return BackupOutcome(
      written: written,
      removed: removed,
      total: current.length,
    );
  }

  Future<Map<String, int>> _readManifest(String folderUri) async {
    final raw = await _storage.readText(folderUri, manifestPath);
    if (raw == null || raw.isEmpty) return const {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final entries = decoded['entries'];
      if (entries is! Map) return const {};

      return {
        for (final entry in entries.entries)
          if (entry.key is String && entry.value is int)
            entry.key as String: entry.value as int,
      };
    } on FormatException {
      return const {};
    }
  }

  String _encodeManifest(Map<String, int> entries) {
    final dates = entries.keys.toList()..sort();
    return jsonEncode({
      'app': 'still',
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'entries': {for (final date in dates) date: entries[date]},
    });
  }
}
