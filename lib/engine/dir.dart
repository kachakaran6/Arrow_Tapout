/// Orthogonal grid directions for Unwind threads.
enum Dir {
  up,
  right,
  down,
  left;

  /// Row offset delta.
  int get dr => switch (this) {
        Dir.up => -1,
        Dir.down => 1,
        Dir.left => 0,
        Dir.right => 0,
      };

  /// Column offset delta.
  int get dc => switch (this) {
        Dir.left => -1,
        Dir.right => 1,
        Dir.up => 0,
        Dir.down => 0,
      };

  /// X coordinate offset in board units.
  double get dx => dc.toDouble();

  /// Y coordinate offset in board units.
  double get dy => dr.toDouble();

  /// Opposite direction.
  Dir get opposite => switch (this) {
        Dir.up => Dir.down,
        Dir.down => Dir.up,
        Dir.left => Dir.right,
        Dir.right => Dir.left,
      };
}
