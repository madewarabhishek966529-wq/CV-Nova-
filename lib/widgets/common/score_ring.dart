import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// CVNova's signature visual: a gradient progress ring used everywhere a
/// score exists (Resume Score, ATS Score, Interview Readiness, Skill Graph
/// nodes). The sweep always uses [AppColors.scoreGradient] so a "72" means
/// the same color story no matter where it appears in the app.
///
/// Animates from 0 to [value] on first build.
class ScoreRing extends StatefulWidget {
  const ScoreRing({
    super.key,
    required this.value, // 0.0 - 1.0
    this.size = 96,
    this.strokeWidth = 10,
    this.label,
    this.showPercentage = true,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final String? label;
  final bool showPercentage;

  @override
  State<ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<ScoreRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ScoreRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animatedValue = widget.value.clamp(0.0, 1.0) * _animation.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ScoreRingPainter(
                  progress: animatedValue,
                  strokeWidth: widget.strokeWidth,
                  trackColor: AppColors.glassBorder(brightness),
                ),
              ),
              if (widget.showPercentage)
                Text(
                  '${(animatedValue * 100).round()}',
                  style: AppTypography.data(
                    brightness: brightness,
                    fontSize: widget.size * 0.24,
                    weight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    final sweepPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: AppColors.scoreGradient,
        stops: [0.0, 0.55, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
