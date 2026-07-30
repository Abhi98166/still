import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/still_dates.dart';
import '../../core/theme/still_theme.dart';
import '../../core/theme/tokens.dart';
import '../../models/journal_entry.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, required this.dateKey});

  final String dateKey;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  static const _debounce = Duration(milliseconds: 650);

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _bodyFocus = FocusNode();

  Timer? _saveTimer;
  String _saveMessage = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final existing = await ref
        .read(journalRepositoryProvider)
        .getByDate(widget.dateKey);
    if (!mounted) return;
    setState(() {
      _titleController.text = existing?.title ?? '';
      _bodyController.text = existing?.content ?? '';
      _saveMessage = existing == null ? 'New entry' : 'Saved';
      _loaded = true;
    });

    if (existing == null && mounted) {
      _bodyFocus.requestFocus();
    }
  }

  void _onChanged() {
    setState(() => _saveMessage = 'Saving…');
    _saveTimer?.cancel();
    _saveTimer = Timer(_debounce, _persist);
  }

  Future<void> _persist() async {
    await ref
        .read(journalRepositoryProvider)
        .save(
          dateKey: widget.dateKey,
          title: _titleController.text,
          content: _bodyController.text,
        );
    if (!mounted) return;
    setState(() => _saveMessage = 'Saved · just now');
  }

  Future<void> _flush() async {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      await _persist();
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;

    final date = JournalEntry.parseDateKey(widget.dateKey);
    final isToday = widget.dateKey == ref.watch(todayKeyProvider);
    final dayLabel = isToday ? 'Today' : StillDates.shortDay(date);

    final words = _bodyController.text.trim().isEmpty
        ? ''
        : '${_bodyController.text.trim().split(RegExp(r'\s+')).length} words';

    return PopScope(
      onPopInvokedWithResult: (didPop, _) => _flush(),
      child: Scaffold(
        backgroundColor: c.bg,

        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 20,
                right: 20,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                color: c.bg,
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () async {
                          await _flush();
                          if (context.mounted) Navigator.of(context).maybePop();
                        },
                        child: const Text('Done'),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(dayLabel, style: t.listTitle.copyWith(color: c.ink)),
                      const SizedBox(height: 2),
                      Text(
                        _saveMessage,
                        style: t.caption.copyWith(
                          color: c.muted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        words,
                        style: t.caption.copyWith(color: c.muted),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: !_loaded
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: StillMetrics.gutter,
                        right: StillMetrics.gutter,
                        top: 22,
                        bottom: 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _titleController,
                            onChanged: (_) => _onChanged(),
                            textCapitalization: TextCapitalization.sentences,
                            style: t.editorTitle.copyWith(color: c.ink),
                            decoration: InputDecoration(
                              hintText: 'Title (optional)',
                              hintStyle: t.editorTitle.copyWith(color: c.muted),
                              contentPadding: const EdgeInsets.only(bottom: 10),
                            ),
                          ),
                          TextField(
                            controller: _bodyController,
                            focusNode: _bodyFocus,
                            onChanged: (_) => _onChanged(),
                            maxLines: null,
                            minLines: 12,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            style: t.editorBody.copyWith(color: c.ink),
                            decoration: InputDecoration(
                              hintText: 'What are you grateful for today?',
                              hintStyle: t.editorBody.copyWith(color: c.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
