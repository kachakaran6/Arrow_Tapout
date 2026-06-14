import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Typography system for Arrow Tap-Out
/// Uses Space Grotesk font via google_fonts
class GameTypography {
  GameTypography._();

  // Combo counter: 48sp, Bold, White
  static TextStyle get comboCounter => GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: GameColors.textPrimary,
      );

  // Combo multiplier: 32sp, Bold, Gold
  static TextStyle get comboMultiplier => GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: GameColors.comboHighlight,
        letterSpacing: 2,
      );

  // "Puzzle Cleared": 40sp, ExtraBold, White
  static TextStyle get puzzleCleared => GoogleFonts.spaceGrotesk(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: GameColors.textPrimary,
        shadows: const [
          Shadow(
            color: Color(0x80FFFFFF),
            blurRadius: 20,
          ),
        ],
      );

  // Level subtitle: 16sp, Regular, White 60%
  static TextStyle get levelSubtitle => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: GameColors.textSecondary,
      );

  // HUD label: 14sp, Medium, White 60%
  static TextStyle get hudLabel => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: GameColors.textSecondary,
      );

  // HUD value: 24sp, Bold, White
  static TextStyle get hudValue => GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: GameColors.textPrimary,
      );

  // Button text: 16sp, Bold, White
  static TextStyle get button => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: GameColors.textPrimary,
      );
}
