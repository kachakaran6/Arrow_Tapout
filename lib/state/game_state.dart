import 'dart:ui';
import 'package:flutter/foundation.dart';

enum ArrowDirection {
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0);

  final int dx;
  final int dy;

  const ArrowDirection(this.dx, this.dy);

  double get angleRad {
    switch (this) {
      case ArrowDirection.up:
        return -1.5708; // -pi/2
      case ArrowDirection.down:
        return 1.5708; // pi/2
      case ArrowDirection.left:
        return 3.14159; // pi
      case ArrowDirection.right:
        return 0;
    }
  }

  /// Get the direction from p1 to p2. Returns right if they are the same.
  static ArrowDirection fromPoints(GridCoord p1, GridCoord p2) {
    if (p2.x > p1.x) return ArrowDirection.right;
    if (p2.x < p1.x) return ArrowDirection.left;
    if (p2.y > p1.y) return ArrowDirection.down;
    if (p2.y < p1.y) return ArrowDirection.up;
    return ArrowDirection.right; // fallback
  }
}

enum ArrowState {
  free,     // Path is clear to the edge
  blocked,  // Path is blocked by another arrow
  removed,  // Arrow has been successfully tapped out
}

@immutable
class GridCoord {
  final int x;
  final int y;

  const GridCoord(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridCoord && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => '($x, $y)';
}

@immutable
class PathArrow {
  final String id;
  // The path of coordinates this arrow occupies.
  // path[0] is the tail, path.last is the head.
  final List<GridCoord> path;
  final Color color;
  final ArrowState state;

  const PathArrow({
    required this.id,
    required this.path,
    required this.color,
    this.state = ArrowState.blocked,
  });

  /// The head is the last coordinate in the path
  GridCoord get head => path.last;

  /// The direction the head is pointing.
  /// It is determined by the vector from the second-to-last coordinate to the head.
  ArrowDirection get direction {
    if (path.length < 2) return ArrowDirection.right; // Fallback
    return ArrowDirection.fromPoints(path[path.length - 2], head);
  }

  PathArrow copyWith({
    String? id,
    List<GridCoord>? path,
    Color? color,
    ArrowState? state,
  }) {
    return PathArrow(
      id: id ?? this.id,
      path: path ?? this.path,
      color: color ?? this.color,
      state: state ?? this.state,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PathArrow &&
          id == other.id &&
          listEquals(path, other.path) &&
          color == other.color &&
          state == other.state;

  @override
  int get hashCode => id.hashCode ^ Object.hashAll(path) ^ color.hashCode ^ state.hashCode;
}

@immutable
class GameState {
  final List<PathArrow> arrows;
  final int gridCols;
  final int gridRows;
  final int combo;
  final int removed;
  final bool isComplete;

  const GameState({
    required this.arrows,
    required this.gridCols,
    required this.gridRows,
    this.combo = 0,
    this.removed = 0,
    this.isComplete = false,
  });

  int get remaining => arrows.length - removed;

  GameState copyWith({
    List<PathArrow>? arrows,
    int? gridCols,
    int? gridRows,
    int? combo,
    int? removed,
    bool? isComplete,
  }) {
    return GameState(
      arrows: arrows ?? this.arrows,
      gridCols: gridCols ?? this.gridCols,
      gridRows: gridRows ?? this.gridRows,
      combo: combo ?? this.combo,
      removed: removed ?? this.removed,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameState &&
          listEquals(arrows, other.arrows) &&
          gridCols == other.gridCols &&
          gridRows == other.gridRows &&
          combo == other.combo &&
          removed == other.removed &&
          isComplete == other.isComplete;

  @override
  int get hashCode =>
      Object.hashAll(arrows) ^
      gridCols.hashCode ^
      gridRows.hashCode ^
      combo.hashCode ^
      removed.hashCode ^
      isComplete.hashCode;
}
