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
import '../../widgets/still_scaffold.dart';
import '../../widgets/still_tab_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const prompt = 'What are you grateful for today?';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.still;
    final t = context.type;

    final todayKey = ref.watch(todayKeyProvider);
    final today = ref.watch(todayEntryProvider);
    final stats = ref.watch(statsProvider);
    final entries = ref.watch(entryListProvider);

    final earlier = entries.where((e) => e.date != todayKey).take(5).toList();

    return StillScaffold(
      tab: StillTab.home,
      onSelectTab: (tab) => goToTab(context, tab),
      topPadding: 22,
      child: StillUp(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StillLabel(StillDates.longDay(DateTime.now())),
            const SizedBox(height: 10),
            Text(
              StillDates.greeting(DateTime.now()),
              style: t.greeting.copyWith(color: c.ink),
            ),
            const SizedBox(height: 24),

            if (today != null)
              _TodayCard(entry: today)
            else
              _PromptCard(dateKey: todayKey),

            const SizedBox(height: 16),
            _StatStrip(
              streak: stats.currentStreak,
              thisMonth: stats.thisMonth,
              total: stats.total,
            ),

            if (earlier.isNotEmpty) ...[
              const SizedBox(height: 30),
              const StillLabel('Earlier'),
              const SizedBox(height: 8),
              for (final entry in earlier) _EarlierRow(entry: entry),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;

    return StillCard(
      onTap: () => context.push(Routes.entry(entry.date)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: StillLabel(
                  "Today's entry",
                  style: StillLabelStyle.eyebrow,
                  color: c.clay,
                ),
              ),
              Text(
                'edited ${StillDates.timeOfDay(entry.updatedAt)}',
                style: t.caption.copyWith(color: c.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry.title.trim().isEmpty ? 'Today' : entry.title,
            style: t.entryTitleSerif.copyWith(color: c.ink),
          ),
          const SizedBox(height: 6),
          Text(
            entry.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: t.entryBody.copyWith(color: c.soft),
          ),
          const SizedBox(height: 16),
          Text('Continue writing', style: t.bodySmall.copyWith(color: c.clay)),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.dateKey});

  final String dateKey;

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;

    return StillCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(HomeScreen.prompt, style: t.prompt.copyWith(color: c.ink)),
          const SizedBox(height: 20),
          SizedBox(
            height: StillMetrics.cardButtonHeight,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.clay,
                foregroundColor: c.onClay,
                minimumSize: const Size.fromHeight(
                  StillMetrics.cardButtonHeight,
                ),
                shape: const StadiumBorder(),
                textStyle: t.button,
                elevation: 0,
              ),
              onPressed: () => context.push(Routes.entry(dateKey)),
              child: const Text("Write today's entry"),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({
    required this.streak,
    required this.thisMonth,
    required this.total,
  });

  final int streak;
  final int thisMonth;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;

    final cells = [
      ('$streak', 'Day streak'),
      ('$thisMonth', 'This month'),
      ('$total', 'Entries'),
    ];

    return StillCard(
      radius: StillRadius.group,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      shadow: false,
      onTap: () => context.push(Routes.stats),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : Border(left: BorderSide(color: c.line)),
                ),
                child: Column(
                  children: [
                    Text(
                      cells[i].$1,
                      style: t.statValueLarge.copyWith(color: c.ink),
                    ),
                    const SizedBox(height: 7),

                    StillLabel(cells[i].$2, style: StillLabelStyle.micro),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EarlierRow extends StatelessWidget {
  const _EarlierRow({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;
    final date = entry.dateTime;

    return InkWell(
      onTap: () => context.push(Routes.entry(entry.date)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 2),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  StillLabel(
                    StillDates.monthAbbrev(date),
                    style: StillLabelStyle.micro,
                  ),
                  Text(
                    '${date.day}',
                    style: t.dayNumeral.copyWith(color: c.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title.trim().isEmpty
                        ? StillDates.weekday(date)
                        : entry.title,
                    style: t.listTitle.copyWith(color: c.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.snippet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.snippet.copyWith(color: c.soft),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
