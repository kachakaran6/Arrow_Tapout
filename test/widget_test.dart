import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrowtapout/game/logic/freedom_checker.dart';
import 'package:arrowtapout/state/game_state.dart';

void main() {
  group('FreedomChecker', () {
    test('path pointing at empty edge is free', () {
      final arrow = const PathArrow(
        id: 'test_0_0',
        path: [GridCoord(0, 1), GridCoord(0, 0)],
        color: Colors.red,
        state: ArrowState.blocked,
      );
      final result = FreedomChecker.isFree(arrow, [arrow], 10, 10);
      expect(result, isTrue); // Head at 0,0 pointing UP. Escapes immediately.
    });

    test('path blocked by another arrow is not free', () {
      final arrow1 = const PathArrow(
        id: 'a_0_0',
        path: [GridCoord(0, 0), GridCoord(1, 0)],
        color: Colors.red,
        state: ArrowState.blocked,
      ); // Points right, head at 1,0
      final arrow2 = const PathArrow(
        id: 'a_2_0',
        path: [GridCoord(2, 0), GridCoord(2, 1)],
        color: Colors.blue,
        state: ArrowState.blocked,
      );
      final result = FreedomChecker.isFree(arrow1, [arrow1, arrow2], 10, 10);
      expect(result, isFalse); // Ray from (1,0) going Right hits (2,0) which is occupied.
    });

    test('removed arrows do not block path', () {
      final free = const PathArrow(
        id: 'free',
        path: [GridCoord(0, 0), GridCoord(1, 0)],
        color: Colors.red,
        state: ArrowState.free,
      );
      final removed = const PathArrow(
        id: 'removed',
        path: [GridCoord(2, 0), GridCoord(2, 1)],
        color: Colors.blue,
        state: ArrowState.removed,
      );
      final result = FreedomChecker.isFree(free, [free, removed], 10, 10);
      expect(result, isTrue);
    });
  });
}
