
import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrowtapout/state/game_state.dart';
import 'package:arrowtapout/state/game_notifier.dart';
import 'package:arrowtapout/state/game_events.dart';
import 'package:arrowtapout/game/components/board_component.dart';
import 'package:arrowtapout/game/components/confetti_component.dart';
import 'package:arrowtapout/audio/audio_service.dart';
import 'package:arrowtapout/design/constants.dart';

/// Root Flame game — coordinates all game components
class ArrowTapOutGame extends FlameGame
    with PanDetector, ScaleDetector, DoubleTapDetector {
  final WidgetRef ref;

  late BoardComponent _board;
  GameState? _lastState;
  StreamSubscription<GameEvent>? _eventSubscription;

  // Camera control
  double _zoom = 1.0;
  Vector2 _cameraOffset = Vector2.zero();
  Vector2? _panStart;


  // Scale gesture
  double _scaleStart = 1.0;

  ArrowTapOutGame({required this.ref});

  @override
  Color backgroundColor() => const Color(0xFF0D0F1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize audio
    await AudioService().initialize();
    await AudioService().startAmbient();

    final initialState = ref.read(gameProvider);
    _lastState = initialState;

    _board = BoardComponent(
      initialState: initialState,
      onArrowTap: _onArrowTap,
      position: Vector2.zero(),
    );

    // Center board on screen
    _centerBoard();

    add(_board);

    // Subscribe to game events for audio + visual feedback
    _eventSubscription = ref.read(gameProvider.notifier).events.listen((event) {
      _handleEvent(event);
    });
  }

  @override
  void onRemove() {
    _eventSubscription?.cancel();
    super.onRemove();
  }

  void _centerBoard() {
    final boardW = GameConstants.gridCols * GameConstants.cellSize;
    final boardH = GameConstants.gridRows * GameConstants.cellSize;
    final centerX = (size.x - boardW) / 2;
    final centerY = (size.y - boardH) / 2;
    _cameraOffset = Vector2(centerX, centerY);
    _board.setBasePosition(centerX, centerY);
  }

  void _onArrowTap(String arrowId) {
    ref.read(gameProvider.notifier).tryRemoveArrow(arrowId);
  }

  void _handleEvent(GameEvent event) {
    final currentState = ref.read(gameProvider);

    switch (event) {
      case ArrowRemovedEvent _:
        AudioService().playPop();
        Future.delayed(const Duration(milliseconds: 30),
            () => AudioService().playWhoosh());
        if (_lastState != null) {
          _board.syncState(currentState, _lastState!);
        }

      case ArrowBlockedEvent e:
        AudioService().playThud();
        _board.playBlockedAnimation(e.arrow.id);

      case LevelCompleteEvent _:
        _playCompletionSequence();

      case LevelResetEvent _:
        _resetBoard();

      case ComboMilestoneEvent _:
        AudioService().playComboMilestone();
    }

    _lastState = currentState;
  }

  Future<void> _playCompletionSequence() async {
    AudioService().playLevelComplete();

    // Wait for last arrow animation
    await Future.delayed(const Duration(milliseconds: 300));

    // Confetti burst from center
    add(ConfettiComponent(center: Vector2(size.x / 2, size.y / 2)));

    // Show completion overlay
    await Future.delayed(const Duration(milliseconds: 200));
    overlays.add('levelComplete');
  }

  Future<void> _resetBoard() async {
    overlays.remove('levelComplete');

    _board.removeFromParent();
    _lastState = null;

    final initialState = ref.read(gameProvider);
    _lastState = initialState;

    _board = BoardComponent(
      initialState: initialState,
      onArrowTap: _onArrowTap,
      position: Vector2.zero(),
    );
    _centerBoard();
    add(_board);
  }



  // --- Gesture Handlers ---

  @override
  void onPanStart(DragStartInfo info) {
    _panStart = info.eventPosition.global;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_panStart != null) {
      final delta = info.eventPosition.global - _panStart!;
      _cameraOffset += delta;
      _board.position = _cameraOffset;
      _panStart = info.eventPosition.global;
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _panStart = null;
  }

  @override
  void onScaleStart(ScaleStartInfo info) {
    _scaleStart = _zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    final newZoom = (_scaleStart * info.scale.global.x)
        .clamp(GameConstants.cameraMinZoom, GameConstants.cameraMaxZoom);
    if ((newZoom - _zoom).abs() > 0.001) {
      _zoom = newZoom;
      _board.scale = Vector2.all(_zoom);
    }
  }

  @override
  void onDoubleTapDown(TapDownInfo info) {
    // Reset camera to default centered position
    _centerBoard();
    _zoom = 1.0;
    _board.scale = Vector2.all(1.0);
  }
}
