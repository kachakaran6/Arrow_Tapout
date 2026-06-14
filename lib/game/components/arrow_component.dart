import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:arrowtapout/state/game_state.dart';
import 'package:arrowtapout/design/constants.dart';

class PathArrowComponent extends PositionComponent with TapCallbacks {
  final PathArrow arrow;
  final void Function(String arrowId) onTap;

  double _exitProgress = 0.0;
  bool _isExiting = false;
  double _shakeOffset = 0.0;
  bool _isShaking = false;

  PathArrowComponent({
    required this.arrow,
    required this.onTap,
  }) {
    // The component spans the entire board so its coordinate system matches the board grid directly
    size = Vector2.zero(); // Will be set by parent, or just keep it 0 and override containsLocalPoint
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    if (arrow.state == ArrowState.removed) return false;
    final halfCell = GameConstants.cellSize / 2;
    // Check if the point falls inside any of the path cells
    for (final coord in arrow.path) {
      final cx = coord.x * GameConstants.cellSize + halfCell;
      final cy = coord.y * GameConstants.cellSize + halfCell;
      final distSq = (point.x - cx) * (point.x - cx) + (point.y - cy) * (point.y - cy);
      if (distSq <= halfCell * halfCell) {
        return true;
      }
    }
    return false;
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap(arrow.id);
  }

  void playExitAnimation() {
    _isExiting = true;
  }

  void playBlockedAnimation() {
    _isShaking = true;
    _shakeOffset = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isExiting) {
      _exitProgress += dt * 10.0; // 10 cells per second
      if (_exitProgress > arrow.path.length + 10) {
        removeFromParent();
      }
    }
    if (_isShaking) {
      // simple shake
      _shakeOffset += dt * 50;
      if (_shakeOffset > 3.14159 * 2) {
        _isShaking = false;
        _shakeOffset = 0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (arrow.state == ArrowState.removed && !_isExiting) return;

    final paint = Paint()
      ..color = arrow.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = GameConstants.cellSize * 0.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _buildCurrentPath();
    
    canvas.save();
    if (_isShaking) {
      canvas.translate(0, 4 * (1 - (_shakeOffset/(3.14159*2))) * (math.sin(_shakeOffset * 4)));
    }
    canvas.drawPath(path, paint);

    // Draw arrowhead
    _drawArrowHead(canvas);
    canvas.restore();
  }

  Path _buildCurrentPath() {
    final p = Path();
    if (arrow.path.isEmpty) return p;

    // _exitProgress shifts the start and end of the drawn path forward
    final len = arrow.path.length.toDouble();
    final startD = _exitProgress;
    final endD = _exitProgress + len - 1;

    final startPt = _getPointOnPath(startD);
    p.moveTo(startPt.x, startPt.y);

    int firstNode = startD.ceil();
    int lastNode = endD.floor();

    for (int i = firstNode; i <= lastNode; i++) {
      final pt = _getPointOnPath(i.toDouble());
      p.lineTo(pt.x, pt.y);
    }

    final endPt = _getPointOnPath(endD);
    p.lineTo(endPt.x, endPt.y);

    return p;
  }

  void _drawArrowHead(Canvas canvas) {
    final len = arrow.path.length.toDouble();
    final endD = _exitProgress + len - 1;
    final endPt = _getPointOnPath(endD);
    
    final dir = arrow.direction;
    final paint = Paint()
      ..color = arrow.color
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(endPt.x, endPt.y);
    canvas.rotate(dir.angleRad);

    final s = GameConstants.cellSize * 0.35;
    final p = Path()
      ..moveTo(s, 0)
      ..lineTo(-s, s)
      ..lineTo(-s, -s)
      ..close();
    canvas.drawPath(p, paint);
    canvas.restore();
  }

  Vector2 _getPointOnPath(double d) {
    if (d <= 0) return _cellCenter(arrow.path.first);
    if (d >= arrow.path.length - 1) {
      final head = _cellCenter(arrow.head);
      final dir = arrow.direction;
      final over = d - (arrow.path.length - 1);
      return head + Vector2(dir.dx * GameConstants.cellSize * over, dir.dy * GameConstants.cellSize * over);
    }

    int idx = d.floor();
    double frac = d - idx;
    final p1 = _cellCenter(arrow.path[idx]);
    final p2 = _cellCenter(arrow.path[idx + 1]);
    return p1 + (p2 - p1) * frac;
  }

  Vector2 _cellCenter(GridCoord c) {
    return Vector2(
      c.x * GameConstants.cellSize + GameConstants.cellSize / 2,
      c.y * GameConstants.cellSize + GameConstants.cellSize / 2,
    );
  }
}
