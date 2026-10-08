import 'package:arrowtapout/engine/board_state.dart';
import 'package:arrowtapout/engine/level.dart';

/// Result of solving a level.
class SolveResult {
  const SolveResult._({
    required this.isSolved,
    required this.depth,
    required this.initialFreeCount,
    required this.removalOrder,
  });

  const SolveResult.unsolvable()
      : isSolved = false,
        depth = 0,
        initialFreeCount = 0,
        removalOrder = const [];

  const SolveResult.solved({
    required int depth,
    required int initialFreeCount,
    required List<int> removalOrder,
  }) : this._(
          isSolved: true,
          depth: depth,
          initialFreeCount: initialFreeCount,
          removalOrder: removalOrder,
        );

  final bool isSolved;
  final int depth;
  final int initialFreeCount;
  final List<int> removalOrder;

  @override
  String toString() => isSolved
      ? 'Solved(depth: $depth, initFree: $initialFreeCount, order: ${removalOrder.length})'
      : 'Unsolvable()';
}

/// Solves a level using the complete greedy algorithm.
SolveResult solve(Level level) {
  final board = BoardState(level);
  var rounds = 0;
  var initialFreeCount = 0;
  final removalOrder = <int>[];

  while (board.active.isNotEmpty) {
    final free = board.freeThreads();
    if (free.isEmpty) {
      return const SolveResult.unsolvable();
    }
    if (rounds == 0) {
      initialFreeCount = free.length;
    }

    // Record sequential order and remove in batch for round count
    for (final id in free) {
      removalOrder.add(id);
      board.remove(id);
    }
    rounds++;
  }

  return SolveResult.solved(
    depth: rounds,
    initialFreeCount: initialFreeCount,
    removalOrder: removalOrder,
  );
}
