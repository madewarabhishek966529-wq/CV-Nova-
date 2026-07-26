import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Type roles:
/// - Display (Space Grotesk): headlines, hero numbers, section titles.
///   Geometric and a little architectural — signals "built", not "written".
/// - Body (Inter): everything a user reads and edits.
/// - Data (JetBrains Mono): scores, percentages, dates in tables — anything
///   that should look measured rather than composed.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final display = GoogleFonts.spaceGrotesk(color: primary, fontWeight: FontWeight.w600);
    final body = GoogleFonts.inter(color: primary);
    final bodyMuted = GoogleFonts.inter(color: secondary);

    return TextTheme(
      displayLarge: display.copyWith(fontSize: 48, height: 1.05, letterSpacing: -1.0),
      displayMedium: display.copyWith(fontSize: 36, height: 1.1, letterSpacing: -0.6),
      displaySmall: display.copyWith(fontSize: 28, height: 1.15, letterSpacing: -0.4),
      headlineMedium: display.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
      headlineSmall: display.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: body.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      titleMedium: body.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      bodyLarge: body.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: body.copyWith(fontSize: 14, height: 1.5),
      bodySmall: bodyMuted.copyWith(fontSize: 12.5, height: 1.4),
      labelLarge: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      labelSmall: bodyMuted.copyWith(fontSize: 11, letterSpacing: 0.4),
    );
  }

  /// Monospace style for scores, stats, and dates. Use sparingly and only
  /// for genuinely measured/numeric content, never for prose.
  static TextStyle data({
    required Brightness brightness,
    double fontSize = 14,
    FontWeight weight = FontWeight.w500,
  }) {
    final color = brightness == Brightness.dark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    return GoogleFonts.jetBrainsMono(fontSize: fontSize, fontWeight: weight, color: color);
  }
}
