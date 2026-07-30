import 'package:flutter/material.dart';

@immutable
class StillType extends ThemeExtension<StillType> {
  const StillType({
    required this.display,
    required this.greeting,
    required this.screenTitle,
    required this.monthLabel,
    required this.statValueLarge,
    required this.editorTitle,
    required this.prompt,
    required this.sheetTitle,
    required this.statValue,
    required this.entryTitleSerif,
    required this.dayNumeral,
    required this.editorBody,
    required this.entryBody,
    required this.snippet,
    required this.buttonLarge,
    required this.button,
    required this.settingsRow,
    required this.listTitle,
    required this.body,
    required this.bodySmall,
    required this.chip,
    required this.caption,
    required this.overline,
    required this.overlineTight,
    required this.overlineSmall,
    required this.microLabel,
    required this.tabLabel,
  });

  final TextStyle display;

  final TextStyle greeting;

  final TextStyle screenTitle;

  final TextStyle monthLabel;

  final TextStyle statValueLarge;

  final TextStyle editorTitle;

  final TextStyle prompt;

  final TextStyle sheetTitle;

  final TextStyle statValue;

  final TextStyle entryTitleSerif;

  final TextStyle dayNumeral;

  final TextStyle editorBody;

  final TextStyle entryBody;

  final TextStyle snippet;

  final TextStyle buttonLarge;

  final TextStyle button;

  final TextStyle settingsRow;

  final TextStyle listTitle;

  final TextStyle body;

  final TextStyle bodySmall;

  final TextStyle chip;

  final TextStyle caption;

  final TextStyle overline;

  final TextStyle overlineTight;

  final TextStyle overlineSmall;

  final TextStyle microLabel;

  final TextStyle tabLabel;

  static const String _serif = 'Newsreader';

  static double _ls(double em, double size) => em * size;

  static TextStyle _serifStyle(
    double size, {
    double weight = 400,
    double? height,
    double letterSpacingEm = 0,
    bool italic = false,
  }) {
    return TextStyle(
      fontFamily: _serif,
      fontSize: size,
      height: height,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      letterSpacing: letterSpacingEm == 0 ? null : _ls(letterSpacingEm, size),

      fontWeight: _nearestWeight(weight),
      fontVariations: [
        FontVariation('wght', weight),
        FontVariation('opsz', size.clamp(6, 72)),
      ],
    );
  }

  static TextStyle _sansStyle(
    double size, {
    FontWeight weight = FontWeight.w400,
    double? height,
    double letterSpacingEm = 0,
  }) {
    return TextStyle(
      fontSize: size,
      height: height,
      fontWeight: weight,
      letterSpacing: letterSpacingEm == 0 ? null : _ls(letterSpacingEm, size),
    );
  }

  static FontWeight _nearestWeight(double w) {
    final index = ((w / 100).round() - 1).clamp(
      0,
      FontWeight.values.length - 1,
    );
    return FontWeight.values[index];
  }

  factory StillType.standard() {
    return StillType(
      display: _serifStyle(44, height: 1.1, letterSpacingEm: -0.01),
      greeting: _serifStyle(34, height: 1.15),
      screenTitle: _serifStyle(32),
      monthLabel: _serifStyle(28),
      statValueLarge: _serifStyle(26, height: 1.0),
      editorTitle: _serifStyle(24),
      prompt: _serifStyle(22, height: 1.4, weight: 300, italic: true),
      sheetTitle: _serifStyle(22),
      statValue: _serifStyle(22),
      entryTitleSerif: _serifStyle(20),
      dayNumeral: _serifStyle(20, height: 1.1),
      editorBody: _serifStyle(18, height: 1.7),
      entryBody: _serifStyle(16, height: 1.65),
      snippet: _serifStyle(15, height: 1.55),
      buttonLarge: _sansStyle(17, letterSpacingEm: 0.01),
      button: _sansStyle(16),
      settingsRow: _sansStyle(15.5),
      listTitle: _sansStyle(15, weight: FontWeight.w500),
      body: _sansStyle(14.5),
      bodySmall: _sansStyle(14),
      chip: _sansStyle(13.5),
      caption: _sansStyle(12.5),
      overline: _sansStyle(12, letterSpacingEm: 0.16),
      overlineTight: _sansStyle(12, letterSpacingEm: 0.14),
      overlineSmall: _sansStyle(11.5, letterSpacingEm: 0.14),
      microLabel: _sansStyle(11, letterSpacingEm: 0.1),
      tabLabel: _sansStyle(11.5, letterSpacingEm: 0.06),
    );
  }

  @override
  StillType copyWith() => this;

  @override
  StillType lerp(ThemeExtension<StillType>? other, double t) => this;
}
