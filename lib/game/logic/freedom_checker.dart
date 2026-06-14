import 'package:arrowtapout/state/game_state.dart';

/// Checks if a PathArrow is free to escape (path in front of head to boundary is clear)
class FreedomChecker {
  /// Check if the [target] arrow is free to move.
  /// It is free if a ray cast from its head in its pointing direction
  /// reaches the edge of the board without intersecting any other non-removed arrow.
  static bool isFree(
      PathArrow target, List<PathArrow> allArrows, int gridCols, int gridRows) {
    if (target.state == ArrowState.removed) return true;

    final head = target.head;
    final dir = target.direction;

    int cx = head.x + dir.dx;
    int cy = head.y + dir.dy;

    // We build a set of all occupied cells by OTHER non-removed arrows for O(1) lookup.
    final occupied = <GridCoord>{};
    for (final arrow in allArrows) {
      if (arrow.id == target.id) continue;
      if (arrow.state == ArrowState.removed) continue;
      occupied.addAll(arrow.path);
    }

    // Raycast loop
    while (cx >= 0 && cx < gridCols && cy >= 0 && cy < gridRows) {
      final pos = GridCoord(cx, cy);
      // If we hit another arrow's body, we are blocked
      if (occupied.contains(pos)) {
        return false;
      }
      cx += dir.dx;
      cy += dir.dy;
    }

    // Made it to the edge!
    return true;
  }

  /// Recomputes the ArrowState for all arrows based on current grid occupancy
  static List<PathArrow> recomputeFreedom(
      List<PathArrow> arrows, int gridCols, int gridRows) {
    return arrows.map((arrow) {
      if (arrow.state == ArrowState.removed) return arrow;
      final free = isFree(arrow, arrows, gridCols, gridRows);
      return arrow.copyWith(
          state: free ? ArrowState.free : ArrowState.blocked);
    }).toList();
  }
}
