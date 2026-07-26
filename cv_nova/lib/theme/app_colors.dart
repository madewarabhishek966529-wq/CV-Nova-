import 'package:flutter/material.dart';

/// CVNova color tokens.
///
/// Palette logic: this is a career-growth product, so the accent ramp
/// (indigo -> violet -> amber) doubles as the "score" gradient used across
/// the app (resume score, ATS score, skill graph). Cool = starting point,
/// warm = achievement. Every score-driven visual should pull from
/// [AppColors.scoreGradient] rather than inventing a new ramp.
class AppColors {
  AppColors._();

  // Brand ramp
  static const Color indigo = Color(0xFF4A3AFF);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color amber = Color(0xFFF5A623);
  static const Color coral = Color(0xFFFF5D73);
  static const Color mint = Color(0xFF2FD8A6);

  // Surfaces — dark
  static const Color ink = Color(0xFF0C0E1B);
  static const Color inkElevated = Color(0xFF14172A);
  static const Color inkGlass = Color(0x1AFFFFFF); // white 10% for glass fill

  // Surfaces — light
  static const Color paper = Color(0xFFF6F5FB);
  static const Color paperElevated = Color(0xFFFFFFFF);
  static const Color paperGlass = Color(0x99FFFFFF); // white 60% for glass fill

  // Text — dark mode
  static const Color textPrimaryDark = Color(0xFFF3F2FA);
  static const Color textSecondaryDark = Color(0xFF9C9CB8);

  // Text — light mode
  static const Color textPrimaryLight = Color(0xFF14172A);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Semantic
  static const Color success = mint;
  static const Color warning = amber;
  static const Color danger = coral;

  static const List<Color> scoreGradient = [indigo, violet, amber];
  static const List<Color> heroGradient = [indigo, violet];

  static Color glassBorder(Brightness b) =>
      b == Brightness.dark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
}
