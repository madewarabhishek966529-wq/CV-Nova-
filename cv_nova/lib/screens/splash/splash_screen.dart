import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) context.go(RouteNames.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
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
                ShaderMask(
                  shaderCallback: (bounds) => AppGradients.hero.createShader(bounds),
                  child: Text(
                    'CVNova',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(
                    begin: const Offset(0.92, 0.92), end: const Offset(1, 1)),
                const SizedBox(height: 10),
                Text(
                  'Build the resume that gets you the interview',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
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
