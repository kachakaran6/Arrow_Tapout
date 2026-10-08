import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arrowtapout/design/primitives.dart';
import 'package:arrowtapout/engine/board_state.dart';
import 'package:arrowtapout/engine/dir.dart';
import 'package:arrowtapout/engine/level.dart';
import 'package:arrowtapout/engine/thread.dart';
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

  int? hintedThreadId;
  double? hintStartTimeMs;

  double? enterStartTimeMs;
  double enterTotalMs = 0.0;

  double _nowMs = 0.0;
  double get nowMs => _nowMs;

  bool get hasActiveAnimations =>
      exits.isNotEmpty ||
      blockeds.isNotEmpty ||
      hintedThreadId != null ||
      (enterStartTimeMs != null && (_nowMs - enterStartTimeMs!) < enterTotalMs);

  void setLevel(Level level, double cellSize) {
    geometries.clear();
    exits.clear();
    blockeds.clear();
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

  void triggerExit(int threadId, {required bool reduceMotion}) {
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

  void _ensureTicker() {
    if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _handleTick(Duration elapsed) {
    _nowMs = elapsed.inMicroseconds / 1000.0;

    // Prune finished exits
    final completedExits = <int>[];
    for (final exit in exits.values) {
      if (exit.isDone(_nowMs)) {
        completedExits.add(exit.threadId);
      }
    }
    for (final id in completedExits) {
      exits.remove(id);
    }

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
