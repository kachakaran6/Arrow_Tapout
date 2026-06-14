import 'package:arrowtapout/state/game_state.dart';

/// Events emitted by the game that drive animations and audio
/// Separates game logic (state) from presentation (animations)
sealed class GameEvent {
  const GameEvent();
}

/// An arrow was successfully removed
class ArrowRemovedEvent extends GameEvent {
  final PathArrow arrow;
  const ArrowRemovedEvent(this.arrow);
}

/// A blocked arrow was tapped (wrong move)
class ArrowBlockedEvent extends GameEvent {
  final PathArrow arrow;
  const ArrowBlockedEvent(this.arrow);
}

/// The board was cleared — all arrows removed
class LevelCompleteEvent extends GameEvent {
  const LevelCompleteEvent();
}

/// Level was reset / restarted
class LevelResetEvent extends GameEvent {
  const LevelResetEvent();
}

/// A combo milestone was reached (3, 5, 10, 15, 25, 50)
class ComboMilestoneEvent extends GameEvent {
  final int combo;
  const ComboMilestoneEvent(this.combo);
}
