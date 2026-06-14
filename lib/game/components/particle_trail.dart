import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:arrowtapout/state/game_state.dart';
import 'package:arrowtapout/design/constants.dart';

/// A single particle in the exit trail
class _Particle {
  Vector2 position;
  Vector2 velocity;
  double lifetime;
  double age = 0;
  double size;
  Color color;
  bool isGlow;

  _Particle({
    required this.position,
    required this.velocity,
    required this.lifetime,
    required this.size,
    required this.color,
    required this.isGlow,
  });
}

/// Particle trail emitted when an arrow exits
class ParticleTrailComponent extends PositionComponent {
  final ArrowDirection direction;
  final Color arrowColor;
  late List<_Particle> _particles;
  bool _done = false;

  ParticleTrailComponent({
    required Vector2 position,
    required this.direction,
    required this.arrowColor,
  }) : super(position: position);

  @override
  Future<void> onLoad() async {
    _particles = _generateParticles();
  }

  List<_Particle> _generateParticles() {
    final rng = math.Random();
    final baseAngle = math.atan2(
      direction.dy.toDouble(),
      direction.dx.toDouble(),
    );
    final spreadRad = GameConstants.trailSpreadAngleDeg * (math.pi / 180);
    final count = GameConstants.trailParticleCount;
    final particles = <_Particle>[];

    for (int i = 0; i < count; i++) {
      final isGlow = rng.nextDouble() < 0.3; // 30% glow particles
      final angle = baseAngle + (rng.nextDouble() * 2 - 1) * spreadRad;
      final speed = 80 + rng.nextDouble() * 60; // 80–140 px/s
      final lifetime = (GameConstants.trailLifetimeMinMs +
              rng.nextInt(GameConstants.trailLifetimeMaxMs - GameConstants.trailLifetimeMinMs))
          .toDouble();

      particles.add(_Particle(
        position: Vector2.zero(),
        velocity: Vector2(
          math.cos(angle) * speed,
          math.sin(angle) * speed,
        ),
        lifetime: lifetime,
        size: isGlow ? 8 + rng.nextDouble() * 4 : 3 + rng.nextDouble() * 3,
        color: arrowColor,
        isGlow: isGlow,
      ));
    }
    return particles;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_done) return;

    bool allDead = true;
    for (final p in _particles) {
      p.age += dt * 1000; // convert to ms
      if (p.age < p.lifetime) {
        p.position += p.velocity * dt;
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
      final opacity = 1.0 - t;
      final currentSize = p.size * (1.0 - t);

      if (p.isGlow) {
        final glowPaint = Paint()
          ..color = p.color.withOpacity(opacity * 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(
          Offset(p.position.x, p.position.y),
          currentSize,
          glowPaint,
        );
      } else {
        final paint = Paint()
          ..color = p.color.withOpacity(opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(p.position.x, p.position.y),
          currentSize / 2,
          paint,
        );
      }
    }
  }
}
