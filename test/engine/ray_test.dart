import 'package:arrowtapout/engine/board_state.dart';
import 'package:arrowtapout/engine/cell.dart';
import 'package:arrowtapout/engine/dir.dart';
import 'package:arrowtapout/engine/thread.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardState Ray Generation', () {
    test('ray stepping UP produces correct consecutive cells to top edge', () {
      final t = Thread(1, [const Cell(4, 2), const Cell(3, 2)]);
      expect(t.dir, equals(Dir.up));

      final ray = BoardState.ray(t, 6, 6).toList();
      expect(
          ray,
          equals([
            const Cell(2, 2),
            const Cell(1, 2),
            const Cell(0, 2),
          ]));
    });

    test('ray stepping DOWN produces correct consecutive cells to bottom edge',
        () {
      final t = Thread(1, [const Cell(1, 4), const Cell(2, 4)]);
      expect(t.dir, equals(Dir.down));

      final ray = BoardState.ray(t, 5, 5).toList();
      expect(
          ray,
          equals([
            const Cell(3, 4),
            const Cell(4, 4),
          ]));
    });

    test('ray stepping LEFT produces correct consecutive cells to left edge',
        () {
      final t = Thread(1, [const Cell(2, 3), const Cell(2, 2)]);
      expect(t.dir, equals(Dir.left));

      final ray = BoardState.ray(t, 5, 5).toList();
      expect(
          ray,
          equals([
            const Cell(2, 1),
            const Cell(2, 0),
          ]));
    });

    test('ray stepping RIGHT produces correct consecutive cells to right edge',
        () {
      final t = Thread(1, [const Cell(1, 0), const Cell(1, 1)]);
      expect(t.dir, equals(Dir.right));

      final ray = BoardState.ray(t, 4, 4).toList();
      expect(
          ray,
          equals([
            const Cell(1, 2),
            const Cell(1, 3),
          ]));
    });

    test('ray at the boundary immediately exits grid (empty ray)', () {
      final t = Thread(1, [const Cell(1, 0), const Cell(0, 0)]);
      expect(t.dir, equals(Dir.up));

      final ray = BoardState.ray(t, 4, 4).toList();
      expect(ray, isEmpty);
    });
  });
}
