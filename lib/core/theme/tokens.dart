import 'package:flutter/material.dart';

import 'accents.dart';

@immutable
class StillColors extends ThemeExtension<StillColors> {
  const StillColors({
    required this.bg,
    required this.card,
    required this.ink,
    required this.soft,
    required this.muted,
    required this.line,
    required this.clay,
    required this.claySoft,
    required this.dot,
    required this.onClay,
  });

  final Color bg;

  final Color card;

  final Color ink;

  final Color soft;

  final Color muted;

  final Color line;

  final Color clay;

  final Color claySoft;

  final Color dot;

  final Color onClay;

  factory StillColors.light(Accent accent) {
    final clay = accent.light;
    return StillColors(
      bg: const Color(0xFFFAF6F0),
      card: const Color(0xFFFFFFFF),
      ink: const Color(0xFF2B2521),
      soft: const Color(0xFF6B6259),
      muted: const Color(0xFF9C9289),

      line: const Color(0xFF2B2521).withValues(alpha: 0.09),
      clay: clay,

      claySoft: clay.withValues(alpha: 0.12),
      dot: const Color(0xFFC6A98F),
      onClay: _onAccent(clay),
    );
  }

  factory StillColors.dark(Accent accent) {
    final clay = accent.dark;
    return StillColors(
      bg: const Color(0xFF161310),
      card: const Color(0xFF211D19),
      ink: const Color(0xFFEFE8DF),
      soft: const Color(0xFFB4AAA0),
      muted: const Color(0xFF8A8077),

      line: const Color(0xFFEFE8DF).withValues(alpha: 0.11),
      clay: clay,

      claySoft: clay.withValues(alpha: 0.15),
      dot: const Color(0xFFA8846A),
      onClay: _onAccent(clay),
    );
  }

  static Color _onAccent(Color accent) => accent.computeLuminance() > 0.45
      ? const Color(0xFF2B2521)
      : const Color(0xFFFFF7F1);

  @override
  StillColors copyWith({
    Color? bg,
    Color? card,
    Color? ink,
    Color? soft,
    Color? muted,
    Color? line,
    Color? clay,
    Color? claySoft,
    Color? dot,
    Color? onClay,
  }) {
    return StillColors(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      ink: ink ?? this.ink,
      soft: soft ?? this.soft,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      clay: clay ?? this.clay,
      claySoft: claySoft ?? this.claySoft,
      dot: dot ?? this.dot,
      onClay: onClay ?? this.onClay,
    );
  }

  @override
  StillColors lerp(ThemeExtension<StillColors>? other, double t) {
    if (other is! StillColors) return this;
    return StillColors(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      clay: Color.lerp(clay, other.clay, t)!,
      claySoft: Color.lerp(claySoft, other.claySoft, t)!,
      dot: Color.lerp(dot, other.dot, t)!,
      onClay: Color.lerp(onClay, other.onClay, t)!,
    );
  }
}

abstract final class StillRadius {
  static const double card = 22;

  static const double group = 18;

  static const double field = 16;

  static const double cell = 14;

  static const double option = 16;

  static const double chip = 10;

  static const double sheet = 26;

  static const double heat = 3;
}

abstract final class StillMetrics {
  static const double gutter = 22;

  static const double primaryButtonHeight = 56;

  static const double cardButtonHeight = 52;

  static const EdgeInsets tabBarPadding = EdgeInsets.only(
    left: 12,
    right: 12,
    top: 10,
    bottom: 30,
  );

  static const double tabDot = 6;

  static const double tabMinHeight = 48;

  static List<BoxShadow> cardShadow(Color ink) => [
    BoxShadow(
      color: ink.withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];
}

abstract final class StillMotion {
  static const Duration sheet = Duration(milliseconds: 260);
  static const Curve sheetCurve = Cubic(0.2, 0.8, 0.2, 1);

  static const Duration up = Duration(milliseconds: 260);
  static const double upOffset = 10;

  static const Duration themeSwap = Duration(milliseconds: 220);
}
