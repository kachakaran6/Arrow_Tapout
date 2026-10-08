import 'package:arrowtapout/engine/board_state.dart';
import 'package:arrowtapout/engine/cell.dart';
import 'package:arrowtapout/engine/level.dart';
import 'package:arrowtapout/engine/thread.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardState Occupancy & Blocking Logic', () {
    test('canExit returns true when ray path is completely empty', () {
      final t1 = Thread(1,
          [const Cell(0, 0), const Cell(0, 1)]); // Points right, head at (0,1)
      final level = Level(id: 1, rows: 3, cols: 3, threads: [t1]);
      final board = BoardState(level);

      expect(board.canExit(1), isTrue);
      expect(board.firstBlocker(1), isNull);
      expect(board.freeThreads(), equals([1]));
    });

    test('canExit returns false when ray intersects another active thread', () {
      final t1 = Thread(
          1, [const Cell(0, 0), const Cell(0, 1)]); // Points right from (0,1)
      final t2 = Thread(2, [
        const Cell(2, 2),
        const Cell(1, 2),
        const Cell(0, 2)
      ]); // Occupies (0,2)
      final level = Level(id: 1, rows: 4, cols: 4, threads: [t1, t2]);
      final board = BoardState(level);

      expect(board.canExit(1), isFalse);
      final blocker = board.firstBlocker(1);
      expect(blocker, isNotNull);
      expect(blocker!.id, equals(2));
      expect(blocker.distanceCells, equals(1));
      expect(blocker.hitCell, equals(const Cell(0, 2)));

      // Thread 2 points up from (0,2), exits immediately
      expect(board.canExit(2), isTrue);
    });

    test('removing a thread immediately frees blocked threads', () {
      final t1 =
          Thread(1, [const Cell(0, 0), const Cell(0, 1)]); // Blocked by t2
      final t2 = Thread(2, [const Cell(1, 2), const Cell(0, 2)]);
      final level = Level(id: 1, rows: 4, cols: 4, threads: [t1, t2]);
      final board = BoardState(level);

      expect(board.canExit(1), isFalse);
      board.remove(2);

      expect(board.active.contains(2), isFalse);
      expect(board.canExit(1), isTrue);
      expect(board.firstBlocker(1), isNull);
      expect(board.freeThreads(), equals([1]));
    });

    test('hint selection chooses thread that frees maximum blocked rays', () {
      // t1 points right, blocked by t2 at (0,3)
      final t1 = Thread(1, [const Cell(0, 1), const Cell(0, 2)]);
      // t3 points right, blocked by t2 at (1,3)
      final t3 = Thread(3, [const Cell(1, 1), const Cell(1, 2)]);
      // t2 occupies (0,3), (1,3), (2,3) pointing down and can exit down freely
      final t2 =
          Thread(2, [const Cell(0, 3), const Cell(1, 3), const Cell(2, 3)]);
      // t4 is also free but frees 0 other threads
      final t4 = Thread(4, [const Cell(3, 0), const Cell(3, 1)]);

      final level = Level(id: 1, rows: 5, cols: 5, threads: [t1, t2, t3, t4]);
      final board = BoardState(level);

      // t2 frees 2 threads (t1 and t3). t4 frees 0.
      expect(board.blockedRaysFreedBy(2), equals(2));
      expect(board.blockedRaysFreedBy(4), equals(0));
      expect(board.chooseHintThread(), equals(2));
    });
  });
}
