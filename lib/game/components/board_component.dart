import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';

import 'package:arrowtapout/state/game_state.dart';
import 'package:arrowtapout/game/components/arrow_component.dart';
import 'package:arrowtapout/game/components/particle_trail.dart';
import 'package:arrowtapout/design/colors.dart';
import 'package:arrowtapout/design/constants.dart';

/// The game board — renders the grid and owns all PathArrowComponents
class BoardComponent extends PositionComponent {
  final GameState initialState;
  final void Function(String arrowId) onArrowTap;

  final Map<String, PathArrowComponent> _arrowComponents = {};

  // Ambient board float
  double _floatTime = 0;
  double _floatOffset = 0;

  BoardComponent({
    required this.initialState,
    required this.onArrowTap,
    required Vector2 position,
  }) : super(position: position) {
    size = Vector2(
      initialState.gridCols * GameConstants.cellSize,
      initialState.gridRows * GameConstants.cellSize,
    );
  }

  @override
  Future<void> onLoad() async {
    // Spawn all arrow components
    for (final arrow in initialState.arrows) {
      if (arrow.state != ArrowState.removed) {
        _spawnArrow(arrow);
      }
    }
  }

  void _spawnArrow(PathArrow arrow) {
    final comp = PathArrowComponent(
      arrow: arrow,
      onTap: onArrowTap,
    );
    comp.size = size; // Span entire board
    _arrowComponents[arrow.id] = comp;
    add(comp);
  }

  /// Called when game state updates — sync arrow states and handle removals
  void syncState(GameState newState, GameState oldState) {
    for (final arrow in newState.arrows) {
      if (arrow.state == ArrowState.removed) {
        final comp = _arrowComponents[arrow.id];
        if (comp != null && comp.parent != null) {
          // Check if old state had it as non-removed (just removed this frame)
          final oldArrow = oldState.arrows.where((a) => a.id == arrow.id).firstOrNull;
          if (oldArrow != null && oldArrow.state != ArrowState.removed) {
            // Arrow was just removed
            _onArrowRemoved(arrow, comp);
          }
        }
      }
    }
  }

  void _onArrowRemoved(PathArrow arrow, PathArrowComponent comp) {
    // Play exit animation on the component
    comp.playExitAnimation();

    // Particle trail on the head (optional, maybe not needed for paths, but let's add one)
    final head = arrow.head;
    final trailPos = Vector2(
      head.x * GameConstants.cellSize + GameConstants.cellSize / 2,
      head.y * GameConstants.cellSize + GameConstants.cellSize / 2,
    );
    
    // Using particle trail but adapting direction
    final trail = ParticleTrailComponent(
      position: trailPos,
      direction: arrow.direction,
      arrowColor: arrow.color,
    );
    add(trail);
  }

  /// Play blocked animation for a specific arrow
  void playBlockedAnimation(String arrowId) {
    _arrowComponents[arrowId]?.playBlockedAnimation();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _floatTime += dt * 1000;
    // Y offset: 0→8→0, 3000ms loop
    final floatCycle = (_floatTime / GameConstants.boardFloatMs) * math.pi * 2;
    _floatOffset = 8.0 * ((math.sin(floatCycle) + 1) / 2);
    position.y = _baseY + _floatOffset;
  }

  double _baseY = 0;

  void setBasePosition(double x, double y) {
    _baseY = y;
    position = Vector2(x, y);
  }

  @override
  void render(Canvas canvas) {
    _renderGrid(canvas);
    super.render(canvas);
  }

  void _renderGrid(Canvas canvas) {
    // Optionally render a light grid for debugging or aesthetics
    final dotPaint = Paint()
      ..color = GameColors.borderGlow
      ..style = PaintingStyle.fill;

    final cols = initialState.gridCols;
    final rows = initialState.gridRows;

    // Dot grid: small circles at each cell center
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        final cx = c * GameConstants.cellSize + GameConstants.cellSize / 2;
        final cy = r * GameConstants.cellSize + GameConstants.cellSize / 2;
        canvas.drawCircle(Offset(cx, cy), 2.0, dotPaint);
      }
    }
  }
}
