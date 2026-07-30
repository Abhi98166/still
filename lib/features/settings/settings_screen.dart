import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/theme/accents.dart';
import '../../core/theme/still_theme.dart';
import '../../core/theme/tokens.dart';
import '../../models/app_settings.dart';
import '../../widgets/still_card.dart';
import '../../widgets/still_scaffold.dart';
import '../../widgets/still_tab_bar.dart';
import 'settings_sheets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.still;
    final t = context.type;

    final settings = ref.watch(settingsProvider);
    final entryCount = ref.watch(entryListProvider).length;

    return StillScaffold(
      tab: StillTab.settings,
      onSelectTab: (tab) => goToTab(context, tab),
      child: StillUp(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: t.screenTitle.copyWith(color: c.ink)),

            const SizedBox(height: 24),
            const StillLabel('Appearance', style: StillLabelStyle.group),
            const SizedBox(height: 10),
            _ThemeSegments(current: settings.themeMode),

            const SizedBox(height: 18),
            const StillLabel('Accent', style: StillLabelStyle.group),
            const SizedBox(height: 10),
            _AccentRow(currentId: settings.accentId),

            const SizedBox(height: 26),
            const StillLabel('Reminder', style: StillLabelStyle.group),
            const SizedBox(height: 10),
            _ReminderGroup(settings: settings),

            const SizedBox(height: 26),
            const StillLabel('Your data', style: StillLabelStyle.group),
            const SizedBox(height: 10),
            StillGroup(
              children: [
                _DataRow(
                  label: 'Export entries',
                  trailing: 'Markdown · JSON · TXT',
                  onTap: entryCount == 0
                      ? null
                      : () => showExportSheet(context, ref, entryCount),
                ),
                _DataRow(
                  label: 'Import from JSON',
                  trailing: 'Merge, never overwrite',
                  onTap: () => showImportSheet(context, ref),
                ),
              ],
            ),

            const SizedBox(height: 26),
            Center(
              child: Text(
                'still 1.0 · $entryCount '
                '${entryCount == 1 ? 'entry' : 'entries'} on this device\n'
                'No account. No analytics. No cloud.',
                textAlign: TextAlign.center,
                style: t.caption.copyWith(color: c.muted, height: 1.7),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ThemeSegments extends ConsumerWidget {
  const _ThemeSegments({required this.current});

  final ThemeMode current;

  static const _labels = {
    ThemeMode.system: 'System',
    ThemeMode.light: 'Light',
    ThemeMode.dark: 'Dark',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.still;
    final t = context.type;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(StillRadius.field),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          for (final mode in ThemeMode.values)
            Expanded(
              child: Semantics(
                selected: mode == current,
                button: true,
                child: GestureDetector(
                  onTap: () =>
                      ref.read(settingsProvider.notifier).setThemeMode(mode),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: StillMotion.themeSwap,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: mode == current ? c.claySoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _labels[mode]!,
                      style: t.body.copyWith(
                        color: mode == current ? c.clay : c.soft,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccentRow extends ConsumerWidget {
  const _AccentRow({required this.currentId});

  final String currentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.still;
    final isDark = context.isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(StillRadius.field),
        border: Border.all(color: c.line),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final accent in AccentRegistry.all)
            Semantics(
              selected: accent.id == currentId,
              button: true,
              label: accent.label,
              child: GestureDetector(
                onTap: () =>
                    ref.read(settingsProvider.notifier).setAccent(accent.id),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: StillMotion.themeSwap,
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.id == currentId
                              ? c.clay
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.resolve(isDark),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    StillLabel(
                      accent.label,
                      style: StillLabelStyle.micro,
                      color: accent.id == currentId ? c.ink : c.muted,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReminderGroup extends ConsumerWidget {
  const _ReminderGroup({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.still;
    final t = context.type;

    return StillGroup(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily nudge',
                      style: t.settingsRow.copyWith(color: c.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'On this device only',
                      style: t.caption.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: settings.reminderEnabled,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setReminderEnabled(v),
              ),
            ],
          ),
        ),

        AnimatedOpacity(
          duration: StillMotion.themeSwap,
          opacity: settings.reminderEnabled ? 1 : 0.4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Time',
                    style: t.settingsRow.copyWith(color: c.ink),
                  ),
                ),
                for (final slot in ReminderSlot.all)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _TimeChip(
                      slot: slot,
                      selected: slot.id == settings.reminderTimeId,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeChip extends ConsumerWidget {
  const _TimeChip({required this.slot, required this.selected});

  final ReminderSlot slot;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.still;
    final t = context.type;

    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: () =>
            ref.read(settingsProvider.notifier).setReminderTime(slot.id),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? c.claySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(StillRadius.chip),
            border: Border.all(color: selected ? c.clay : c.line),
          ),
          child: Text(
            slot.label,
            style: t.chip.copyWith(color: selected ? c.clay : c.soft),
          ),
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.trailing, this.onTap});

  final String label;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: t.settingsRow.copyWith(color: c.ink)),
              ),
              Text(trailing, style: t.bodySmall.copyWith(color: c.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
