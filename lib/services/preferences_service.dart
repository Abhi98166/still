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

  static Future<PreferencesService> create() async =>
      PreferencesService(await SharedPreferences.getInstance());

  AppSettings load() {
    return AppSettings(
      themeMode: _themeModeFromString(_prefs.getString(_kThemeMode)),
      accentId: _prefs.getString(_kAccentId) ?? const AppSettings().accentId,
      hasOnboarded: _prefs.getBool(_kOnboarded) ?? false,
      reminderEnabled: _prefs.getBool(_kReminderOn) ?? false,
      reminderTimeId:
          _prefs.getString(_kReminderTime) ?? ReminderSlot.defaultId,
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

  static ThemeMode _themeModeFromString(String? raw) {
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
