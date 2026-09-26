import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/common/app_logo.dart';

/// Purely a branding beat — CVNova is single-user/local, so there's no
/// session to restore and nothing to gate on here. It just shows the logo
/// for a moment, then lands on the dashboard.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) context.go(RouteNames.dashboard);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient gradient blobs — atmosphere only, not decoration for its own sake.
          Positioned(
            top: -80,
            left: -60,
            child: _blob(AppColors.indigo, 260),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: _blob(AppColors.violet, 320),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 84, showGlow: true)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), curve: Curves.easeOutBack),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppGradients.hero.createShader(bounds),
                  child: Text(
                    'CVNova',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                  ),
                ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 8),
                Text(
                  'Next-Gen Resume & Career Intelligence',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        letterSpacing: -0.2,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.ambientBlob(color),
      ),
    );
  }
}
