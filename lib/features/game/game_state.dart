import 'package:arrowtapout/engine/level.dart';

enum GameStatus { playing, completed, failed }

/// Immutable state snapshot of an active game level.
class GameState {
  const GameState({
    required this.level,
    required this.activeIds,
    required this.mistakes,
    required this.hintsUsed,
    required this.moves,
    required this.elapsedSeconds,
    required this.status,
    required this.stars,
    required this.showCoachMark,
    this.hintedThreadId,
    this.lastBlockedTapTimeMs = 0.0,
    this.lastBlockedThreadId,
  });

  final Level level;
  final Set<int> activeIds;
  final int mistakes;
  final int hintsUsed;
  final int moves;
  final int elapsedSeconds;
  final GameStatus status;
  final int stars;
  final bool showCoachMark;
  final int? hintedThreadId;
  final double lastBlockedTapTimeMs;
  final int? lastBlockedThreadId;

  /// Is this level a tutorial level with unlimited mistakes?
  bool get isTutorial => level.id <= 5;

  /// Remaining mistakes out of 3 allowed (always 3 for tutorial).
  int get remainingMistakes => isTutorial ? 3 : (3 - mistakes).clamp(0, 3);

  /// Number of cleared threads.
  int get clearedCount => level.threads.length - activeIds.length;

  /// Calculates stars on completion: 3 for 0 mistakes, 2 for 1-2 mistakes, 1 otherwise.
  static int calculateStars(int mistakes) {
    if (mistakes == 0) return 3;
    if (mistakes <= 2) return 2;
    return 1;
  }

  GameState copyWith({
    Level? level,
    Set<int>? activeIds,
    int? mistakes,
    int? hintsUsed,
    int? moves,
    int? elapsedSeconds,
    GameStatus? status,
    int? stars,
    bool? showCoachMark,
    int? hintedThreadId,
    double? lastBlockedTapTimeMs,
    int? lastBlockedThreadId,
  }) {
    return GameState(
      level: level ?? this.level,
      activeIds: activeIds ?? this.activeIds,
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      moves: moves ?? this.moves,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      status: status ?? this.status,
      stars: stars ?? this.stars,
      showCoachMark: showCoachMark ?? this.showCoachMark,
      hintedThreadId: hintedThreadId ?? this.hintedThreadId,
      lastBlockedTapTimeMs: lastBlockedTapTimeMs ?? this.lastBlockedTapTimeMs,
      lastBlockedThreadId: lastBlockedThreadId ?? this.lastBlockedThreadId,
    );
  }
}
