import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';

/// Confetti burst for board completion
class ConfettiComponent extends PositionComponent {
  static const int _count = 80;
  late List<_Confetti> _particles;
  bool _done = false;

  ConfettiComponent({required Vector2 center})
      : super(position: center);

  @override
  Future<void> onLoad() async {
    _particles = _generate();
  }

  List<_Confetti> _generate() {
    final rng = math.Random();
    const colors = [
      Color(0xFF4ECAFF),
      Color(0xFFFF6B6B),
      Color(0xFFFFC45C),
      Color(0xFF78FFB8),
      Color(0xFFB47CFF),
      Color(0xFFFF8DE0),
      Color(0xFFFFD166),
    ];

    return List.generate(_count, (i) {
      final angle = rng.nextDouble() * math.pi * 2;
      final speed = 150 + rng.nextDouble() * 250;
      return _Confetti(
        velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
        gravity: 200 + rng.nextDouble() * 100,
        lifetime: 800 + rng.nextDouble() * 600,
        width: 4 + rng.nextDouble() * 6,
        height: 6 + rng.nextDouble() * 8,
        color: colors[rng.nextInt(colors.length)],
        rotationSpeed: (rng.nextDouble() * 6 - 3),
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_done) return;

    bool allDead = true;
    for (final p in _particles) {
      p.age += dt * 1000;
      if (p.age < p.lifetime) {
        p.position += p.velocity * dt;
        p.velocity.y += p.gravity * dt;
        p.rotation += p.rotationSpeed * dt;
        allDead = false;
      }
    }

    if (allDead) {
      _done = true;
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      if (p.age >= p.lifetime) continue;
      final t = (p.age / p.lifetime).clamp(0.0, 1.0);
      final opacity = 1.0 - math.pow(t, 2).toDouble();

      canvas.save();
      canvas.translate(p.position.x, p.position.y);
      canvas.rotate(p.rotation);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.width, height: p.height),
        paint,
      );
      canvas.restore();
    }
  }
}

class _Confetti {
  Vector2 position = Vector2.zero();
  final Vector2 velocity;
  final double gravity;
  final double lifetime;
  final double width;
  final double height;
  final Color color;
  final double rotationSpeed;
  double age = 0;
  double rotation = 0;

  _Confetti({
    required this.velocity,
    required this.gravity,
    required this.lifetime,
    required this.width,
    required this.height,
    required this.color,
    required this.rotationSpeed,
  });
}
