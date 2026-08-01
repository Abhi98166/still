import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const _kThemeMode = 'still.themeMode';
  static const _kAccentId = 'still.accentId';
  static const _kOnboarded = 'still.hasOnboarded';
  static const _kReminderOn = 'still.reminderEnabled';
  static const _kReminderTime = 'still.reminderTimeId';
  static const _kBackupOn = 'still.backupEnabled';
  static const _kBackupUri = 'still.backupFolderUri';
  static const _kBackupName = 'still.backupFolderName';
  static const _kBackupLastRun = 'still.backupLastRunAt';

  static Future<PreferencesService> create() async =>
      PreferencesService(await SharedPreferences.getInstance());

  AppSettings load() {
    final lastRun = _prefs.getInt(_kBackupLastRun);

    return AppSettings(
      themeMode: _themeModeFromString(_prefs.getString(_kThemeMode)),
      accentId: _prefs.getString(_kAccentId) ?? const AppSettings().accentId,
      hasOnboarded: _prefs.getBool(_kOnboarded) ?? false,
      reminderEnabled: _prefs.getBool(_kReminderOn) ?? false,
      reminderTimeId:
          _prefs.getString(_kReminderTime) ?? ReminderSlot.defaultId,
      backupEnabled: _prefs.getBool(_kBackupOn) ?? false,
      backupFolderUri: _prefs.getString(_kBackupUri),
      backupFolderName: _prefs.getString(_kBackupName),
      backupLastRunAt: lastRun == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastRun),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_kThemeMode, mode.name);

  Future<void> setAccentId(String id) => _prefs.setString(_kAccentId, id);

  Future<void> setOnboarded(bool value) => _prefs.setBool(_kOnboarded, value);

  Future<void> setReminderEnabled(bool value) =>
      _prefs.setBool(_kReminderOn, value);

  Future<void> setReminderTimeId(String id) =>
      _prefs.setString(_kReminderTime, id);

  Future<void> setBackupFolder(String uri, String name) async {
    await _prefs.setString(_kBackupUri, uri);
    await _prefs.setString(_kBackupName, name);
    await _prefs.setBool(_kBackupOn, true);
  }

  Future<void> setBackupLastRun(DateTime at) =>
      _prefs.setInt(_kBackupLastRun, at.millisecondsSinceEpoch);

  Future<void> clearBackup() async {
    await _prefs.remove(_kBackupUri);
    await _prefs.remove(_kBackupName);
    await _prefs.remove(_kBackupLastRun);
    await _prefs.setBool(_kBackupOn, false);
  }

  static ThemeMode _themeModeFromString(String? raw) {
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
