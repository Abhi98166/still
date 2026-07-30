import 'package:flutter/material.dart';

import 'accents.dart';
import 'tokens.dart';
import 'typography.dart';

abstract final class StillTheme {
  static ThemeData light(Accent accent) =>
      _build(StillColors.light(accent), Brightness.light);

  static ThemeData dark(Accent accent) =>
      _build(StillColors.dark(accent), Brightness.dark);

  static ThemeData _build(StillColors c, Brightness brightness) {
    final type = StillType.standard();

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.clay,
      onPrimary: c.onClay,
      primaryContainer: c.claySoft,
      onPrimaryContainer: c.clay,
      secondary: c.dot,
      onSecondary: c.onClay,
      surface: c.bg,
      onSurface: c.ink,
      surfaceContainerLowest: c.bg,
      surfaceContainerLow: c.card,
      surfaceContainer: c.card,
      surfaceContainerHigh: c.card,
      surfaceContainerHighest: c.card,
      onSurfaceVariant: c.soft,
      outline: c.muted,
      outlineVariant: c.line,

      error: brightness == Brightness.light
          ? const Color(0xFFB3261E)
          : const Color(0xFFF2B8B5),
      onError: brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF601410),
      inverseSurface: c.ink,
      onInverseSurface: c.bg,
      shadow: Colors.black,
      scrim: const Color(0xFF181411),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      splashFactory: InkSparkle.splashFactory,

      textTheme: TextTheme(
        displayLarge: type.display.copyWith(color: c.ink),
        headlineLarge: type.greeting.copyWith(color: c.ink),
        headlineMedium: type.screenTitle.copyWith(color: c.ink),
        titleLarge: type.entryTitleSerif.copyWith(color: c.ink),
        titleMedium: type.listTitle.copyWith(color: c.ink),
        bodyLarge: type.button.copyWith(color: c.ink),
        bodyMedium: type.body.copyWith(color: c.soft),
        bodySmall: type.caption.copyWith(color: c.muted),
        labelLarge: type.button.copyWith(color: c.ink),
        labelSmall: type.microLabel.copyWith(color: c.muted),
      ),

      iconTheme: IconThemeData(color: c.soft, size: 20),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),

      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.clay,
          foregroundColor: c.onClay,
          minimumSize: const Size.fromHeight(StillMetrics.primaryButtonHeight),
          shape: const StadiumBorder(),
          textStyle: type.buttonLarge,
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.clay,
          textStyle: type.button,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        hintStyle: type.button.copyWith(color: c.muted),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.clay,
        selectionColor: c.claySoft,
        selectionHandleColor: c.clay,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: const Color(0xFF181411).withValues(alpha: 0.35),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(StillRadius.sheet),
          ),
        ),
        showDragHandle: false,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.clay : c.line,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        trackOutlineWidth: const WidgetStatePropertyAll(0),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: type.body.copyWith(color: c.bg),
        actionTextColor: c.dot,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StillRadius.field),
        ),
        insetPadding: const EdgeInsets.all(StillMetrics.gutter),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.clay,
        linearTrackColor: c.claySoft,
        circularTrackColor: c.claySoft,
      ),

      extensions: <ThemeExtension<dynamic>>[c, type],
    );
  }
}

extension StillThemeContext on BuildContext {
  StillColors get still => Theme.of(this).extension<StillColors>()!;

  StillType get type => Theme.of(this).extension<StillType>()!;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
