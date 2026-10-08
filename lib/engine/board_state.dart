import 'package:arrowtapout/engine/cell.dart';
import 'package:arrowtapout/engine/level.dart';
import 'package:arrowtapout/engine/thread.dart';

/// Blocker details for a blocked thread tap.
class Blocker {
  const Blocker({
    required this.id,
    required this.distanceCells,
    required this.hitCell,
  });

  /// The ID of the blocking thread.
  final int id;

  /// The distance in grid cells from the head of the blocked thread to the blocker cell.
  final int distanceCells;

  /// The exact grid cell where collision occurs.
  final Cell hitCell;

  @override
  String toString() =>
      'Blocker(thread: $id, dist: $distanceCells, cell: $hitCell)';
}

/// Mutable engine state tracking cell occupancy and active threads.
class BoardState {
  BoardState(this.level)
      : rows = level.rows,
        cols = level.cols,
        threads = {for (final t in level.threads) t.id: t},
        active = {for (final t in level.threads) t.id},
        occupancy = {} {
    _initOccupancy();
  }

  /// Copy constructor for solver / simulation branching.
  BoardState.clone(BoardState other)
      : level = other.level,
        rows = other.rows,
        cols = other.cols,
        threads = other.threads,
        active = Set<int>.of(other.active),
        occupancy = Map<Cell, int>.of(other.occupancy);

  final Level level;
  final int rows;
  final int cols;
  final Map<int, Thread> threads;
  final Set<int> active;
  final Map<Cell, int> occupancy;

  void _initOccupancy() {
    for (final t in level.threads) {
      for (final cell in t.cells) {
        occupancy[cell] = t.id;
      }
    }
  }

  /// Generates the sequence of cells in the straight line forward from [t.head]
  /// until leaving the bounding grid.
  static Iterable<Cell> ray(Thread t, int rows, int cols) sync* {
    var r = t.head.r + t.dir.dr;
    var c = t.head.c + t.dir.dc;
    while (r >= 0 && r < rows && c >= 0 && c < cols) {
      yield Cell(r, c);
      r += t.dir.dr;
      c += t.dir.dc;
    }
  }

  /// Returns the ray cells for thread with [id].
  Iterable<Cell> rayFor(int id) {
    final t = threads[id];
    if (t == null) return const [];
    return ray(t, rows, cols);
  }

  /// Checks if the thread with [id] has an unobstructed exit path.
  bool canExit(int id) {
    if (!active.contains(id)) return false;
    final t = threads[id]!;
    for (final cell in ray(t, rows, cols)) {
      if (occupancy.containsKey(cell)) {
        return false;
      }
    }
    return true;
  }

  /// Finds the first blocking thread along the exit path of thread [id].
  Blocker? firstBlocker(int id) {
    if (!active.contains(id)) return null;
    final t = threads[id]!;
    var dist = 1;
    for (final cell in ray(t, rows, cols)) {
      final blockerId = occupancy[cell];
      if (blockerId != null) {
        return Blocker(
          id: blockerId,
          distanceCells: dist,
          hitCell: cell,
        );
      }
      dist++;
    }
    return null;
  }

  /// Removes the thread with [id] from the board and frees its occupied cells.
  void remove(int id) {
    if (!active.remove(id)) return;
    final t = threads[id];
    if (t == null) return;
    for (final cell in t.cells) {
      occupancy.remove(cell);
    }
  }

  /// Returns all currently active thread IDs that can exit without obstruction.
  List<int> freeThreads() {
    final result = <int>[];
    for (final id in active) {
      if (canExit(id)) {
        result.add(id);
      }
    }
    return result;
  }

  /// Computes for a given free thread how many other active threads' exit rays
  /// it is currently blocking.
  int blockedRaysFreedBy(int id) {
    if (!active.contains(id)) return 0;
    final t = threads[id]!;
    final threadCells = t.cells.toSet();

    var count = 0;
    for (final otherId in active) {
      if (otherId == id) continue;
      final other = threads[otherId]!;
      for (final rayCell in ray(other, rows, cols)) {
        if (threadCells.contains(rayCell)) {
          count++;
          break;
        }
      }
    }
    return count;
  }

  /// Selects the optimal hint thread (frees most other threads, tie-broken by lowest id).
  int? chooseHintThread() {
    final frees = freeThreads();
    if (frees.isEmpty) return null;

    var bestId = frees.first;
    var bestCount = -1;

    for (final id in frees) {
      final count = blockedRaysFreedBy(id);
      if (count > bestCount || (count == bestCount && id < bestId)) {
        bestCount = count;
        bestId = id;
      }
    }
    return bestId;
  }
}
