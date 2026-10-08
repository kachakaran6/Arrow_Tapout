import 'package:arrowtapout/engine/cell.dart';

/// Normalized 2D point (0.0 to 1.0) for polygon silhouettes.
class ShapePoint {
  const ShapePoint(this.x, this.y);
  final double x;
  final double y;
}

/// Normalized polygon silhouette definitions.
abstract final class ShapePolygons {
  static const Map<String, List<ShapePoint>> shapes = {
    'diamond': [
      ShapePoint(0.5, 0.05),
      ShapePoint(0.95, 0.5),
      ShapePoint(0.5, 0.95),
      ShapePoint(0.05, 0.5),
    ],
    'cross': [
      ShapePoint(0.35, 0.05),
      ShapePoint(0.65, 0.05),
      ShapePoint(0.65, 0.35),
      ShapePoint(0.95, 0.35),
      ShapePoint(0.95, 0.65),
      ShapePoint(0.65, 0.65),
      ShapePoint(0.65, 0.95),
      ShapePoint(0.35, 0.95),
      ShapePoint(0.35, 0.65),
      ShapePoint(0.05, 0.65),
      ShapePoint(0.05, 0.35),
      ShapePoint(0.35, 0.35),
    ],
    'square_ring': [
      ShapePoint(0.1, 0.1),
      ShapePoint(0.9, 0.1),
      ShapePoint(0.9, 0.9),
      ShapePoint(0.1, 0.9),
    ],
    'pyramid': [
      ShapePoint(0.5, 0.08),
      ShapePoint(0.92, 0.92),
      ShapePoint(0.08, 0.92),
    ],
    'shield': [
      ShapePoint(0.1, 0.1),
      ShapePoint(0.9, 0.1),
      ShapePoint(0.9, 0.55),
      ShapePoint(0.5, 0.95),
      ShapePoint(0.1, 0.55),
    ],
    'hexagon': [
      ShapePoint(0.5, 0.05),
      ShapePoint(0.92, 0.28),
      ShapePoint(0.92, 0.72),
      ShapePoint(0.5, 0.95),
      ShapePoint(0.08, 0.72),
      ShapePoint(0.08, 0.28),
    ],
    'heart': [
      ShapePoint(0.5, 0.25),
      ShapePoint(0.65, 0.08),
      ShapePoint(0.85, 0.1),
      ShapePoint(0.95, 0.3),
      ShapePoint(0.9, 0.55),
      ShapePoint(0.5, 0.92),
      ShapePoint(0.1, 0.55),
      ShapePoint(0.05, 0.3),
      ShapePoint(0.15, 0.1),
      ShapePoint(0.35, 0.08),
    ],
    'star': [
      ShapePoint(0.5, 0.05),
      ShapePoint(0.62, 0.35),
      ShapePoint(0.95, 0.38),
      ShapePoint(0.7, 0.6),
      ShapePoint(0.78, 0.95),
      ShapePoint(0.5, 0.76),
      ShapePoint(0.22, 0.95),
      ShapePoint(0.3, 0.6),
      ShapePoint(0.05, 0.38),
      ShapePoint(0.38, 0.35),
    ],
    'moon': [
      ShapePoint(0.6, 0.08),
      ShapePoint(0.85, 0.25),
      ShapePoint(0.9, 0.5),
      ShapePoint(0.85, 0.75),
      ShapePoint(0.6, 0.92),
      ShapePoint(0.72, 0.7),
      ShapePoint(0.75, 0.5),
      ShapePoint(0.72, 0.3),
    ],
    'leaf': [
      ShapePoint(0.5, 0.05),
      ShapePoint(0.85, 0.35),
      ShapePoint(0.85, 0.65),
      ShapePoint(0.5, 0.95),
      ShapePoint(0.15, 0.65),
      ShapePoint(0.15, 0.35),
    ],
    'drop': [
      ShapePoint(0.5, 0.05),
      ShapePoint(0.85, 0.55),
      ShapePoint(0.75, 0.88),
      ShapePoint(0.5, 0.95),
      ShapePoint(0.25, 0.88),
      ShapePoint(0.15, 0.55),
    ],
    'mountain': [
      ShapePoint(0.5, 0.1),
      ShapePoint(0.7, 0.45),
      ShapePoint(0.85, 0.35),
      ShapePoint(0.95, 0.9),
      ShapePoint(0.05, 0.9),
      ShapePoint(0.2, 0.5),
      ShapePoint(0.35, 0.3),
    ],
    'bolt': [
      ShapePoint(0.55, 0.05),
      ShapePoint(0.25, 0.5),
      ShapePoint(0.5, 0.5),
      ShapePoint(0.4, 0.95),
      ShapePoint(0.75, 0.45),
      ShapePoint(0.52, 0.45),
      ShapePoint(0.68, 0.05),
    ],
    'house': [
      ShapePoint(0.5, 0.08),
      ShapePoint(0.9, 0.42),
      ShapePoint(0.82, 0.42),
      ShapePoint(0.82, 0.92),
      ShapePoint(0.18, 0.92),
      ShapePoint(0.18, 0.42),
      ShapePoint(0.1, 0.42),
    ],
    'fish': [
      ShapePoint(0.08, 0.5),
      ShapePoint(0.35, 0.18),
      ShapePoint(0.7, 0.3),
      ShapePoint(0.92, 0.1),
      ShapePoint(0.85, 0.5),
      ShapePoint(0.92, 0.9),
      ShapePoint(0.7, 0.7),
      ShapePoint(0.35, 0.82),
    ],
    'crown': [
      ShapePoint(0.1, 0.25),
      ShapePoint(0.28, 0.5),
      ShapePoint(0.5, 0.15),
      ShapePoint(0.72, 0.5),
      ShapePoint(0.9, 0.25),
      ShapePoint(0.85, 0.88),
      ShapePoint(0.15, 0.88),
    ],
    'tree': [
      ShapePoint(0.5, 0.05),
      ShapePoint(0.82, 0.4),
      ShapePoint(0.68, 0.4),
      ShapePoint(0.9, 0.7),
      ShapePoint(0.58, 0.7),
      ShapePoint(0.58, 0.95),
      ShapePoint(0.42, 0.95),
      ShapePoint(0.42, 0.7),
      ShapePoint(0.1, 0.7),
      ShapePoint(0.32, 0.4),
      ShapePoint(0.18, 0.4),
    ],
    'anchor': [
      ShapePoint(0.5, 0.05),
      ShapePoint(0.6, 0.2),
      ShapePoint(0.55, 0.2),
      ShapePoint(0.55, 0.75),
      ShapePoint(0.85, 0.55),
      ShapePoint(0.9, 0.7),
      ShapePoint(0.5, 0.95),
      ShapePoint(0.1, 0.7),
      ShapePoint(0.15, 0.55),
      ShapePoint(0.45, 0.75),
      ShapePoint(0.45, 0.2),
      ShapePoint(0.4, 0.2),
    ],
  };

  /// Tests if a point (px, py) is inside the polygon using ray-casting.
  static bool isInside(List<ShapePoint> polygon, double px, double py) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].x, yi = polygon[i].y;
      final xj = polygon[j].x, yj = polygon[j].y;

      final intersect = ((yi > py) != (yj > py)) &&
          (px < (xj - xi) * (py - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  /// Rasterizes a shape polygon onto a rows x cols grid, returning the set of mask cells.
  static Set<Cell> rasterize(String shapeKey, int rows, int cols) {
    if (shapeKey == 'rect' || !shapes.containsKey(shapeKey)) {
      final rectCells = <Cell>{};
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          rectCells.add(Cell(r, c));
        }
      }
      return rectCells;
    }

    final poly = shapes[shapeKey]!;
    final cells = <Cell>{};

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final px = (c + 0.5) / cols;
        final py = (r + 0.5) / rows;
        if (isInside(poly, px, py)) {
          cells.add(Cell(r, c));
        }
      }
    }

    // Ensure connectivity: find largest connected component
    return _largestConnectedComponent(cells);
  }

  static Set<Cell> _largestConnectedComponent(Set<Cell> cells) {
    if (cells.isEmpty) return cells;

    final visited = <Cell>{};
    Set<Cell>? largest;

    for (final cell in cells) {
      if (visited.contains(cell)) continue;
      final component = <Cell>{};
      final queue = <Cell>[cell];
      visited.add(cell);

      while (queue.isNotEmpty) {
        final curr = queue.removeLast();
        component.add(curr);

        final neighbours = [
          Cell(curr.r - 1, curr.c),
          Cell(curr.r + 1, curr.c),
          Cell(curr.r, curr.c - 1),
          Cell(curr.r, curr.c + 1),
        ];

        for (final n in neighbours) {
          if (cells.contains(n) && visited.add(n)) {
            queue.add(n);
          }
        }
      }

      if (largest == null || component.length > largest.length) {
        largest = component;
      }
    }

    return largest ?? cells;
  }
}
