import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arrowtapout/engine/dir.dart';
import 'package:arrowtapout/engine/thread.dart';
import 'package:flutter/animation.dart';

/// Pure mathematical evaluation for the extraction displacement along the track.
double calculateExitDisplacement({
  required double u,
  required double totalDistanceD,
  double anticipationA = 0.0,
}) {
  final clampedU = u.clamp(0.0, 1.0);
  final eased = Curves.easeInOutCubic.transform(clampedU);
  return totalDistanceD * eased;
}

/// Instantaneous geometric state of an arrow being extracted along its path.
class ExtractedGeometry {
  const ExtractedGeometry({
    required this.visiblePath,
    required this.headPosition,
    required this.headAngleRad,
    required this.alpha,
    required this.isCompleted,
    required this.displacementPx,
  });

  /// The continuous sub-path polyline that is currently visible on the board.
  final ui.Path visiblePath;

  /// The leading position of the arrowhead tip in pixel coordinates.
  final ui.Offset headPosition;

  /// The orientation of the arrowhead in radians (tangent of the path).
  final double headAngleRad;

  /// Opacity multiplier for the thread (fades out as it clears the screen).
  final double alpha;

  /// Whether the arrow has completely exited the visible viewport.
  final bool isCompleted;

  /// Arc-length displacement distance traveled so far in pixels.
  final double displacementPx;
}

/// A pre-computed, continuous extraction track for an arrow polyline.
///
/// Follows the complete piecewise trajectory from tail -> head -> exit ray -> off-screen boundary.
class ExtractionTrack {
  ExtractionTrack({
    required this.thread,
    required this.cellSize,
    required this.rows,
    required this.cols,
  }) {
    _buildTrack();
  }

  final Thread thread;
  final double cellSize;
  final int rows;
  final int cols;

  late final ui.Path fullTrackPath;
  late final ui.PathMetric trackMetric;
  late final double threadLengthPx;
  late final double rayLengthPx;
  late final double totalDistanceD;
  late final double durationMs;

  void _buildTrack() {
    threadLengthPx = (thread.cells.length - 1) * cellSize;

    final head = thread.head;
    rayLengthPx = switch (thread.dir) {
      Dir.up => head.r * cellSize,
      Dir.down => (rows - 1 - head.r) * cellSize,
      Dir.left => head.c * cellSize,
      Dir.right => (cols - 1 - head.c) * cellSize,
    };

    // Extra distance beyond lattice boundary to guarantee full tail exit
    final extraRun = 1.6 * cellSize + threadLengthPx;
    totalDistanceD = rayLengthPx + extraRun;

    // Build the continuous polyline track:
    // Tail -> internal vertices -> Head -> Grid edge -> Off-screen infinity
    fullTrackPath = ui.Path();
    final first = thread.cells.first;
    fullTrackPath.moveTo(first.c * cellSize, first.r * cellSize);

    for (var i = 1; i < thread.cells.length; i++) {
      final c = thread.cells[i];
      fullTrackPath.lineTo(c.c * cellSize, c.r * cellSize);
    }

    // Edge node coordinate along exit ray
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
    fullTrackPath.lineTo(edgeNodeC * cellSize, edgeNodeR * cellSize);

    // Final off-screen point
    final finalX = edgeNodeC * cellSize + thread.dir.dx * extraRun;
    final finalY = edgeNodeR * cellSize + thread.dir.dy * extraRun;
    fullTrackPath.lineTo(finalX, finalY);

    final metrics = fullTrackPath.computeMetrics().toList();
    trackMetric = metrics.first;

    // Calibrated natural duration: 300ms to 420ms based on total exit travel
    durationMs =
        (300.0 + 6.0 * (totalDistanceD / cellSize)).clamp(320.0, 440.0);
  }

  /// Samples the path-aware extracted geometry at normalized animation progress [progress] (0.0 to 1.0).
  ExtractedGeometry sample(
    double progress, {
    bool reduceMotion = false,
    Curve curve = Curves.easeInOutCubic,
  }) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    if (reduceMotion) {
      // In reduced motion mode, fade the stationary polyline in place
      final alpha = (1.0 - clampedProgress).clamp(0.0, 1.0);
      final head = thread.head;
      final headPos = ui.Offset(head.c * cellSize, head.r * cellSize);
      final angle = _dirToAngle(thread.dir);

      final basePath = ui.Path();
      basePath.moveTo(
          thread.cells.first.c * cellSize, thread.cells.first.r * cellSize);
      for (var i = 1; i < thread.cells.length; i++) {
        basePath.lineTo(
            thread.cells[i].c * cellSize, thread.cells[i].r * cellSize);
      }

      return ExtractedGeometry(
        visiblePath: basePath,
        headPosition: headPos,
        headAngleRad: angle,
        alpha: alpha,
        isCompleted: clampedProgress >= 1.0,
        displacementPx: 0.0,
      );
    }

    final eased = curve.transform(clampedProgress);
    final exitTravel = trackMetric.length - threadLengthPx;
    final displacement = eased * exitTravel;

    final startOffset = displacement.clamp(0.0, trackMetric.length);
    final endOffset =
        (displacement + threadLengthPx).clamp(0.0, trackMetric.length);

    // Extract the exact continuous sub-path polyline
    final visiblePath = (endOffset > startOffset)
        ? trackMetric.extractPath(startOffset, endOffset)
        : ui.Path();

    // Sample the exact tangent coordinate and orientation for the leading arrowhead
    final sampleOffset = endOffset.clamp(0.001, trackMetric.length - 0.001);
    final tangent = trackMetric.getTangentForOffset(sampleOffset);

    final headPos = tangent?.position ??
        ui.Offset(thread.head.c * cellSize, thread.head.r * cellSize);

    final headAngle = tangent != null
        ? math.atan2(tangent.vector.dy, tangent.vector.dx)
        : _dirToAngle(thread.dir);

    // Smooth alpha fadeout in the final 25% of the slide
    final alpha = clampedProgress >= 0.75
        ? ((1.0 - clampedProgress) / 0.25).clamp(0.0, 1.0)
        : 1.0;

    return ExtractedGeometry(
      visiblePath: visiblePath,
      headPosition: headPos,
      headAngleRad: headAngle,
      alpha: alpha,
      isCompleted: clampedProgress >= 1.0,
      displacementPx: displacement,
    );
  }

  static double _dirToAngle(Dir dir) => switch (dir) {
        Dir.right => 0.0,
        Dir.down => math.pi / 2.0,
        Dir.left => math.pi,
        Dir.up => -math.pi / 2.0,
      };
}
