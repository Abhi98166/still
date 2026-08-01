import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:still/models/journal_entry.dart';
import 'package:still/services/backup_service.dart';
import 'package:still/services/backup_storage.dart';
import 'package:still/services/export_service.dart';

const _uri = 'content://tree/primary%3ADocuments';

JournalEntry _entry(String date, {String title = '', String content = 'x'}) {
  final at = DateTime.parse('${date}T09:00:00');
  return JournalEntry(
    id: 'entry-$date',
    date: date,
    title: title,
    content: content,
    createdAt: at,
    updatedAt: at,
  );
}

class _FakeStorage extends BackupStorage {
  _FakeStorage();

  final Map<String, String> files = {};
  final List<String> written = [];
  final List<String> deleted = [];

  @override
  Future<String?> readText(String uri, String path) async => files[path];

  @override
  Future<List<String>> list(String uri, String path) async {
    final prefix = path.isEmpty ? '' : '$path/';
    return files.keys.where((k) => k.startsWith(prefix)).toList()..sort();
  }

  @override
  Future<Map<String, String>> readBatch(String uri, List<String> paths) async {
    return {
      for (final path in paths)
        if (files.containsKey(path)) path: files[path]!,
    };
  }

  @override
  Future<int> write(String uri, List<BackupFile> incoming) async {
    for (final f in incoming) {
      files[f.path] = f.content;
      written.add(f.path);
    }
    return incoming.length;
  }

  @override
  Future<int> delete(String uri, List<String> paths) async {
    var removed = 0;
    for (final path in paths) {
      deleted.add(path);
      if (files.remove(path) != null) removed++;
    }
    return removed;
  }

  List<String> get entryFiles =>
      files.keys.where((k) => k != BackupService.manifestPath).toList()..sort();

  void resetLog() {
    written.clear();
    deleted.clear();
  }
}

void main() {
  group('entry document', () {
    test('round-trips through the parser', () {
      const entry = ExportService();
      final original = _entry(
        '2026-08-01',
        title: 'A morning: quiet, "still"',
        content: 'First line.\n\nSecond line with --- in it.',
      );

      final parsed = const ImportService().parseEntryDocument(
        entry.entryDocument(original),
      );

      expect(parsed, isNotNull);
      expect(parsed!.date, original.date);
      expect(parsed.title, original.title);
      expect(parsed.content, original.content);
      expect(parsed.createdAt, original.createdAt);
      expect(parsed.updatedAt, original.updatedAt);
    });

    test('rejects a file without frontmatter', () {
      expect(const ImportService().parseEntryDocument('just text'), isNull);
    });

    test('rejects frontmatter without a usable date', () {
      const raw = '---\ndate: not-a-date\n---\n\nbody';
      expect(const ImportService().parseEntryDocument(raw), isNull);
    });
  });

  group('backup service', () {
    test('files an entry under its year', () {
      expect(
        BackupService.pathFor('2026-08-01'),
        'still/entries/2026/2026-08-01.md',
      );
    });

    test('first run writes every entry and a manifest', () async {
      final storage = _FakeStorage();
      final entries = [_entry('2026-07-30'), _entry('2026-08-01')];

      final outcome = await BackupService(
        storage,
      ).run(folderUri: _uri, entries: entries);

      expect(outcome.written, 2);
      expect(outcome.total, 2);
      expect(storage.entryFiles, [
        'still/entries/2026/2026-07-30.md',
        'still/entries/2026/2026-08-01.md',
      ]);

      final manifest = jsonDecode(storage.files[BackupService.manifestPath]!);
      expect(manifest['formatVersion'], BackupService.formatVersion);
      expect((manifest['entries'] as Map).keys, ['2026-07-30', '2026-08-01']);
    });

    test('an unchanged second run writes nothing', () async {
      final storage = _FakeStorage();
      final service = BackupService(storage);
      final entries = [_entry('2026-07-30'), _entry('2026-08-01')];

      await service.run(folderUri: _uri, entries: entries);
      storage.resetLog();

      final outcome = await service.run(folderUri: _uri, entries: entries);

      expect(outcome.changed, isFalse);
      expect(outcome.total, 2);
      expect(storage.written, isEmpty);
      expect(storage.deleted, isEmpty);
    });

    test('only the edited day is rewritten', () async {
      final storage = _FakeStorage();
      final service = BackupService(storage);
      final entries = [_entry('2026-07-30'), _entry('2026-08-01')];

      await service.run(folderUri: _uri, entries: entries);
      storage.resetLog();

      final edited = [
        entries.first,
        entries.last.copyWith(
          content: 'changed',
          updatedAt: DateTime(2026, 8, 1, 21),
        ),
      ];
      final outcome = await service.run(folderUri: _uri, entries: edited);

      expect(outcome.written, 1);
      expect(storage.written, [
        'still/entries/2026/2026-08-01.md',
        BackupService.manifestPath,
      ]);
      expect(storage.files['still/entries/2026/2026-08-01.md'], contains('changed'));
    });

    test('a removed day is pruned from the folder', () async {
      final storage = _FakeStorage();
      final service = BackupService(storage);
      final entries = [_entry('2026-07-30'), _entry('2026-08-01')];

      await service.run(folderUri: _uri, entries: entries);
      storage.resetLog();

      final outcome = await service.run(
        folderUri: _uri,
        entries: [entries.first],
      );

      expect(outcome.removed, 1);
      expect(outcome.total, 1);
      expect(storage.deleted, ['still/entries/2026/2026-08-01.md']);
      expect(storage.entryFiles, ['still/entries/2026/2026-07-30.md']);
    });

    test('a full run rewrites everything even when nothing changed', () async {
      final storage = _FakeStorage();
      final service = BackupService(storage);
      final entries = [_entry('2026-07-30'), _entry('2026-08-01')];

      await service.run(folderUri: _uri, entries: entries);
      storage.resetLog();

      final outcome = await service.run(
        folderUri: _uri,
        entries: entries,
        full: true,
      );

      expect(outcome.written, 2);
      expect(storage.written.length, 3);
    });

    test('reads back everything it wrote', () async {
      final storage = _FakeStorage();
      final service = BackupService(storage);
      final entries = [
        _entry('2026-07-30', title: 'A title: with a colon'),
        _entry('2026-08-01', content: 'Two\n\nparagraphs.'),
      ];

      await service.run(folderUri: _uri, entries: entries);
      final restored = await service.readFolder(_uri);

      expect(restored.map((e) => e.date), ['2026-07-30', '2026-08-01']);
      expect(restored.first.title, 'A title: with a colon');
      expect(restored.last.content, 'Two\n\nparagraphs.');
    });

    test('restores when handed the still folder itself', () async {
      final storage = _FakeStorage()
        ..files['entries/2026/2026-08-01.md'] = const ExportService()
            .entryDocument(_entry('2026-08-01', content: 'nested one level up'));

      final restored = await BackupService(storage).readFolder(_uri);

      expect(restored.single.content, 'nested one level up');
    });

    test('restores from a bare pile of day files', () async {
      final storage = _FakeStorage()
        ..files['2026-08-01.md'] = const ExportService().entryDocument(
          _entry('2026-08-01', content: 'no folders at all'),
        );

      final restored = await BackupService(storage).readFolder(_uri);

      expect(restored.single.content, 'no folders at all');
    });

    test('skips files that are not still entries', () async {
      final storage = _FakeStorage()
        ..files['still/entries/2026/2026-08-01.md'] = const ExportService()
            .entryDocument(_entry('2026-08-01'))
        ..files['still/entries/2026/notes.md'] = 'just some markdown'
        ..files['still/entries/2026/photo.png'] = 'binary';

      final restored = await BackupService(storage).readFolder(_uri);

      expect(restored.single.date, '2026-08-01');
    });

    test('keeps the newest copy when a day appears twice', () async {
      final older = _entry('2026-08-01', content: 'older');
      final newer = older.copyWith(
        content: 'newer',
        updatedAt: DateTime(2026, 8, 1, 22),
      );

      final storage = _FakeStorage()
        ..files['still/entries/2026/2026-08-01.md'] = const ExportService()
            .entryDocument(older)
        ..files['still/entries/2026/2026-08-01 (1).md'] = const ExportService()
            .entryDocument(newer);

      final restored = await BackupService(storage).readFolder(_uri);

      expect(restored.single.content, 'newer');
    });

    test('an empty folder restores nothing rather than failing', () async {
      final restored = await BackupService(_FakeStorage()).readFolder(_uri);
      expect(restored, isEmpty);
    });

    test('a corrupt manifest falls back to a full write', () async {
      final storage = _FakeStorage()
        ..files[BackupService.manifestPath] = 'not json';

      final outcome = await BackupService(
        storage,
      ).run(folderUri: _uri, entries: [_entry('2026-08-01')]);

      expect(outcome.written, 1);
    });
  });
}
