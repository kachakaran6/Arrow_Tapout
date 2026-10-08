import 'package:arrowtapout/design/primitives.dart';
import 'package:flutter/material.dart';

/// Typography definitions for Unwind.
///
/// Uses Newsreader (serif) for display & title numerals and Manrope for clean UI.
final class AppTypography {
  const AppTypography({
    required this.display,
    required this.title,
    required this.heading,
    required this.body,
    required this.label,
    required this.caption,
  });

  final TextStyle display;
  final TextStyle title;
  final TextStyle heading;
  final TextStyle body;
  final TextStyle label;
  final TextStyle caption;

  /// Creates typography scaled to the theme's [ink] and [inkMuted] colours.
  factory AppTypography.create({
    required Color ink,
    required Color inkMuted,
  }) {
    return AppTypography(
      display: TextStyle(
        fontFamily: Primitives.fontDisplay,
        fontSize: 40.0,
        height: 44.0 / 40.0,
        fontWeight: FontWeight.w500,
        color: ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      title: TextStyle(
        fontFamily: Primitives.fontDisplay,
        fontSize: 24.0,
        height: 30.0 / 24.0,
        fontWeight: FontWeight.w500,
        color: ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      heading: TextStyle(
        fontFamily: Primitives.fontUi,
        fontSize: 18.0,
        height: 24.0 / 18.0,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      body: TextStyle(
        fontFamily: Primitives.fontUi,
        fontSize: 15.0,
        height: 22.0 / 15.0,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      label: TextStyle(
        fontFamily: Primitives.fontUi,
        fontSize: 13.0,
        height: 16.0 / 13.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: ink,
      ),
      caption: TextStyle(
        fontFamily: Primitives.fontUi,
        fontSize: 12.0,
        height: 16.0 / 12.0,
        fontWeight: FontWeight.w500,
        color: inkMuted,
      ),
    );
  }

  /// Clamps text scaler to a maximum of 1.3 per accessibility specification.
  static TextScaler clampScaler(TextScaler scaler) {
    return scaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3);
  }

  AppTypography copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? heading,
    TextStyle? body,
    TextStyle? label,
    TextStyle? caption,
  }) {
    return AppTypography(
      display: display ?? this.display,
      title: title ?? this.title,
      heading: heading ?? this.heading,
      body: body ?? this.body,
      label: label ?? this.label,
      caption: caption ?? this.caption,
    );
  }

  static AppTypography lerp(AppTypography a, AppTypography b, double t) {
    return AppTypography(
      display: TextStyle.lerp(a.display, b.display, t)!,
      title: TextStyle.lerp(a.title, b.title, t)!,
      heading: TextStyle.lerp(a.heading, b.heading, t)!,
      body: TextStyle.lerp(a.body, b.body, t)!,
      label: TextStyle.lerp(a.label, b.label, t)!,
      caption: TextStyle.lerp(a.caption, b.caption, t)!,
    );
  }
}
