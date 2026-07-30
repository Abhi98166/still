import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DataClassName('JournalEntryRow')
class JournalEntries extends Table {
  TextColumn get id => text()();

  TextColumn get date => text()();

  TextColumn get title => text().withDefault(const Constant(''))();

  TextColumn get content => text().withDefault(const Constant(''))();

  IntColumn get createdAt => integer().named('created_at')();

  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE(date)'];
}

@DriftDatabase(tables: [JournalEntries])
class StillDatabase extends _$StillDatabase {
  StillDatabase() : super(_open());

  StillDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onCreate: (m) async {
      await m.createAll();

      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_entries_title ON journal_entries (title)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_entries_content ON journal_entries (content)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_entries_date_desc ON journal_entries (date DESC)',
      );
    },
  );

  static QueryExecutor _open() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'still.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
