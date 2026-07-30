import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  /// Primary CTA / hero gradient — indigo to violet, 135°.
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppColors.heroGradient,
  );

  /// Full score ramp — used by ScoreRing and any progress-through-achievement UI.
  static const LinearGradient score = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppColors.scoreGradient,
  );

  /// Soft ambient background blobs behind glass surfaces. Very low opacity —
  /// this is atmosphere, not a focal element.
  static RadialGradient ambientBlob(Color color, {double opacity = 0.35}) => RadialGradient(
        colors: [color.withOpacity(opacity), color.withOpacity(0.0)],
      );

  static LinearGradient glassOverlay(Brightness b) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: b == Brightness.dark
            ? [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)]
            : [Colors.white.withOpacity(0.75), Colors.white.withOpacity(0.35)],
      );
}
