import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';

/// Reusable ultra-crisp CVNova App Logo with glowing gradient squircle framing.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
    this.borderRadius,
    this.showGlow = true,
    this.showText = false,
    this.textScale = 1.0,
  });

  final double size;
  final double? borderRadius;
  final bool showGlow;
  final bool showText;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? (size * 0.24);

    final logoIcon = RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: size * 0.35,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.20),
                    blurRadius: size * 0.2,
                    offset: const Offset(0, -1),
                  ),
                ]
              : null,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E2139),
              Color(0xFF0F1120),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1.2),
          child: Image.asset(
            'assets/images/logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );

    if (!showText) return logoIcon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoIcon,
        SizedBox(width: size * 0.28),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => AppGradients.hero.createShader(bounds),
          child: Text(
            'CVNova',
            style: TextStyle(
              fontSize: 20 * textScale,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
        ),
      ],
    );
  }
}
