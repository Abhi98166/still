import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/still_dates.dart';
import '../models/journal_entry.dart';

enum ExportFormat {
  markdown('Markdown (.md)', 'md', 'text/markdown'),
  json('JSON (.json)', 'json', 'application/json'),
  text('Plain text (.txt)', 'txt', 'text/plain');

  const ExportFormat(this.label, this.extension, this.mimeType);

  final String label;
  final String extension;
  final String mimeType;
}

class ExportService {
  const ExportService();

  static const int schemaVersion = 1;

  String entryDocument(JournalEntry e) {
    final b = StringBuffer()
      ..writeln('---')
      ..writeln('date: ${e.date}')
      ..writeln('title: ${jsonEncode(e.title)}')
      ..writeln('created: ${e.createdAt.toIso8601String()}')
      ..writeln('updated: ${e.updatedAt.toIso8601String()}')
      ..writeln('---')
      ..writeln()
      ..writeln(e.content.trimRight());
    return b.toString();
  }

  Future<void> share(List<JournalEntry> entries, ExportFormat format) async {
    final content = serialise(entries, format);
    final dir = await getTemporaryDirectory();
    final stamp = JournalEntry.dateKey(DateTime.now());
    final file = File(p.join(dir.path, 'still-$stamp.${format.extension}'));
    await file.writeAsString(content, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: format.mimeType)],
        subject: 'still — $stamp',
      ),
    );
  }

  String serialise(List<JournalEntry> entries, ExportFormat format) {
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    return switch (format) {
      ExportFormat.markdown => _markdown(sorted),
      ExportFormat.json => _json(sorted),
      ExportFormat.text => _text(sorted),
    };
  }

  String _markdown(List<JournalEntry> entries) {
    final b = StringBuffer()
      ..writeln('# still')
      ..writeln()
      ..writeln(
        '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}, '
        'exported ${StillDates.fullDate(DateTime.now())}.',
      )
      ..writeln();

    for (final e in entries) {
      b
        ..writeln('## ${StillDates.longDay(e.dateTime)}')
        ..writeln();
      if (e.title.trim().isNotEmpty) {
        b
          ..writeln('**${e.title.trim()}**')
          ..writeln();
      }
      b
        ..writeln(e.content.trim())
        ..writeln();
    }
    return b.toString();
  }

  String _text(List<JournalEntry> entries) {
    final b = StringBuffer();
    for (final e in entries) {
      b.writeln(StillDates.longDay(e.dateTime));
      if (e.title.trim().isNotEmpty) b.writeln(e.title.trim());
      b
        ..writeln(e.content.trim())
        ..writeln()
        ..writeln('---')
        ..writeln();
    }
    return b.toString();
  }

  String _json(List<JournalEntry> entries) {
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'still',
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'entries': [
        for (final e in entries)
          {
            'id': e.id,
            'date': e.date,
            'title': e.title,
            'content': e.content,
            'createdAt': e.createdAt.millisecondsSinceEpoch,
            'updatedAt': e.updatedAt.millisecondsSinceEpoch,
          },
      ],
    });
  }
}

class ImportService {
  const ImportService();

  Future<List<JournalEntry>?> pickAndParse() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'still export', extensions: ['json']),
      ],
    );
    if (file == null) return null;

    final raw = await file.readAsString();
    return parse(raw);
  }

  List<JournalEntry> parse(String raw) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const ImportException("That file isn't valid JSON.");
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ImportException("That doesn't look like a still export.");
    }
    final list = decoded['entries'];
    if (list is! List) {
      throw const ImportException('No entries found in that file.');
    }

    final entries = <JournalEntry>[];
    for (final item in list) {
      if (item is! Map) continue;
      final date = item['date'];

      if (date is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
        continue;
      }

      final created = _millisOrNow(item['createdAt']);
      entries.add(
        JournalEntry(
          id: item['id'] is String && (item['id'] as String).isNotEmpty
              ? item['id'] as String
              : 'entry-$date',
          date: date,
          title: item['title'] is String ? item['title'] as String : '',
          content: item['content'] is String ? item['content'] as String : '',
          createdAt: created,
          updatedAt: _millis(item['updatedAt']) ?? created,
        ),
      );
    }

    if (entries.isEmpty) {
      throw const ImportException('That file contained no readable entries.');
    }
    return entries;
  }

  JournalEntry? parseEntryDocument(String raw) {
    final lines = const LineSplitter().convert(raw);
    if (lines.isEmpty || lines.first.trim() != '---') return null;

    final close = lines.indexWhere((l) => l.trim() == '---', 1);
    if (close < 0) return null;

    final fields = <String, String>{};
    for (final line in lines.getRange(1, close)) {
      final colon = line.indexOf(':');
      if (colon < 0) continue;
      fields[line.substring(0, colon).trim()] = line.substring(colon + 1).trim();
    }

    final date = fields['date'];
    if (date == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      return null;
    }

    final created = _millisOrNow(fields['created']);
    return JournalEntry(
      id: 'entry-$date',
      date: date,
      title: _unquote(fields['title']),
      content: lines.skip(close + 1).join('\n').trim(),
      createdAt: created,
      updatedAt: _millis(fields['updated']) ?? created,
    );
  }

  static String _unquote(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (!raw.startsWith('"')) return raw;
    try {
      final decoded = jsonDecode(raw);
      return decoded is String ? decoded : raw;
    } on FormatException {
      return raw;
    }
  }

  static DateTime _millisOrNow(Object? v) => _millis(v) ?? DateTime.now();

  static DateTime? _millis(Object? v) {
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

class ImportException implements Exception {
  const ImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
