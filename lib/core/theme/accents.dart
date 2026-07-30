import 'package:flutter/material.dart';

@immutable
class Accent {
  const Accent({
    required this.id,
    required this.label,
    required this.light,
    required this.dark,
  });

  final String id;

  final String label;

  final Color light;
  final Color dark;

  Color resolve(bool isDark) => isDark ? dark : light;
}

abstract final class AccentRegistry {
  static const List<Accent> all = [
    Accent(
      id: 'clay',
      label: 'Clay',
      light: Color(0xFFA9704B),
      dark: Color(0xFFD79A73),
    ),
    Accent(
      id: 'sage',
      label: 'Sage',
      light: Color(0xFF7C8B72),
      dark: Color(0xFF9FB093),
    ),
    Accent(
      id: 'lavender',
      label: 'Lavender',
      light: Color(0xFF8A7BA8),
      dark: Color(0xFFB0A2CC),
    ),
    Accent(
      id: 'ink',
      label: 'Ink',
      light: Color(0xFF3A332C),
      dark: Color(0xFFCFC4B8),
    ),
  ];

  static const String defaultId = 'lavender';

  static Accent get fallback =>
      all.firstWhere((a) => a.id == defaultId, orElse: () => all.first);

  static Accent byId(String? id) =>
      all.firstWhere((a) => a.id == id, orElse: () => fallback);
}
