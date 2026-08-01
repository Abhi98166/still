import 'package:flutter/material.dart';

import '../core/theme/accents.dart';

@immutable
class ReminderSlot {
  const ReminderSlot(this.hour, this.minute);

  final int hour;
  final int minute;

  String get id =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get label {
    final display = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour < 12 ? 'AM' : 'PM';
    return '$display:${minute.toString().padLeft(2, '0')} $period';
  }

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  bool get isPreset => presets.contains(this);

  static const List<ReminderSlot> presets = [
    ReminderSlot(7, 30),
    ReminderSlot(21, 0),
    ReminderSlot(22, 30),
  ];

  static const ReminderSlot fallback = ReminderSlot(21, 0);

  static const String defaultId = '21:00';

  factory ReminderSlot.fromTimeOfDay(TimeOfDay time) =>
      ReminderSlot(time.hour, time.minute);

  static ReminderSlot? tryParse(String? id) {
    if (id == null) return null;

    final parts = id.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return ReminderSlot(hour, minute);
  }

  static ReminderSlot byId(String? id) => tryParse(id) ?? fallback;

  @override
  bool operator ==(Object other) =>
      other is ReminderSlot && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.accentId = AccentRegistry.defaultId,
    this.hasOnboarded = false,
    this.reminderEnabled = false,
    this.reminderTimeId = ReminderSlot.defaultId,
    this.backupEnabled = false,
    this.backupFolderUri,
    this.backupFolderName,
    this.backupLastRunAt,
  });

  final ThemeMode themeMode;

  final String accentId;

  final bool hasOnboarded;

  final bool reminderEnabled;

  final String reminderTimeId;

  final bool backupEnabled;

  final String? backupFolderUri;

  final String? backupFolderName;

  final DateTime? backupLastRunAt;

  Accent get accent => AccentRegistry.byId(accentId);

  ReminderSlot get reminderTime => ReminderSlot.byId(reminderTimeId);

  bool get backupReady => backupEnabled && backupFolderUri != null;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? accentId,
    bool? hasOnboarded,
    bool? reminderEnabled,
    String? reminderTimeId,
    bool? backupEnabled,
    String? backupFolderUri,
    String? backupFolderName,
    DateTime? backupLastRunAt,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentId: accentId ?? this.accentId,
      hasOnboarded: hasOnboarded ?? this.hasOnboarded,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTimeId: reminderTimeId ?? this.reminderTimeId,
      backupEnabled: backupEnabled ?? this.backupEnabled,
      backupFolderUri: backupFolderUri ?? this.backupFolderUri,
      backupFolderName: backupFolderName ?? this.backupFolderName,
      backupLastRunAt: backupLastRunAt ?? this.backupLastRunAt,
    );
  }

  AppSettings withoutBackup() {
    return AppSettings(
      themeMode: themeMode,
      accentId: accentId,
      hasOnboarded: hasOnboarded,
      reminderEnabled: reminderEnabled,
      reminderTimeId: reminderTimeId,
    );
  }
}
