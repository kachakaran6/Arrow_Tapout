import 'package:arrowtapout/engine/cell.dart';
import 'package:arrowtapout/engine/hit_test_geometry.dart';
import 'package:arrowtapout/engine/level.dart';
import 'package:arrowtapout/engine/thread.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hit Test Geometry', () {
    test(
        'segment distance calculates exact perpendicular distance and interior projection',
        () {
      const p1 = BoardPoint(0.0, 0.0);
      const p2 = BoardPoint(3.0, 0.0);
      const seg = BoardSegment(p1, p2, 1);

      // Point directly above middle of segment
      const testP = BoardPoint(1.5, 0.3);
      final (dist, isInterior) = seg.distanceToPoint(testP);

      expect(isInterior, isTrue);
      expect(dist, closeTo(0.3, 1e-6));
    });

    test('spatial index finds nearest active thread within tolerance', () {
      // Thread 1: horizontal along row 0
      final t1 = Thread(1, [const Cell(0, 0), const Cell(0, 2)]);
      // Thread 2: horizontal along row 1
      final t2 = Thread(2, [const Cell(1, 0), const Cell(1, 2)]);

      final level = Level(id: 1, rows: 3, cols: 3, threads: [t1, t2]);
      final index = SpatialHitIndex(level);

      // Tap at (1.0, 0.1) -> closer to row 0 (node y=0.0, distance=0.1) than row 1 (node y=1.0, distance=0.9)
      final hit1 = index.findHitThread(
        tapPoint: const BoardPoint(1.0, 0.1),
        activeThreadIds: {1, 2},
      );
      expect(hit1, equals(1));

      // If thread 1 is already removed, tap at same position ignores it
      final hit2 = index.findHitThread(
        tapPoint: const BoardPoint(1.0, 0.1),
        activeThreadIds: {2},
      );
      expect(hit2, isNull); // 0.9 is > 0.5 tolerance
    });
  });
}
