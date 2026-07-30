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

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.still;
    final t = context.type;

    final month = ref.watch(visibleMonthProvider);
    final byDate = ref.watch(entriesByDateProvider);
    final todayKey = ref.watch(todayKeyProvider);

    final monthPrefix =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
    final monthEntries =
        byDate.entries
            .where((e) => e.key.startsWith(monthPrefix))
            .map((e) => e.value)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return StillScaffold(
      tab: StillTab.calendar,
      onSelectTab: (tab) => goToTab(context, tab),
      child: StillUp(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    StillDates.monthYear(month),
                    style: t.monthLabel.copyWith(color: c.ink),
                  ),
                ),
                _RoundButton(
                  glyph: '←',
                  semanticLabel: 'Previous month',
                  onTap: () =>
                      ref.read(visibleMonthProvider.notifier).previous(),
                ),
                const SizedBox(width: 8),
                _RoundButton(
                  glyph: '→',
                  semanticLabel: 'Next month',
                  onTap: () => ref.read(visibleMonthProvider.notifier).next(),
                ),
              ],
            ),
            const SizedBox(height: 22),

            Row(
              children: [
                for (final d in StillDates.weekdayInitials)
                  Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: t.microLabel.copyWith(
                          color: c.muted,
                          letterSpacing: 0.08 * 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            _MonthGrid(month: month, byDate: byDate, todayKey: todayKey),

            const SizedBox(height: 26),
            StillLabel(
              '${monthEntries.length} '
              '${monthEntries.length == 1 ? 'entry' : 'entries'} this month',
            ),
            const SizedBox(height: 10),

            for (final entry in monthEntries) _MonthEntryRow(entry: entry),

            const SizedBox(height: 18),
            Center(
              child: Text(
                'Tap a past day to read or write on it.',
                style: t.caption.copyWith(color: c.muted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.byDate,
    required this.todayKey,
  });

  final DateTime month;
  final Map<String, JournalEntry> byDate;
  final String todayKey;

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;

    final lead = StillDates.leadingBlanks(month);
    final days = StillDates.daysInMonth(month);
    final today = JournalEntry.parseDateKey(todayKey);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: lead + days,
      itemBuilder: (context, index) {
        if (index < lead) return const SizedBox.shrink();

        final day = index - lead + 1;
        final date = DateTime(month.year, month.month, day);
        final key = JournalEntry.dateKey(date);
        final hasEntry = byDate.containsKey(key);
        final isToday = key == todayKey;
        final isFuture = date.isAfter(today);

        return Semantics(
          label:
              '$day ${StillDates.monthYear(month)}'
              '${hasEntry ? ', has an entry' : ''}'
              '${isToday ? ', today' : ''}',
          button: !isFuture,
          child: InkWell(
            onTap: isFuture ? null : () => context.push(Routes.entry(key)),
            onLongPress: isFuture
                ? null
                : () => context.push(Routes.entry(key)),
            borderRadius: BorderRadius.circular(StillRadius.cell),
            child: Container(
              decoration: BoxDecoration(
                color: hasEntry ? c.claySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(StillRadius.cell),
                border: Border.all(
                  color: isToday ? c.clay : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: t.body.copyWith(
                      color: isFuture ? c.muted : c.ink,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: hasEntry ? c.clay : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MonthEntryRow extends StatelessWidget {
  const _MonthEntryRow({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;

    return InkWell(
      onTap: () => context.push(Routes.entry(entry.date)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 2),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '${entry.dateTime.day}',
                style: t.entryTitleSerif.copyWith(color: c.ink, fontSize: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                entry.snippet,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.snippet.copyWith(color: c.soft, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.glyph,
    required this.onTap,
    required this.semanticLabel,
  });

  final String glyph;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: c.card,
            shape: BoxShape.circle,
            border: Border.all(color: c.line),
          ),
          child: Center(
            child: Text(
              glyph,
              style: t.button.copyWith(color: c.soft, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}
