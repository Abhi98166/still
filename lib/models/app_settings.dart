import 'package:flutter/material.dart';

import '../core/theme/accents.dart';

@immutable
class ReminderSlot {
  const ReminderSlot(this.hour, this.minute);

  final int hour;
  final int minute;

  String get id =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get label => id;

  static const List<ReminderSlot> all = [
    ReminderSlot(7, 30),
    ReminderSlot(21, 0),
    ReminderSlot(22, 30),
  ];

  static const String defaultId = '21:00';

  static ReminderSlot byId(String? id) => all.firstWhere(
    (s) => s.id == id,
    orElse: () =>
        all.firstWhere((s) => s.id == defaultId, orElse: () => all.first),
  );

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
  });

  final ThemeMode themeMode;

  final String accentId;

  final bool hasOnboarded;

  final bool reminderEnabled;

  final String reminderTimeId;

  Accent get accent => AccentRegistry.byId(accentId);

  ReminderSlot get reminderTime => ReminderSlot.byId(reminderTimeId);

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? accentId,
    bool? hasOnboarded,
    bool? reminderEnabled,
    String? reminderTimeId,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentId: accentId ?? this.accentId,
      hasOnboarded: hasOnboarded ?? this.hasOnboarded,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTimeId: reminderTimeId ?? this.reminderTimeId,
    );
  }
}
