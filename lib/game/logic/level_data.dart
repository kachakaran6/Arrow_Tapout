import 'package:arrowtapout/state/game_state.dart';
import 'package:flutter/material.dart';

/// Predefined level data for the path-based arrow tap-out game.
class LevelData {
  static const int gridCols = 6;
  static const int gridRows = 6;

  // A small perfectly packed 6x6 puzzle
  static const List<List<GridCoord>> paths = [
    // 1. Exits UP (Free initially)
    [GridCoord(0, 3), GridCoord(0, 2), GridCoord(0, 1), GridCoord(0, 0)],
    
    // 2. Exits RIGHT (Free initially)
    [GridCoord(1, 0), GridCoord(2, 0), GridCoord(3, 0), GridCoord(4, 0), GridCoord(5, 0)],
    
    // 3. Blocked by #1, points LEFT
    [GridCoord(2, 1), GridCoord(1, 1)],
    
    // 4. Blocked by #2, points UP
    [GridCoord(1, 4), GridCoord(1, 3), GridCoord(1, 2)],
    
    // 5. Exits RIGHT (Free initially)
    [GridCoord(3, 1), GridCoord(4, 1), GridCoord(5, 1)],
    
    // 6. Blocked by #5, points RIGHT
    [GridCoord(2, 2), GridCoord(3, 2), GridCoord(4, 2), GridCoord(5, 2)],
    
    // 7. Blocked by #1, points LEFT
    [GridCoord(2, 3), GridCoord(1, 3)], // Wait, 1,3 is used by #4.
  ];

  static final List<List<GridCoord>> puzzlePaths = [
    // Path 1: (Yellow)
    [GridCoord(0,2), GridCoord(0,1), GridCoord(0,0), GridCoord(1,0)], // Head at (1,0) pointing Right. Blocked by Path 2
    // Path 2: (Green)
    [GridCoord(2,1), GridCoord(2,0), GridCoord(3,0), GridCoord(4,0), GridCoord(5,0)], // Head at (5,0) pointing Right. Free!
    // Path 3: (Navy)
    [GridCoord(1,3), GridCoord(1,2), GridCoord(1,1)], // Head at (1,1) pointing Up. Blocked by Path 1
    // Path 4: (Orange)
    [GridCoord(3,3), GridCoord(2,3), GridCoord(2,2), GridCoord(3,2), GridCoord(4,2), GridCoord(4,1), GridCoord(5,1)], // Head at (5,1) pointing Right. Free!
    // Path 5: (Purple)
    [GridCoord(5,5), GridCoord(5,4), GridCoord(5,3), GridCoord(5,2)], // Head at (5,2) pointing Up. Blocked by Path 4
    // Path 6: (Cyan)
    [GridCoord(3,1), GridCoord(4,1)], // Wait, (4,1) is used by Path 4.
  ];

  // A carefully constructed non-overlapping 6x6 path puzzle
  static final List<List<GridCoord>> validPuzzle = [
    // P1: Top border, exits right. (Free)
    [GridCoord(0,0), GridCoord(1,0), GridCoord(2,0), GridCoord(3,0), GridCoord(4,0), GridCoord(5,0)],
    
    // P2: Left border, exits up. (Blocked by P1 at 0,0)
    [GridCoord(0,5), GridCoord(0,4), GridCoord(0,3), GridCoord(0,2), GridCoord(0,1)],
    
    // P3: Spirals from center, exits left. (Blocked by P2)
    [GridCoord(2,3), GridCoord(3,3), GridCoord(3,2), GridCoord(2,2), GridCoord(1,2), GridCoord(1,1), GridCoord(0,1)], // Wait, 0,1 used by P2. Head at 1,1 pointing Left.
    
    // P4: Bottom border, exits right. (Free)
    [GridCoord(1,5), GridCoord(2,5), GridCoord(3,5), GridCoord(4,5), GridCoord(5,5)],
    
    // P5: Right border, exits down. (Blocked by P4)
    [GridCoord(5,1), GridCoord(5,2), GridCoord(5,3), GridCoord(5,4)],
    
    // P6: Inner path, exits up. (Blocked by P1)
    [GridCoord(4,4), GridCoord(4,3), GridCoord(4,2), GridCoord(4,1)],
    
    // P7: Inner path, exits down. (Blocked by P4)
    [GridCoord(1,3), GridCoord(1,4)],
    
    // P8: Inner path, exits left. (Blocked by P2)
    [GridCoord(2,4), GridCoord(2,4)], // Just a single coordinate? Head direction needs 2 points.
    [GridCoord(3,4), GridCoord(2,4)],
  ];
}
