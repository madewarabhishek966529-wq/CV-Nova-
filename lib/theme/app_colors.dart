import 'package:flutter/material.dart';

/// CVNova ultra-premium color tokens optimized for 120 FPS rendering.
class AppColors {
  AppColors._();

  // Vibrant Brand Accents
  static const Color primary = Color(0xFF6366F1); // Radiant Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF8B5CF6); // Electric Violet
  static const Color tertiary = Color(0xFFD946EF); // Fuchsia Neon
  static const Color cyan = Color(0xFF06B6D4); // Cyber Cyan
  static const Color mint = Color(0xFF10B981); // Emerald Mint
  static const Color amber = Color(0xFFF59E0B); // Amber Glow
  static const Color coral = Color(0xFFF43F5E); // Rose/Coral

  // Surfaces — Dark (Obsidian / OLED deep)
  static const Color backgroundDark = Color(0xFF07080E);
  static const Color surfaceDark = Color(0xFF10121E);
  static const Color surfaceElevatedDark = Color(0xFF181B2D);
  static const Color surfaceCardDark = Color(0xFF131627);
  static const Color cardBorderDark = Color(0x24FFFFFF); // 14% white border

  // Surfaces — Light (Clean frosted pearl)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFF1F5F9);
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0x1A000000); // 10% black border

  // Text — Dark Mode
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Text — Light Mode
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Status & Semantic
  static const Color success = mint;
  static const Color warning = amber;
  static const Color danger = coral;
  static const Color info = cyan;

  // Static Gradient ramps
  static const List<Color> scoreGradient = [primary, secondary, amber];
  static const List<Color> heroGradient = [primary, secondary, tertiary];
  static const List<Color> cyanGradient = [cyan, primary];
  static const List<Color> mintGradient = [mint, cyan];
  static const List<Color> amberGradient = [amber, coral];
  static const List<Color> obsidianGradient = [Color(0xFF141728), Color(0xFF0D0F1B)];

  // Legacy mappings for backwards-compatibility
  static const Color indigo = primary;
  static const Color violet = secondary;
  static const Color ink = backgroundDark;
  static const Color inkElevated = surfaceElevatedDark;
  static const Color paper = backgroundLight;
  static const Color paperElevated = surfaceElevatedLight;

  static Color glassBorder(Brightness b) =>
      b == Brightness.dark ? const Color(0x26FFFFFF) : const Color(0x1A000000);

  static Color surface(Brightness b) =>
      b == Brightness.dark ? surfaceDark : surfaceLight;

  static Color surfaceElevated(Brightness b) =>
      b == Brightness.dark ? surfaceElevatedDark : surfaceElevatedLight;

  static Color textPrimary(Brightness b) =>
      b == Brightness.dark ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(Brightness b) =>
      b == Brightness.dark ? textSecondaryDark : textSecondaryLight;
}
