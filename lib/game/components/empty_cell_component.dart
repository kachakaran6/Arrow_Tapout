import 'dart:ui';
import 'package:flame/components.dart';
import 'package:arrowtapout/design/colors.dart';
import 'package:arrowtapout/design/constants.dart';

/// Visual hole left behind after an arrow is removed
/// Faint rounded square outline with a pulse ring
class EmptyCellComponent extends PositionComponent {
  double _pulseAge = 0;
  bool _pulseDone = false;
  double _pulseAlpha = 0.6;
  double _pulseRadius = 0;

  EmptyCellComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(GameConstants.arrowSize),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (_pulseDone) return;

    _pulseAge += dt * 1000;
    final t = _pulseAge / GameConstants.emptyCellPulseMs;
    if (t >= 1.0) {
      _pulseDone = true;
      _pulseAlpha = 0;
      return;
    }
    _pulseAlpha = 0.6 * (1.0 - t);
    _pulseRadius = 20.0 * t;
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Faint rounded square outline
    final outlinePaint = Paint()
      ..color = GameColors.emptyCellBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.x * 0.7,
          height: size.y * 0.7,
        ),
        const Radius.circular(6),
      ),
      outlinePaint,
    );

    // Pulse ring
    if (!_pulseDone && _pulseAlpha > 0) {
      final pulsePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withOpacity(_pulseAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(
        Offset(cx, cy),
        size.x * 0.3 + _pulseRadius,
        pulsePaint,
      );
    }
  }
}
