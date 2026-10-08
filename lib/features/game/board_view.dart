import 'package:arrowtapout/design/app_tokens.dart';
import 'package:arrowtapout/design/component_tokens.dart';
import 'package:arrowtapout/engine/level.dart';
import 'package:arrowtapout/features/game/board_painter.dart';
import 'package:arrowtapout/features/game/hit_tester.dart';
import 'package:arrowtapout/features/game/thread_animator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Interactive board view widget rendering the thread puzzle with lattice model and unified painter.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.level,
    required this.activeIds,
    required this.animator,
    required this.onThreadTap,
    this.reduceMotion = false,
    this.interactive = true,
  });

  final Level level;
  final Set<int> activeIds;
  final BoardAnimator animator;
  final ValueChanged<int> onThreadTap;
  final bool reduceMotion;
  final bool interactive;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  late BoardHitTester _hitTester;
  final TransformationController _transformController =
      TransformationController();

  Offset? _pointerDownPos;
  DateTime? _pointerDownTime;
  int _activePointers = 0;
  double _lastCellSize = 0.0;

  @override
  void initState() {
    super.initState();
    _hitTester = BoardHitTester(widget.level);
  }

  @override
  void didUpdateWidget(covariant BoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _hitTester = BoardHitTester(widget.level);
      _transformController.value = Matrix4.identity();
      _lastCellSize = 0.0;
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers++;
    _pointerDownPos = event.localPosition;
    _pointerDownTime = DateTime.now();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
    _pointerDownPos = null;
    _pointerDownTime = null;
  }

  void _handlePointerUp(PointerUpEvent event, double cellSize) {
    final downPos = _pointerDownPos;
    final downTime = _pointerDownTime;
    final pointerCount = _activePointers;
    _activePointers = (_activePointers - 1).clamp(0, 10);
    _pointerDownPos = null;
    _pointerDownTime = null;

    if (!widget.interactive ||
        downPos == null ||
        downTime == null ||
        pointerCount > 1) {
      return;
    }

    final elapsedMs = DateTime.now().difference(downTime).inMilliseconds;
    final dist = (event.localPosition - downPos).distance;

    // Fast tap: moved < kTouchSlop and duration < 400ms
    if (dist <= kTouchSlop && elapsedMs < 400) {
      final hitId = _hitTester.hitTest(
        localPosition: event.localPosition,
        cellSize: cellSize,
        activeThreadIds: widget.activeIds,
      );

      if (hitId != null) {
        widget.onThreadTap(hitId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = ComponentTokens.computeLatticeCellSize(
          screenWidth: constraints.maxWidth,
          boardRegionHeight: constraints.maxHeight,
          rows: widget.level.rows,
          cols: widget.level.cols,
          devicePixelRatio: dpr,
        );

        if (_lastCellSize != cellSize) {
          _lastCellSize = cellSize;
          widget.animator.setLevel(widget.level, cellSize);
        }

        final boardW = (widget.level.cols - 1) * cellSize;
        final boardH = (widget.level.rows - 1) * cellSize;
        final needsPinchZoom = cellSize < ComponentTokens.zoomThresholdCellSize;

        Widget boardWidget = Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _handlePointerDown,
          onPointerCancel: _handlePointerCancel,
          onPointerUp: (event) => _handlePointerUp(event, cellSize),
          child: SizedBox(
            width: boardW,
            height: boardH,
            child: Semantics(
              label: 'Puzzle board, ${widget.activeIds.length} threads left',
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(boardW, boardH),
                  painter: BoardPainter(
                    level: widget.level,
                    activeIds: widget.activeIds,
                    cellSize: cellSize,
                    tokens: tokens,
                    animator: widget.animator,
                    reduceMotion: widget.reduceMotion,
                  ),
                ),
              ),
            ),
          ),
        );

        if (needsPinchZoom) {
          boardWidget = InteractiveViewer(
            transformationController: _transformController,
            minScale: 1.0,
            maxScale: 3.0,
            onInteractionStart: (details) {
              if (details.pointerCount > 1) {
                _pointerDownPos = null;
              }
            },
            boundaryMargin: const EdgeInsets.all(24.0),
            child: Center(
              child: Transform.translate(
                offset: Offset(0, -0.02 * constraints.maxHeight),
                child: boardWidget,
              ),
            ),
          );
        } else {
          boardWidget = Center(
            child: Transform.translate(
              offset: Offset(0, -0.02 * constraints.maxHeight),
              child: boardWidget,
            ),
          );
        }

        return boardWidget;
      },
    );
  }
}
