import 'dart:ui';
import 'package:arrowtapout/state/game_state.dart';
import 'package:arrowtapout/game/logic/freedom_checker.dart';

/// Loads predefined level data into a structured GameState
class LevelLoader {
  static const int cols = 6;
  static const int rows = 6;

  // Colors for paths
  static const List<Color> _palette = [
    Color(0xFF2A314E), // Navy
    Color(0xFF28B463), // Green
    Color(0xFFF39C12), // Orange
    Color(0xFF8E44AD), // Purple
    Color(0xFF2E86C1), // Blue
    Color(0xFFC0392B), // Red
  ];

  // Define paths from tail to head
  static final List<List<GridCoord>> _rawPaths = [
    // 0: Exits RIGHT
    [GridCoord(0, 0), GridCoord(1, 0), GridCoord(2, 0), GridCoord(3, 0), GridCoord(4, 0), GridCoord(5, 0)],
    
    // 1: Exits UP
    [GridCoord(0, 5), GridCoord(0, 4), GridCoord(0, 3), GridCoord(0, 2), GridCoord(0, 1)],
    
    // 2: Exits DOWN
    [GridCoord(5, 1), GridCoord(5, 2), GridCoord(5, 3), GridCoord(5, 4), GridCoord(5, 5)],
    
    // 3: Exits LEFT
    [GridCoord(4, 5), GridCoord(3, 5), GridCoord(2, 5), GridCoord(1, 5)],
    
    // 4: Inner loop
    [GridCoord(3, 3), GridCoord(2, 3), GridCoord(1, 3), GridCoord(1, 2), GridCoord(1, 1)],
    
    // 5: Inner loop
    [GridCoord(2, 2), GridCoord(3, 2), GridCoord(4, 2), GridCoord(4, 3), GridCoord(4, 4)],
    
    // 6: Filler
    [GridCoord(3, 4), GridCoord(2, 4), GridCoord(1, 4)],
    
    // 7: Filler
    [GridCoord(2, 1), GridCoord(3, 1), GridCoord(4, 1)],
  ];

  static GameState loadLevel1() {
    List<PathArrow> paths = [];

    for (int i = 0; i < _rawPaths.length; i++) {
      paths.add(PathArrow(
        id: 'arrow_$i',
        path: _rawPaths[i],
        color: _palette[i % _palette.length],
      ));
    }

    // Compute initial freedom state
    final evaluatedPaths = FreedomChecker.recomputeFreedom(paths, cols, rows);

    return GameState(
      arrows: evaluatedPaths,
      gridCols: cols,
      gridRows: rows,
    );
  }
}
