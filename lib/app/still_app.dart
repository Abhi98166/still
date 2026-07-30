import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/still_theme.dart';
import '../core/theme/tokens.dart';
import 'providers.dart';
import 'router.dart';

class StillApp extends ConsumerStatefulWidget {
  const StillApp({super.key});

  @override
  ConsumerState<StillApp> createState() => _StillAppState();
}

class _StillAppState extends ConsumerState<StillApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifications = ref.read(notificationServiceProvider);
      await notifications.init();
      await notifications.sync(ref.read(settingsProvider));
    });

    ref.listenManual(settingsProvider, (previous, next) {
      final changed =
          previous?.reminderEnabled != next.reminderEnabled ||
          previous?.reminderTimeId != next.reminderTimeId;
      if (changed) {
        ref.read(notificationServiceProvider).sync(next);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final accent = settings.accent;

    return MaterialApp.router(
      title: 'still',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      themeMode: settings.themeMode,
      theme: StillTheme.light(accent),
      darkTheme: StillTheme.dark(accent),
      themeAnimationDuration: StillMotion.themeSwap,
      themeAnimationCurve: Curves.easeOut,
    );
  }
}
