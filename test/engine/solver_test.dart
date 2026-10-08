import 'package:arrowtapout/engine/cell.dart';
import 'package:arrowtapout/engine/level.dart';
import 'package:arrowtapout/engine/solver.dart';
import 'package:arrowtapout/engine/thread.dart';
import 'package:arrowtapout/engine/validity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Solver and Validity', () {
    test('solver solves solvable level and records depth and initialFree', () {
      // t2 is free initially (points down)
      final t2 = Thread(2, [const Cell(0, 3), const Cell(1, 3)]);
      // t1 is blocked by t2, freed in round 2 (points right)
      final t1 = Thread(1, [const Cell(0, 0), const Cell(0, 1)]);
      // t3 is blocked by t1, freed in round 3 (points up)
      final t3 = Thread(3, [const Cell(2, 0), const Cell(1, 0)]);

      final level = Level(id: 1, rows: 4, cols: 4, threads: [t1, t2, t3]);
      final result = solve(level);

      expect(result.isSolved, isTrue);
      expect(result.initialFreeCount, equals(1)); // Only t2 is free initially
      expect(result.depth, equals(3)); // Round 1: t2. Round 2: t1. Round 3: t3.
      expect(result.removalOrder, equals([2, 1, 3]));
    });

    test('solver identifies mutually locked deadlocks as unsolvable', () {
      // t1 points right into t2
      final t1 = Thread(1, [const Cell(0, 0), const Cell(0, 1)]);
      // t2 points left into t1
      final t2 = Thread(2, [const Cell(0, 3), const Cell(0, 2)]);

      final level = Level(id: 2, rows: 2, cols: 4, threads: [t1, t2]);
      final result = solve(level);

      expect(result.isSolved, isFalse);
    });

    test('validity rejects level with overlapping thread cells', () {
      final t1 = Thread(1, [const Cell(0, 0), const Cell(0, 1)]);
      final t2 =
          Thread(2, [const Cell(0, 1), const Cell(1, 1)]); // Shares (0,1)

      final level = Level(id: 3, rows: 3, cols: 3, threads: [t1, t2]);
      final valid = validateLevel(level);

      expect(valid.isValid, isFalse);
      expect(valid.error, contains('share cell'));
    });

    test('validity rejects thread whose ray hits its own cells', () {
      // Complete U-shape orthogonal path:
      // (2,0) -> (1,0) -> (0,0) -> (0,1) -> (0,2) -> (1,2) -> (2,2) -> (2,1)
      // Head is at (2,1), penultimate at (2,2), dir is left.
      // Ray from (2,1) going left steps to (2,0), which is its own tail cell!
      final t1 = Thread(1, [
        const Cell(2, 0),
        const Cell(1, 0),
        const Cell(0, 0),
        const Cell(0, 1),
        const Cell(0, 2),
        const Cell(1, 2),
        const Cell(2, 2),
        const Cell(2, 1),
      ]);
      final level = Level(id: 4, rows: 4, cols: 4, threads: [t1]);
      final valid = validateLevel(level);

      expect(valid.isValid, isFalse);
      expect(valid.error, contains('ray intersects its own body'));
    });
  });
}
