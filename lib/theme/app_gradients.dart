import 'package:flutter/material.dart';

class AppGradients {
  AppGradients._();

  /// Primary CTA / hero gradient — vibrant Radiant Indigo -> Electric Violet -> Fuchsia Neon
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFD946EF)],
  );

  /// Electric Violet & Indigo (punchy modern CTA)
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  );

  /// Cyber Cyan -> Cobalt Blue
  static const LinearGradient cyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  );

  /// Aurora Mint -> Cyan
  static const LinearGradient mint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
  );

  /// Amber Glow -> Coral Fire
  static const LinearGradient amber = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFF43F5E)],
  );

  /// Full score ramp — used by ScoreRing and progress bars.
  static const LinearGradient score = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFF59E0B)],
  );

  /// Glass card gradient background
  static LinearGradient glassCard(Brightness b) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: b == Brightness.dark
            ? const [Color(0x1F22283A), Color(0x0F111322)]
            : const [Color(0xFFFFFFFF), Color(0xF7F8FAFC)],
      );

  /// Smooth glass stroke / border gradient
  static LinearGradient glassBorder(Brightness b) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: b == Brightness.dark
            ? const [Color(0x38FFFFFF), Color(0x0AFFFFFF)]
            : const [Color(0x33000000), Color(0x0A000000)],
      );

  /// Soft ambient background blob
  static RadialGradient ambientBlob(Color color, {double opacity = 0.3}) => RadialGradient(
        colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0.0)],
      );
}
