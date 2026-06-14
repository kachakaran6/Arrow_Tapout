import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arrowtapout/state/game_state.dart';
import 'package:arrowtapout/state/game_events.dart';
import 'package:arrowtapout/game/logic/freedom_checker.dart';
import 'package:arrowtapout/game/logic/level_loader.dart';
import 'package:arrowtapout/design/constants.dart';

/// Global provider for the game state
final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

/// Global provider for game events stream
final gameEventProvider = StreamProvider<GameEvent>((ref) {
  return ref.watch(gameProvider.notifier).events;
});

/// Manages the game state and emits events for animation/audio layer
class GameNotifier extends Notifier<GameState> {
  final _eventController = StreamController<GameEvent>.broadcast();

  Stream<GameEvent> get events => _eventController.stream;

  // Combo reset protection
  int _lastBlockedMs = 0;

  @override
  GameState build() => LevelLoader.loadLevel1();

  /// Called when the player taps an arrow
  void tryRemoveArrow(String arrowId) {
    final arrow = state.arrows.where((a) => a.id == arrowId).firstOrNull;
    if (arrow == null) return;

    if (arrow.state == ArrowState.removed) return;

    if (arrow.state != ArrowState.free) {
      // Wrong tap — trigger blocked animation, reset combo
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastBlockedMs > 100) {
        // 100ms cooldown on thud sound
        _lastBlockedMs = now;
        _eventController.add(ArrowBlockedEvent(arrow));
      }
      // Reset combo on wrong tap
      state = state.copyWith(combo: 0);
      return;
    }

    // Valid tap — remove arrow
    final updatedArrows = state.arrows.map((a) {
      if (a.id == arrowId) return a.copyWith(state: ArrowState.removed);
      return a;
    }).toList();

    // Recompute freedom after removal
    final recomputed = FreedomChecker.recomputeFreedom(
      updatedArrows,
      state.gridCols,
      state.gridRows,
    );

    final newCombo = state.combo + 1;
    final newRemoved = state.removed + 1;
    final isComplete = recomputed.every((a) => a.state == ArrowState.removed);

    state = state.copyWith(
      arrows: recomputed,
      combo: newCombo,
      removed: newRemoved,
      isComplete: isComplete,
    );

    // Emit removal event
    _eventController.add(ArrowRemovedEvent(arrow));

    // Check combo milestones
    if (GameConstants.comboMilestones.contains(newCombo)) {
      _eventController.add(ComboMilestoneEvent(newCombo));
    }

    // Check completion
    if (isComplete) {
      _eventController.add(const LevelCompleteEvent());
    }
  }

  /// Reset to initial level 1 state
  void resetLevel() {
    state = LevelLoader.loadLevel1();
    _eventController.add(const LevelResetEvent());
  }
}
