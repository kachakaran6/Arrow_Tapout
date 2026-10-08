import 'dart:math' as math;

import 'package:arrowtapout/design/app_tokens.dart';
import 'package:arrowtapout/design/primitives.dart';
import 'package:arrowtapout/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Splash mark draws itself out of square in 600ms, then transitions to Home
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _controller.forward().then((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted) {
            context.go(Routes.home);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: const Size(120.0, 120.0),
              painter: SplashMarkPainter(
                progress: _controller.value,
                accentColor: tokens.accent,
                inkColor: tokens.ink,
                faintColor: tokens.threadFaint,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Paints the Unwind app mark: a rounded square boundary and a thread sliding out.
class SplashMarkPainter extends CustomPainter {
  SplashMarkPainter({
    required this.progress,
    required this.accentColor,
    required this.inkColor,
    required this.faintColor,
  });

  final double progress;
  final Color accentColor;
  final Color inkColor;
  final Color faintColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 72.0,
      height: 72.0,
    );

    // Rounded square box outline
    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = faintColor;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14.0)),
      boxPaint,
    );

    // Thread polyline exiting the box
    final threadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = accentColor;

    final path = Path();
    path.moveTo(rect.left + 24.0, rect.bottom - 20.0);
    path.lineTo(rect.left + 24.0, rect.top + 24.0);
    path.lineTo(rect.right + 36.0, rect.top + 24.0);

    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final curved = Primitives.curveEnter.transform(progress);
      final drawLen = metric.length * curved;

      if (drawLen > 0) {
        final sub = metric.extractPath(0.0, drawLen);
        canvas.drawPath(sub, threadPaint);

        // Chevron at tip
        final tangent = metric.getTangentForOffset(drawLen);
        if (tangent != null) {
          final angle = math.atan2(tangent.vector.dy, tangent.vector.dx);
          const arm = 9.0;
          const armA = 0.58;

          final p1 = Offset(
            tangent.position.dx + math.cos(angle + math.pi - armA) * arm,
            tangent.position.dy + math.sin(angle + math.pi - armA) * arm,
          );
          final p2 = Offset(
            tangent.position.dx + math.cos(angle + math.pi + armA) * arm,
            tangent.position.dy + math.sin(angle + math.pi + armA) * arm,
          );

          canvas.drawLine(tangent.position, p1, threadPaint);
          canvas.drawLine(tangent.position, p2, threadPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SplashMarkPainter old) =>
      old.progress != progress;
}
