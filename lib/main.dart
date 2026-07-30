import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/still_app.dart';
import 'services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await PreferencesService.create();

  runApp(
    ProviderScope(
      overrides: [preferencesServiceProvider.overrideWithValue(preferences)],
      child: const StillApp(),
    ),
  );
}
