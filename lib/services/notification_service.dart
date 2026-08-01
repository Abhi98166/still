import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';

class NotificationService {
  static const int _dailyId = 1;
  static const String _channelId = 'still.daily';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (_ready) return;

    if (!isSupported) return;

    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await ios?.requestPermissions(alert: true, sound: true);
      return granted ?? false;
    }
    return false;
  }

  Future<void> schedule(ReminderSlot slot) async {
    if (!_ready) return;
    await cancel();

    await _plugin.zonedSchedule(
      id: _dailyId,
      title: 'still',
      body: 'One quiet page. What are you grateful for today?',
      scheduledDate: _nextOccurrence(slot),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Daily nudge',
          channelDescription: 'A once-a-day reminder to write your entry.',

          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),

      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel() async {
    if (!_ready) return;
    await _plugin.cancel(id: _dailyId);
  }

  Future<void> sync(AppSettings settings) async {
    if (!_ready) return;
    if (settings.reminderEnabled) {
      await schedule(settings.reminderTime);
    } else {
      await cancel();
    }
  }

  static tz.TZDateTime _nextOccurrence(ReminderSlot slot) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      slot.hour,
      slot.minute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}
