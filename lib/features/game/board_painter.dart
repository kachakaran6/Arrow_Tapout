import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arrowtapout/design/app_tokens.dart';
import 'package:arrowtapout/engine/cell.dart';
import 'package:arrowtapout/engine/dir.dart';
import 'package:arrowtapout/engine/level.dart';
import 'package:arrowtapout/features/game/thread_animator.dart';
import 'package:flutter/material.dart';

/// Helper to draw an open chevron arrowhead at a tangent position with exact specs.
void drawChevronArrowhead({
  required ui.Canvas canvas,
  required ui.Offset headPoint,
  required double angleRad,
  required double armLengthPx,
  required ui.Paint paint,
}) {
  // Half angle = 40 degrees
  const halfAngleRad = 40.0 * math.pi / 180.0;

  final leftAngle = angleRad + math.pi - halfAngleRad;
  final rightAngle = angleRad + math.pi + halfAngleRad;

  final leftP = ui.Offset(
    headPoint.dx + math.cos(leftAngle) * armLengthPx,
    headPoint.dy + math.sin(leftAngle) * armLengthPx,
  );
  final rightP = ui.Offset(
    headPoint.dx + math.cos(rightAngle) * armLengthPx,
    headPoint.dy + math.sin(rightAngle) * armLengthPx,
  );

  canvas.drawLine(headPoint, leftP, paint);
  canvas.drawLine(headPoint, rightP, paint);
}

/// Unified Board Painter rendering the lattice dots and all threads on a single ticker.
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.level,
    required this.activeIds,
    required this.cellSize,
    required this.tokens,
    required this.animator,
    required this.reduceMotion,
  })  : _maskAdjacentNodes = _computeMaskNodes(level),
        super(repaint: animator);

  final Level level;
  final Set<int> activeIds;
  final double cellSize;
  final AppTokens tokens;
  final BoardAnimator animator;
  final bool reduceMotion;
  final Set<Cell> _maskAdjacentNodes;

  final Paint _threadPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  final Paint _hintPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  final Paint _dotPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  static Set<Cell> _computeMaskNodes(Level level) {
    if (level.shape == 'rect') {
      return const {};
    }
    final occupied = <Cell>{};
    for (final t in level.threads) {
      occupied.addAll(t.cells);
    }
    final mask = <Cell>{};
    for (final cell in occupied) {
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          final r = cell.r + dr;
          final c = cell.c + dc;
          if (r >= 0 && r < level.rows && c >= 0 && c < level.cols) {
            mask.add(Cell(r, c));
          }
        }
      }
    }
    return mask;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = (cellSize * 0.06).clamp(1.6, 2.4);
    final armLength = (cellSize * 0.23).clamp(4.0, 9.0);
    final dotRadius = (cellSize * 0.04).clamp(1.0, 1.6);
    final nowMs = animator.nowMs;

    _threadPaint.strokeWidth = strokeWidth;
    _dotPaint.color = tokens.gridDot;

    // 1. Draw lattice grid dots
    if (level.shape == 'rect') {
      for (var r = 0; r < level.rows; r++) {
        for (var c = 0; c < level.cols; c++) {
          canvas.drawCircle(
            Offset(c * cellSize, r * cellSize),
            dotRadius,
            _dotPaint,
          );
        }
      }
    } else {
      for (final cell in _maskAdjacentNodes) {
        canvas.drawCircle(
          Offset(cell.c * cellSize, cell.r * cellSize),
          dotRadius,
          _dotPaint,
        );
      }
    }

    // 2. Hint outline under hinted thread
    final hintedId = animator.hintedThreadId;
    if (hintedId != null && animator.hintStartTimeMs != null) {
      final geom = animator.geometries[hintedId];
      if (geom != null && activeIds.contains(hintedId)) {
        final elapsed = nowMs - animator.hintStartTimeMs!;
        var pulse = 0.55 +
            0.45 * (0.5 + 0.5 * math.sin((elapsed / 1600.0) * 2 * math.pi));
        if (elapsed > 2000.0) {
          final fadeOut = (1.0 - (elapsed - 2000.0) / 200.0).clamp(0.0, 1.0);
          pulse *= fadeOut;
        }

        _hintPaint
          ..strokeWidth = strokeWidth + 2.0
          ..color = tokens.accent.withValues(alpha: pulse.clamp(0.0, 1.0));

        canvas.drawPath(geom.basePath, _hintPaint);
      }
    }

    // 3. Paint all active / exiting threads
    var threadIndex = 0;
    for (final thread in level.threads) {
      final tid = thread.id;
      final isActive = activeIds.contains(tid);
      final activeExit = animator.exits[tid];
      final geom = animator.geometries[tid];

      if (geom == null || (!isActive && activeExit == null)) {
        threadIndex++;
        continue;
      }

      if (activeExit != null) {
        // --- Exiting thread animation ---
        final alpha = activeExit.alpha(nowMs);
        _threadPaint.color =
            tokens.thread.withValues(alpha: tokens.thread.a * alpha);

        if (reduceMotion) {
          // Fade in place
          canvas.drawPath(geom.basePath, _threadPaint);
          final headNode = thread.head;
          final headPoint =
              Offset(headNode.c * cellSize, headNode.r * cellSize);
          final angle = _dirToAngle(thread.dir);
          drawChevronArrowhead(
            canvas: canvas,
            headPoint: headPoint,
            angleRad: angle,
            armLengthPx: armLength,
            paint: _threadPaint,
          );
        } else {
          final disp = activeExit.displacement(nowMs);
          final windowStart = math.max(0.0, geom.stubLengthPx + disp);
          final windowEnd = math.min(
            geom.extendedMetric.length,
            geom.stubLengthPx + disp + geom.threadLengthPx,
          );

          if (windowEnd > windowStart) {
            final extracted =
                geom.extendedMetric.extractPath(windowStart, windowEnd);
            canvas.drawPath(extracted, _threadPaint);

            final headOffset = (geom.stubLengthPx + disp + geom.threadLengthPx)
                .clamp(0.001, geom.extendedMetric.length - 0.001);
            final tangent = geom.extendedMetric.getTangentForOffset(headOffset);
            if (tangent != null) {
              final angle = math.atan2(tangent.vector.dy, tangent.vector.dx);
              drawChevronArrowhead(
                canvas: canvas,
                headPoint: tangent.position,
                angleRad: angle,
                armLengthPx: armLength,
                paint: _threadPaint,
              );
            }
          }
        }
      } else {
        // --- Idle, Blocked, or Entering thread ---
        final activeBlocked = animator.blockeds[tid];
        var blockerPulseLerp = 0.0;
        for (final b in animator.blockeds.values) {
          if (b.blockerId == tid) {
            blockerPulseLerp =
                math.max(blockerPulseLerp, b.blockerPulseLerp(nowMs));
          }
        }

        if (activeBlocked != null) {
          // Blocked tapped thread
          final dispPx = activeBlocked.displacementPx(nowMs);
          final dangerLerp = activeBlocked.tappedDangerLerp(nowMs);
          _threadPaint.color =
              Color.lerp(tokens.thread, tokens.danger, dangerLerp)!;

          canvas.save();
          canvas.translate(
            thread.dir.dx * dispPx,
            thread.dir.dy * dispPx,
          );

          canvas.drawPath(geom.basePath, _threadPaint);

          final headNode = thread.head;
          final headPoint =
              Offset(headNode.c * cellSize, headNode.r * cellSize);
          final angle = _dirToAngle(thread.dir);
          drawChevronArrowhead(
            canvas: canvas,
            headPoint: headPoint,
            angleRad: angle,
            armLengthPx: armLength,
            paint: _threadPaint,
          );

          canvas.restore();
        } else {
          // Normal idle / blocker / entrance thread
          if (blockerPulseLerp > 0.0) {
            _threadPaint.color =
                Color.lerp(tokens.thread, tokens.danger, blockerPulseLerp)!;
          } else {
            _threadPaint.color = tokens.thread;
          }

          final entrance = animator.entranceProgressFor(
            threadIndex,
            reduceMotion: reduceMotion,
          );

          if (entrance >= 1.0) {
            canvas.drawPath(geom.basePath, _threadPaint);

            final headNode = thread.head;
            final headPoint =
                Offset(headNode.c * cellSize, headNode.r * cellSize);
            final angle = _dirToAngle(thread.dir);
            drawChevronArrowhead(
              canvas: canvas,
              headPoint: headPoint,
              angleRad: angle,
              armLengthPx: armLength,
              paint: _threadPaint,
            );
          } else if (entrance > 0.0) {
            final visibleLen = geom.threadLengthPx * entrance;
            final subPath = geom.extendedMetric.extractPath(
              geom.stubLengthPx,
              geom.stubLengthPx + visibleLen,
            );
            canvas.drawPath(subPath, _threadPaint);

            final tangent = geom.extendedMetric.getTangentForOffset(
              geom.stubLengthPx + visibleLen,
            );
            if (tangent != null) {
              final angle = math.atan2(tangent.vector.dy, tangent.vector.dx);
              drawChevronArrowhead(
                canvas: canvas,
                headPoint: tangent.position,
                angleRad: angle,
                armLengthPx: armLength,
                paint: _threadPaint,
              );
            }
          }
        }
      }

      threadIndex++;
    }
  }

  double _dirToAngle(Dir dir) => switch (dir) {
        Dir.right => 0.0,
        Dir.down => math.pi / 2.0,
        Dir.left => math.pi,
        Dir.up => -math.pi / 2.0,
      };

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.activeIds != activeIds ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.tokens != tokens ||
        oldDelegate.reduceMotion != reduceMotion;
  }
}
