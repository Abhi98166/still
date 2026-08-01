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

class _StillAppState extends ConsumerState<StillApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // The backup controller watches the journal for changes, so it has to
    // outlive the screens that read it — this subscription is what pins it.
    ref.listenManual(backupControllerProvider, (_, _) {});

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifications = ref.read(notificationServiceProvider);
      await notifications.init();
      await notifications.sync(ref.read(settingsProvider));

      ref.read(backupControllerProvider.notifier).onAppLifecycle();
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.resumed) {
      ref.read(backupControllerProvider.notifier).onAppLifecycle();
    }
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
