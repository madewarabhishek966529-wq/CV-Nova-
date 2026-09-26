import 'dart:ui';
import 'package:flutter/material.dart';

/// Ultra-smooth 120 FPS glass surface.
/// Uses GPU-efficient translucent gradient fills and optional hardware blur.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 22,
    this.blur = 0, // Default to 0 for maximum 120 FPS rendering speed
    this.gradient,
    this.borderColor,
    this.fillColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double blur;
  final Gradient? gradient;
  final Color? borderColor;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);

    final boxDecoration = BoxDecoration(
      gradient: gradient ??
          (fillColor != null
              ? null
              : (isDark
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF131728), Color(0xFF0D0F1B)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                    ))),
      color: fillColor,
      borderRadius: radius,
      border: Border.all(
        color: borderColor ??
            (isDark ? const Color(0x28FFFFFF) : const Color(0x14000000)),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? const Color(0x28000000) : const Color(0x0A000000),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );

    if (blur > 0) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: boxDecoration,
              child: child,
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: Container(
        padding: padding,
        decoration: boxDecoration,
        child: child,
      ),
    );
  }
}
