import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arrowtapout/design/primitives.dart';
import 'package:arrowtapout/engine/board_state.dart';
import 'package:arrowtapout/engine/dir.dart';
import 'package:arrowtapout/engine/level.dart';
import 'package:arrowtapout/engine/thread.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

/// Pure math evaluation for the exit motion function p(u).
double calculateExitDisplacement({
  required double u,
  required double totalDistanceD,
  required double anticipationA,
}) {
  final clampedU = u.clamp(0.0, 1.0);
  final mainSlide = totalDistanceD * math.pow(clampedU, 2.2);
  final sinTerm = math.sin(math.pi * math.min(clampedU / 0.20, 1.0));
  final pullback = anticipationA * sinTerm * sinTerm;
  return mainSlide - pullback;
}

/// Cached geometry and extended path metrics for a thread in the lattice model.
class ThreadGeometry {
  ThreadGeometry({
    required this.thread,
    required this.cellSize,
    required this.rows,
    required this.cols,
  }) {
    _buildPaths();
  }

  final Thread thread;
  final double cellSize;
  final int rows;
  final int cols;

  late final ui.Path basePath;
  late final ui.Path extendedPath;
  late final ui.PathMetric extendedMetric;
  late final double threadLengthPx;
  late final double rayPx;
  late final double totalDistanceD;
  late final double anticipationA;
  late final double stubLengthPx;
  late final double durationMs;

  void _buildPaths() {
    threadLengthPx = (thread.cells.length - 1) * cellSize;
    stubLengthPx = 0.3 * cellSize;
    anticipationA = 0.16 * cellSize;

    // Ray distance from head node to lattice edge
    final head = thread.head;
    rayPx = switch (thread.dir) {
      Dir.up => head.r * cellSize,
      Dir.down => (rows - 1 - head.r) * cellSize,
      Dir.left => head.c * cellSize,
      Dir.right => (cols - 1 - head.c) * cellSize,
    };

    totalDistanceD = rayPx + threadLengthPx + 0.6 * cellSize;
    durationMs =
        (300.0 + 9.0 * (totalDistanceD / cellSize)).clamp(340.0, 820.0);

    // 1. Base path: node to node
    basePath = ui.Path();
    final first = thread.cells.first;
    basePath.moveTo(first.c * cellSize, first.r * cellSize);
    for (var i = 1; i < thread.cells.length; i++) {
      final c = thread.cells[i];
      basePath.lineTo(c.c * cellSize, c.r * cellSize);
    }

    // 2. Extended path: backward stub + thread path + ray + extra run
    extendedPath = ui.Path();

    // Opposite direction of first segment (tail direction)
    final p0 = thread.cells[0];
    final p1 = thread.cells[1];
    final oppDx = (p0.c - p1.c).toDouble();
    final oppDy = (p0.r - p1.r).toDouble();

    // Backward stub start
    final stubStartX = p0.c * cellSize + oppDx * stubLengthPx;
    final stubStartY = p0.r * cellSize + oppDy * stubLengthPx;
    extendedPath.moveTo(stubStartX, stubStartY);
    extendedPath.lineTo(p0.c * cellSize, p0.r * cellSize);

    // Thread body
    for (var i = 1; i < thread.cells.length; i++) {
      final c = thread.cells[i];
      extendedPath.lineTo(c.c * cellSize, c.r * cellSize);
    }

    // Straight ray from head to grid boundary
    final edgeNodeC = switch (thread.dir) {
      Dir.left => 0.0,
      Dir.right => (cols - 1).toDouble(),
      _ => head.c.toDouble(),
    };
    final edgeNodeR = switch (thread.dir) {
      Dir.up => 0.0,
      Dir.down => (rows - 1).toDouble(),
      _ => head.r.toDouble(),
    };
    extendedPath.lineTo(edgeNodeC * cellSize, edgeNodeR * cellSize);

    // Extra run: 0.6 * cell + threadLengthPx beyond edge
    final extraRun = 0.6 * cellSize + threadLengthPx;
    final finalX = edgeNodeC * cellSize + thread.dir.dx * extraRun;
    final finalY = edgeNodeR * cellSize + thread.dir.dy * extraRun;
    extendedPath.lineTo(finalX, finalY);

    final metrics = extendedPath.computeMetrics().toList();
    extendedMetric = metrics.first;
  }
}

/// Active exit animation state for one thread.
class ActiveExit {
  ActiveExit({
    required this.threadId,
    required this.geometry,
    required this.durationMs,
    required this.startTimeMs,
    required this.reduceMotion,
  });

  final int threadId;
  final ThreadGeometry geometry;
  final double durationMs;
  final double startTimeMs;
  final bool reduceMotion;

  double progress(double nowMs) {
    if (durationMs <= 0) return 1.0;
    return ((nowMs - startTimeMs) / durationMs).clamp(0.0, 1.0);
  }

  double displacement(double nowMs) {
    final u = progress(nowMs);
    return calculateExitDisplacement(
      u: u,
      totalDistanceD: geometry.totalDistanceD,
      anticipationA: geometry.anticipationA,
    );
  }

  double alpha(double nowMs) {
    final u = progress(nowMs);
    if (reduceMotion) {
      return (1.0 - u).clamp(0.0, 1.0);
    }
    if (u >= 0.85) {
      return ((1.0 - u) / 0.15).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  bool isDone(double nowMs) => progress(nowMs) >= 1.0;
}

/// Active blocked bounce animation state.
class ActiveBlocked {
  ActiveBlocked({
    required this.threadId,
    required this.blockerId,
    required this.distanceNodes,
    required this.cellSize,
    required this.startTimeMs,
    required this.reduceMotion,
  })  : maxNudgePx =
            math.min(0.45, math.max(0.12, distanceNodes - 0.6)) * cellSize,
        _spring = SpringSimulation(
          const SpringDescription(mass: 1.0, stiffness: 420.0, damping: 26.0),
          math.min(0.45, math.max(0.12, distanceNodes - 0.6)) * cellSize,
          0.0,
          0.0,
        );

  final int threadId;
  final int blockerId;
  final int distanceNodes;
  final double cellSize;
  final double startTimeMs;
  final bool reduceMotion;
  final double maxNudgePx;
  final SpringSimulation _spring;

  static const double forwardMs = 90.0;
  static const double totalMs = 370.0;

  double displacementPx(double nowMs) {
    if (reduceMotion) return 0.0;
    final elapsed = nowMs - startTimeMs;
    if (elapsed <= 0) return 0.0;

    if (elapsed < forwardMs) {
      final t = elapsed / forwardMs;
      final easeOut = 1.0 - math.pow(1.0 - t, 3).toDouble();
      return maxNudgePx * easeOut;
    } else {
      final springTime = (elapsed - forwardMs) / 1000.0;
      return _spring.x(springTime);
    }
  }

  double tappedDangerLerp(double nowMs) {
    final p = ((nowMs - startTimeMs) / totalMs).clamp(0.0, 1.0);
    if (p < 0.25) return (p / 0.25) * 0.30;
    return (1.0 - (p - 0.25) / 0.75) * 0.30;
  }

  double blockerPulseLerp(double nowMs) {
    final p = ((nowMs - startTimeMs) / 420.0).clamp(0.0, 1.0);
    if (p < 0.35) return (p / 0.35) * 0.55;
    return (1.0 - (p - 0.35) / 0.65) * 0.55;
  }

  bool isDone(double nowMs) => (nowMs - startTimeMs) >= 420.0;
}

/// Particle emitted during exit slides and level completions.
class BoardParticle {
  BoardParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.startTimeMs,
    required this.maxLifeMs,
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final ui.Color color;
  final double size;
  final double startTimeMs;
  final double maxLifeMs;

  double progress(double nowMs) =>
      ((nowMs - startTimeMs) / maxLifeMs).clamp(0.0, 1.0);

  double alpha(double nowMs) {
    final p = progress(nowMs);
    return (1.0 - p).clamp(0.0, 1.0);
  }

  ui.Offset currentPos(double nowMs) {
    final t = (nowMs - startTimeMs) / 1000.0;
    return ui.Offset(x + vx * t, y + vy * t);
  }

  bool isDone(double nowMs) => (nowMs - startTimeMs) >= maxLifeMs;
}

/// Expanding circular shockwave ripple on tapout launch or level completion.
class BoardRipple {
  BoardRipple({
    required this.center,
    required this.maxRadius,
    required this.color,
    required this.startTimeMs,
    this.durationMs = 380.0,
  });

  final ui.Offset center;
  final double maxRadius;
  final ui.Color color;
  final double startTimeMs;
  final double durationMs;

  double progress(double nowMs) =>
      ((nowMs - startTimeMs) / durationMs).clamp(0.0, 1.0);

  double currentRadius(double nowMs) {
    final p = progress(nowMs);
    return maxRadius * Curves.easeOutCubic.transform(p);
  }

  double alpha(double nowMs) {
    final p = progress(nowMs);
    return (1.0 - p).clamp(0.0, 1.0);
  }

  bool isDone(double nowMs) => (nowMs - startTimeMs) >= durationMs;
}

/// Controller and animator driving all dynamic rendering on a single Ticker as a ChangeNotifier.
class BoardAnimator extends ChangeNotifier {
  BoardAnimator({
    required TickerProvider vsync,
  }) {
    _ticker = vsync.createTicker(_handleTick);
  }

  late final Ticker _ticker;

  final Map<int, ThreadGeometry> geometries = {};
  final Map<int, ActiveExit> exits = {};
  final Map<int, ActiveBlocked> blockeds = {};
  final List<BoardParticle> particles = [];
  final List<BoardRipple> ripples = [];

  int? hintedThreadId;
  double? hintStartTimeMs;

  double? enterStartTimeMs;
  double enterTotalMs = 0.0;

  double _nowMs = 0.0;
  double get nowMs => _nowMs;

  final math.Random _rng = math.Random();

  bool get hasActiveAnimations =>
      exits.isNotEmpty ||
      blockeds.isNotEmpty ||
      particles.isNotEmpty ||
      ripples.isNotEmpty ||
      hintedThreadId != null ||
      (enterStartTimeMs != null && (_nowMs - enterStartTimeMs!) < enterTotalMs);

  void setLevel(Level level, double cellSize) {
    geometries.clear();
    exits.clear();
    blockeds.clear();
    particles.clear();
    ripples.clear();
    hintedThreadId = null;
    hintStartTimeMs = null;
    enterStartTimeMs = null;

    for (final t in level.threads) {
      geometries[t.id] = ThreadGeometry(
        thread: t,
        cellSize: cellSize,
        rows: level.rows,
        cols: level.cols,
      );
    }
  }

  void startEntrance(int threadCount, {required bool reduceMotion}) {
    if (reduceMotion) {
      enterStartTimeMs = null;
      return;
    }
    enterTotalMs = math.min(threadCount * 8.0 + 360.0, 600.0);
    enterStartTimeMs = _nowMs;
    _ensureTicker();
  }

  double entranceProgressFor(int threadIndex, {required bool reduceMotion}) {
    if (reduceMotion || enterStartTimeMs == null) return 1.0;
    final elapsed = _nowMs - enterStartTimeMs!;
    final delay = threadIndex * 8.0;
    if (elapsed < delay) return 0.0;
    const duration = 360.0;
    final p = ((elapsed - delay) / duration).clamp(0.0, 1.0);
    return Primitives.curveEnter.transform(p);
  }

  void triggerExit(
    int threadId, {
    required bool reduceMotion,
    ui.Color? particleColor,
  }) {
    final geom = geometries[threadId];
    if (geom == null) return;

    final durationMs = reduceMotion ? 180.0 : geom.durationMs;

    exits[threadId] = ActiveExit(
      threadId: threadId,
      geometry: geom,
      durationMs: durationMs,
      startTimeMs: _nowMs,
      reduceMotion: reduceMotion,
    );

    if (hintedThreadId == threadId) {
      hintedThreadId = null;
    }

    // Spawn initial departure ripple at head node
    if (!reduceMotion) {
      final head = geom.thread.head;
      final headPos = ui.Offset(head.c * geom.cellSize, head.r * geom.cellSize);
      ripples.add(BoardRipple(
        center: headPos,
        maxRadius: geom.cellSize * 0.75,
        color: particleColor ?? const ui.Color(0xFFE07A5F),
        startTimeMs: _nowMs,
        durationMs: 340.0,
      ));

      // Spawn initial stardust burst at head
      for (var i = 0; i < 5; i++) {
        final angle = _rng.nextDouble() * 2 * math.pi;
        final speed = 30.0 + _rng.nextDouble() * 50.0;
        particles.add(BoardParticle(
          x: headPos.dx,
          y: headPos.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          color: particleColor ?? const ui.Color(0xFFE07A5F),
          size: 2.0 + _rng.nextDouble() * 2.2,
          startTimeMs: _nowMs,
          maxLifeMs: 280.0 + _rng.nextDouble() * 160.0,
        ));
      }
    }

    _ensureTicker();
    notifyListeners();
  }

  void triggerBlocked({
    required int threadId,
    required Blocker blocker,
    required double cellSize,
    required bool reduceMotion,
  }) {
    blockeds[threadId] = ActiveBlocked(
      threadId: threadId,
      blockerId: blocker.id,
      distanceNodes: blocker.distanceCells,
      cellSize: cellSize,
      startTimeMs: _nowMs,
      reduceMotion: reduceMotion,
    );

    _ensureTicker();
    notifyListeners();
  }

  void triggerHint(int threadId) {
    hintedThreadId = threadId;
    hintStartTimeMs = _nowMs;
    _ensureTicker();
    notifyListeners();
  }

  void triggerVictoryCelebration({
    required ui.Offset center,
    required double radius,
    required List<ui.Color> palette,
  }) {
    // Expanding rings
    ripples.add(BoardRipple(
      center: center,
      maxRadius: radius * 1.2,
      color: palette.first,
      startTimeMs: _nowMs,
      durationMs: 650.0,
    ));
    ripples.add(BoardRipple(
      center: center,
      maxRadius: radius * 0.85,
      color: palette.length > 1 ? palette[1] : palette.first,
      startTimeMs: _nowMs + 120.0,
      durationMs: 600.0,
    ));

    // Particle sparklers burst
    for (var i = 0; i < 36; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 70.0 + _rng.nextDouble() * 160.0;
      final col = palette[_rng.nextInt(palette.length)];
      particles.add(BoardParticle(
        x: center.dx + (math.cos(angle) * 8.0),
        y: center.dy + (math.sin(angle) * 8.0),
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 15.0,
        color: col,
        size: 2.5 + _rng.nextDouble() * 3.0,
        startTimeMs: _nowMs,
        maxLifeMs: 500.0 + _rng.nextDouble() * 350.0,
      ));
    }

    _ensureTicker();
    notifyListeners();
  }

  void _ensureTicker() {
    if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _handleTick(Duration elapsed) {
    _nowMs = elapsed.inMicroseconds / 1000.0;

    // Prune finished exits and emit trailing speed particles
    final completedExits = <int>[];
    for (final exit in exits.values) {
      if (exit.isDone(_nowMs)) {
        completedExits.add(exit.threadId);
      } else if (!exit.reduceMotion && _rng.nextDouble() < 0.40) {
        // Emit subtle trail whisper
        final geom = exit.geometry;
        final disp = exit.displacement(_nowMs);
        final tailOffset = (geom.stubLengthPx + disp)
            .clamp(0.001, geom.extendedMetric.length - 0.001);
        final tangent = geom.extendedMetric.getTangentForOffset(tailOffset);
        if (tangent != null) {
          particles.add(BoardParticle(
            x: tangent.position.dx + (_rng.nextDouble() - 0.5) * 4.0,
            y: tangent.position.dy + (_rng.nextDouble() - 0.5) * 4.0,
            vx: -tangent.vector.dx * 20.0 + (_rng.nextDouble() - 0.5) * 15.0,
            vy: -tangent.vector.dy * 20.0 + (_rng.nextDouble() - 0.5) * 15.0,
            color: const ui.Color(0xFFE07A5F).withValues(alpha: 0.7),
            size: 1.8 + _rng.nextDouble() * 1.5,
            startTimeMs: _nowMs,
            maxLifeMs: 220.0 + _rng.nextDouble() * 120.0,
          ));
        }
      }
    }
    for (final id in completedExits) {
      exits.remove(id);
    }

    // Prune particles
    particles.removeWhere((p) => p.isDone(_nowMs));

    // Prune ripples
    ripples.removeWhere((r) => r.isDone(_nowMs));

    // Prune finished blocked bounces
    final completedBlockeds = <int>[];
    for (final b in blockeds.values) {
      if (b.isDone(_nowMs)) {
        completedBlockeds.add(b.threadId);
      }
    }
    for (final id in completedBlockeds) {
      blockeds.remove(id);
    }

    // Prune hint if expired (>2200ms)
    if (hintStartTimeMs != null && (_nowMs - hintStartTimeMs!) >= 2200.0) {
      hintedThreadId = null;
      hintStartTimeMs = null;
    }

    notifyListeners();

    if (!hasActiveAnimations && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
