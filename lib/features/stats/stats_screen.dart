import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/still_dates.dart';
import '../../core/theme/still_theme.dart';
import '../../core/theme/tokens.dart';
import '../../models/journal_entry.dart';
import '../../widgets/still_card.dart';
import '../../widgets/still_scaffold.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.still;
    final t = context.type;

    final stats = ref.watch(statsProvider);
    final heat = ref.watch(heatmapProvider);

    final since = stats.firstEntryDate == null
        ? null
        : StillDates.fullDate(JournalEntry.parseDateKey(stats.firstEntryDate!));

    return Scaffold(
      backgroundColor: c.bg,
      body: StillUp(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: StillMetrics.gutter,
            right: StillMetrics.gutter,
            top: MediaQuery.paddingOf(context).top + 12,
            bottom: MediaQuery.paddingOf(context).bottom + 30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('← Home'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your practice',
                style: t.screenTitle.copyWith(color: c.ink),
              ),
              const SizedBox(height: 6),
              Text(
                since == null
                    ? 'No entries yet.'
                    : '${stats.total} ${stats.total == 1 ? 'entry' : 'entries'} since $since',
                style: t.body.copyWith(color: c.soft),
              ),
              const SizedBox(height: 24),

              StillCard(
                shadow: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StillLabel(
                      'Last 12 weeks',
                      style: StillLabelStyle.group,
                    ),
                    const SizedBox(height: 14),
                    _Heatmap(days: heat),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              StillGroup(
                radius: StillRadius.card,
                children: [
                  _StatRow(label: 'Total entries', value: '${stats.total}'),
                  _StatRow(
                    label: 'Current streak',
                    value:
                        '${stats.currentStreak} '
                        '${stats.currentStreak == 1 ? 'day' : 'days'}',
                  ),
                  _StatRow(
                    label: 'Longest streak',
                    value:
                        '${stats.longestStreak} '
                        '${stats.longestStreak == 1 ? 'day' : 'days'}',
                  ),
                  _StatRow(
                    label: 'Entries this month',
                    value: '${stats.thisMonth}',
                  ),
                  _StatRow(
                    label: 'Entries this year',
                    value: '${stats.thisYear}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.days});

  final List<bool> days;

  @override
  Widget build(BuildContext context) {
    final c = context.still;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 12,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemCount: days.length,
      itemBuilder: (context, i) => DecoratedBox(
        decoration: BoxDecoration(
          color: days[i] ? c.clay : c.claySoft,
          borderRadius: BorderRadius.circular(StillRadius.heat),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(label, style: t.listTitle.copyWith(color: c.soft)),
          ),
          Text(value, style: t.statValue.copyWith(color: c.ink)),
        ],
      ),
    );
  }
}
