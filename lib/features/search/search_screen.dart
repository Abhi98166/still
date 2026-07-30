import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/still_dates.dart';
import '../../core/theme/still_theme.dart';
import '../../core/theme/tokens.dart';
import '../../models/journal_entry.dart';
import '../../widgets/still_card.dart';
import '../../widgets/still_tab_bar.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;

    final query = ref.watch(searchQueryProvider);
    final results =
        ref.watch(searchResultsProvider).value ?? const <JournalEntry>[];
    final hasQuery = query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 18,
              left: StillMetrics.gutter,
              right: StillMetrics.gutter,
              bottom: 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(StillRadius.field),
                    border: Border.all(color: c.line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.muted, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onChanged: (v) =>
                              ref.read(searchQueryProvider.notifier).set(v),
                          textInputAction: TextInputAction.search,
                          style: t.button.copyWith(color: c.ink),
                          decoration: InputDecoration(
                            hintText: 'Search your entries',
                            hintStyle: t.button.copyWith(color: c.muted),
                          ),
                        ),
                      ),
                      if (hasQuery)
                        IconButton(
                          onPressed: () {
                            _controller.clear();
                            ref.read(searchQueryProvider.notifier).clear();
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: c.muted,
                          ),
                          tooltip: 'Clear search',
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                StillLabel(
                  hasQuery
                      ? '${results.length} ${results.length == 1 ? 'result' : 'results'}'
                      : 'Recent entries',
                  style: StillLabelStyle.eyebrow,
                ),
              ],
            ),
          ),

          Expanded(
            child: hasQuery && results.isEmpty
                ? _EmptyState(query: query)
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      left: StillMetrics.gutter,
                      right: StillMetrics.gutter,
                      top: 4,
                      bottom: 22,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, i) => _ResultRow(entry: results[i]),
                  ),
          ),

          StillTabBar(
            active: StillTab.search,
            onSelect: (tab) => goToTab(context, tab),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;
    final date = entry.dateTime;

    return InkWell(
      onTap: () => context.push(Routes.entry(entry.date)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    entry.title.trim().isEmpty
                        ? '${StillDates.weekday(date)} entry'
                        : entry.title,
                    style: t.body.copyWith(
                      color: c.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  StillDates.dayMonthAbbrev(date),
                  style: t.caption.copyWith(color: c.muted, fontSize: 11.5),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              entry.snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.snippet.copyWith(color: c.soft, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Text(
        'Nothing yet for “${query.trim()}”.',
        textAlign: TextAlign.center,
        style: t.editorBody.copyWith(color: c.muted, height: 1.6),
      ),
    );
  }
}
