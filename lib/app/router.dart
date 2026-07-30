import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/calendar/calendar_screen.dart';
import '../features/home/home_screen.dart';
import '../features/journal/editor_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stats/stats_screen.dart';
import '../models/journal_entry.dart';
import '../widgets/still_tab_bar.dart';
import 'providers.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const home = '/';
  static const calendar = '/calendar';
  static const search = '/search';
  static const settings = '/settings';
  static const stats = '/stats';

  static String entry(String dateKey) => '/entry/$dateKey';
}

int _branchFor(StillTab tab) => switch (tab) {
  StillTab.home => 0,
  StillTab.calendar => 1,
  StillTab.search => 2,
  StillTab.settings => 3,
};

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,

    redirect: (context, state) {
      final onboarded = ref.read(settingsProvider).hasOnboarded;
      final atOnboarding = state.matchedLocation == Routes.onboarding;

      if (!onboarded && !atOnboarding) return Routes.onboarding;
      if (onboarded && atOnboarding) return Routes.home;
      return null;
    },

    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),

      GoRoute(
        path: '/entry/:date',
        builder: (context, state) {
          final raw = state.pathParameters['date'];

          final dateKey = _isValidDateKey(raw) ? raw! : JournalEntry.todayKey();
          return EditorScreen(dateKey: dateKey);
        },
      ),
      GoRoute(path: Routes.stats, builder: (_, _) => const StatsScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => navigationShell,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.calendar,
                builder: (_, _) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.search,
                builder: (_, _) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

bool _isValidDateKey(String? raw) {
  if (raw == null) return false;
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return false;
  try {
    JournalEntry.parseDateKey(raw);
    return true;
  } catch (_) {
    return false;
  }
}

void goToTab(BuildContext context, StillTab tab) {
  final shell = StatefulNavigationShell.of(context);
  final index = _branchFor(tab);
  shell.goBranch(index, initialLocation: index == shell.currentIndex);
}
