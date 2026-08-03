import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/theme/accents.dart';
import '../../core/theme/still_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/still_dates.dart';
import '../../models/app_settings.dart';
import '../../services/backup_storage.dart';
import '../../services/notification_service.dart';
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

            if (BackupStorage.isSupported) ...[
              const SizedBox(height: 26),
              const StillLabel('Backup folder', style: StillLabelStyle.group),
              const SizedBox(height: 10),
              _BackupGroup(settings: settings),
            ],

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
                if (BackupStorage.isSupported)
                  _DataRow(
                    label: 'Restore from folder',
                    trailing: 'A backup folder',
                    onTap: () => showRestoreSheet(context, ref),
                  ),
              ],
            ),

            const SizedBox(height: 26),
            Center(
              child: Text(
                'still 1.0.1 · $entryCount '
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
                onChanged: (v) => _setEnabled(context, ref, v),
              ),
            ],
          ),
        ),

        AnimatedOpacity(
          duration: StillMotion.themeSwap,
          opacity: settings.reminderEnabled ? 1 : 0.4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => _pickTime(context, ref, settings.reminderTime),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Time',
                          style: t.settingsRow.copyWith(color: c.ink),
                        ),
                      ),
                      Text(
                        settings.reminderTime.label,
                        style: t.settingsRow.copyWith(color: c.clay),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: c.muted,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final slot in ReminderSlot.presets)
                      _TimeChip(
                        label: slot.label,
                        selected: slot == settings.reminderTime,
                        onTap: () => _chooseTime(context, ref, slot),
                      ),
                    _TimeChip(
                      label: 'Custom',
                      selected: !settings.reminderTime.isPreset,
                      onTap: () =>
                          _pickTime(context, ref, settings.reminderTime),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    ReminderSlot current,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current.timeOfDay,
      helpText: 'Daily nudge',
      builder: (pickerContext, child) => MediaQuery(
        data: MediaQuery.of(
          pickerContext,
        ).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;

    await _chooseTime(context, ref, ReminderSlot.fromTimeOfDay(picked));
  }

  static Future<void> _chooseTime(
    BuildContext context,
    WidgetRef ref,
    ReminderSlot slot,
  ) async {
    await ref.read(settingsProvider.notifier).setReminderTime(slot);

    if (!ref.read(settingsProvider).reminderEnabled && context.mounted) {
      await _setEnabled(context, ref, true);
    }
  }

  static Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    if (!value) {
      await ref.read(settingsProvider.notifier).setReminderEnabled(false);
      return;
    }

    final granted =
        !NotificationService.isSupported ||
        await ref.read(notificationServiceProvider).requestPermission();

    if (granted) {
      await ref.read(settingsProvider.notifier).setReminderEnabled(true);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Notifications are blocked for still. Allow them in your system '
          'settings to get the nudge.',
        ),
      ),
    );
  }
}

class _BackupGroup extends ConsumerWidget {
  const _BackupGroup({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.still;
    final t = context.type;

    final backup = ref.watch(backupControllerProvider);
    final controller = ref.read(backupControllerProvider.notifier);
    final on = settings.backupReady;
    final busy = backup.isRunning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StillGroup(
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
                          'Daily backup',
                          style: t.settingsRow.copyWith(color: c.ink),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          on
                              ? 'One file per day, written as you write'
                              : 'Choose a folder you already sync',
                          style: t.caption.copyWith(color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: on,
                    onChanged: busy
                        ? null
                        : (value) => value
                              ? controller.chooseFolder()
                              : controller.disable(),
                  ),
                ],
              ),
            ),

            if (on) ...[
              _DataRow(
                label: 'Folder',
                trailing: settings.backupFolderName ?? 'Chosen folder',
                onTap: busy ? null : controller.chooseFolder,
              ),
              _DataRow(
                label: 'Back up now',
                trailing: _lastRun(backup, settings),
                onTap: busy ? null : () => controller.run(),
              ),
              _DataRow(
                label: 'Re-export everything',
                trailing: 'Rewrites every file',
                onTap: busy ? null : () => controller.run(full: true),
              ),
            ],
          ],
        ),

        if (on && backup.message != null)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
            child: Text(
              backup.message!,
              style: t.caption.copyWith(
                color: backup.phase == BackupPhase.failed ? c.clay : c.muted,
                height: 1.5,
              ),
            ),
          ),

        if (!on)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
            child: Text(
              'still writes a plain folder of dated Markdown files. Point '
              'Syncthing — or any other sync app — at it and your journal '
              'backs itself up. Pick a folder outside Android/data so other '
              'apps can read it.',
              style: t.caption.copyWith(color: c.muted, height: 1.5),
            ),
          ),
      ],
    );
  }

  static String _lastRun(BackupState backup, AppSettings settings) {
    if (backup.isRunning) return 'Working…';

    final at = settings.backupLastRunAt;
    if (at == null) return 'Not yet';

    final now = DateTime.now();
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return sameDay ? StillDates.timeOfDay(at) : StillDates.fullDate(at);
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;

    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? c.claySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(StillRadius.chip),
            border: Border.all(color: selected ? c.clay : c.line),
          ),
          child: Text(
            label,
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
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  trailing,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(color: c.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
