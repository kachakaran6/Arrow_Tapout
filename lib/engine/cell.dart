/// An immutable cell coordinate on the grid.
///
/// In board space, cell (r, c) is centered at (c + 0.5, r + 0.5).
class Cell {
  const Cell(this.r, this.c);

  final int r;
  final int c;

  /// Returns a new cell translated by [dir].
  Cell step(dynamic dir) => Cell(r + (dir.dr as int), c + (dir.dc as int));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cell &&
          runtimeType == other.runtimeType &&
          other.r == r &&
          other.c == c;

  @override
  int get hashCode => r * 10007 + c;

  @override
  String toString() => '($r, $c)';
}
