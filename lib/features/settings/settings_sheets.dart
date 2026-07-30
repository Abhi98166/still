import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/still_theme.dart';
import '../../core/theme/tokens.dart';
import '../../models/journal_entry.dart';
import '../../services/export_service.dart';

Future<T?> _showStillSheet<T>({
  required BuildContext context,
  required String title,
  required String body,
  required List<Widget> Function(BuildContext sheetContext) options,
}) {
  final c = context.still;
  final t = context.type;

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: c.card,
    barrierColor: const Color(0xFF181411).withValues(alpha: 0.35),
    isScrollControlled: true,

    transitionAnimationController: null,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 22,
          bottom: 44 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(title, style: t.sheetTitle.copyWith(color: c.ink)),
            const SizedBox(height: 6),
            Text(body, style: t.bodySmall.copyWith(color: c.soft, height: 1.5)),
            const SizedBox(height: 18),
            ...options(sheetContext),
            const SizedBox(height: 14),
            SizedBox(
              height: StillMetrics.cardButtonHeight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: c.claySoft,
                  foregroundColor: c.clay,
                  minimumSize: const Size.fromHeight(
                    StillMetrics.cardButtonHeight,
                  ),
                  shape: const StadiumBorder(),
                  textStyle: t.button,
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _sheetOption(
  BuildContext context, {
  required String label,
  required VoidCallback onTap,
}) {
  final c = context.still;
  final t = context.type;

  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: SizedBox(
      height: StillMetrics.cardButtonHeight,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          side: BorderSide(color: c.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StillRadius.option),
          ),
          foregroundColor: c.ink,
          textStyle: t.settingsRow,
        ),
        onPressed: onTap,
        child: Align(alignment: Alignment.centerLeft, child: Text(label)),
      ),
    ),
  );
}

Future<void> showExportSheet(
  BuildContext context,
  WidgetRef ref,
  int entryCount,
) {
  return _showStillSheet<void>(
    context: context,
    title: 'Export $entryCount ${entryCount == 1 ? 'entry' : 'entries'}',
    body:
        'Shared through the system share sheet. Nothing leaves your device '
        'unless you send it.',
    options: (sheetContext) => [
      for (final format in ExportFormat.values)
        _sheetOption(
          sheetContext,
          label: format.label,
          onTap: () async {
            Navigator.of(sheetContext).pop();
            final entries = ref.read(entryListProvider);
            try {
              await ExportService().share(entries, format);
            } catch (e) {
              if (context.mounted) {
                _notify(context, 'Could not export: $e');
              }
            }
          },
        ),
    ],
  );
}

Future<void> showImportSheet(BuildContext context, WidgetRef ref) {
  return _showStillSheet<void>(
    context: context,
    title: 'Import entries',
    body:
        'Choose a JSON file you exported before. Existing days are kept — you '
        'will be asked before anything is replaced.',
    options: (sheetContext) => [
      _sheetOption(
        sheetContext,
        label: 'Choose a file…',
        onTap: () async {
          Navigator.of(sheetContext).pop();
          await _runImport(context, ref);
        },
      ),
    ],
  );
}

Future<void> _runImport(BuildContext context, WidgetRef ref) async {
  final List<JournalEntry>? parsed;
  try {
    parsed = await ImportService().pickAndParse();
  } on ImportException catch (e) {
    if (context.mounted) _notify(context, e.message);
    return;
  } catch (e) {
    if (context.mounted) _notify(context, 'Could not read that file.');
    return;
  }

  if (parsed == null) return;

  final repo = ref.read(journalRepositoryProvider);
  final outcome = await repo.mergeImport(parsed);
  if (!context.mounted) return;

  if (!outcome.hasConflicts) {
    _notify(
      context,
      outcome.imported == 0
          ? 'Nothing new to import.'
          : 'Imported ${outcome.imported} '
                '${outcome.imported == 1 ? 'entry' : 'entries'}.',
    );
    return;
  }

  final n = outcome.conflicts.length;
  final replace = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final c = dialogContext.still;
      final t = dialogContext.type;
      return AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StillRadius.group),
        ),
        title: Text(
          'Replace $n existing ${n == 1 ? 'day' : 'days'}?',
          style: t.sheetTitle.copyWith(color: c.ink),
        ),
        content: Text(
          outcome.imported > 0
              ? 'Imported ${outcome.imported} new '
                    '${outcome.imported == 1 ? 'entry' : 'entries'}. '
                    '$n ${n == 1 ? 'day already had' : 'days already had'} an entry '
                    'and ${n == 1 ? 'was' : 'were'} left untouched.'
              : '$n ${n == 1 ? 'day in that file already has' : 'days in that file already have'} '
                    'an entry here. Nothing has been changed yet.',
          style: t.bodySmall.copyWith(color: c.soft, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep mine'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Replace', style: t.button.copyWith(color: c.clay)),
          ),
        ],
      );
    },
  );

  if (replace != true) return;

  final conflicting = outcome.conflicts.toSet();
  final replaced = await repo.overwrite(
    parsed.where((e) => conflicting.contains(e.date)).toList(),
  );
  if (context.mounted) {
    _notify(
      context,
      'Replaced $replaced ${replaced == 1 ? 'entry' : 'entries'}.',
    );
  }
}

void _notify(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
