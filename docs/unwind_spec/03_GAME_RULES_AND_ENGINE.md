# 03 Game rules and engine

All code in this file lives in `lib/engine/` and imports nothing from Flutter. It is also imported by the level generator CLI.

## Coordinates
Grid of `rows x cols`. Cell `(r, c)`, r down, c right. A thread passes through cell centres. In board space one cell is 1.0 unit; the centre of cell (r, c) is `(c + 0.5, r + 0.5)`.

## Model
```dart
enum Dir { up, right, down, left }

extension DirX on Dir {
  int get dr => switch (this) { Dir.up => -1, Dir.down => 1, _ => 0 };
  int get dc => switch (this) { Dir.left => -1, Dir.right => 1, _ => 0 };
}

class Cell {
  const Cell(this.r, this.c);
  final int r, c;
  @override bool operator ==(Object o) => o is Cell && o.r == r && o.c == c;
  @override int get hashCode => r * 1000 + c;
}

class Thread {
  Thread(this.id, this.cells); // tail -> head, length >= 2, consecutive cells orthogonally adjacent
  final int id;
  final List<Cell> cells;
  Cell get head => cells.last;
  Dir get dir {
    final a = cells[cells.length - 2], b = cells.last;
    if (b.r < a.r) return Dir.up;
    if (b.r > a.r) return Dir.down;
    return b.c > a.c ? Dir.right : Dir.left;
  }
}

class Level {
  Level({required this.id, required this.rows, required this.cols, required this.threads, this.shape = 'rect'});
  final int id, rows, cols;
  final String shape;
  final List<Thread> threads;
}
```

## Exit rule
The ray of a thread is the sequence of cells starting at the cell after the head and stepping in `dir` until the position leaves `[0,rows) x [0,cols)`. A thread is free if no active thread (including itself) occupies any cell of its ray. Empty cells, and cells outside a silhouette, are always passable. Silhouette boards still use the bounding grid for rays.

```dart
Iterable<Cell> ray(Thread t, int rows, int cols) sync* {
  var r = t.head.r + t.dir.dr, c = t.head.c + t.dir.dc;
  while (r >= 0 && r < rows && c >= 0 && c < cols) {
    yield Cell(r, c);
    r += t.dir.dr; c += t.dir.dc;
  }
}
```

`BoardState` holds `Map<Cell,int> occupancy` (cell -> thread id) and the set of active ids.
- `bool canExit(id)`: every ray cell has no occupant.
- `Blocker? firstBlocker(id)`: first occupied ray cell, returns blocker id and ray distance in cells (needed to animate the bounce so the head stops one half-cell before the blocker body).
- `void remove(id)`: clears occupancy.
- `List<int> freeThreads()`.

A level is **valid** only if all of:
1. every thread has length >= 2 and is a self-avoiding orthogonal path;
2. no two threads share a cell;
3. no thread's ray intersects its own cells;
4. the greedy solver clears the whole board.

## Solver
Removing a thread only ever frees other threads, never blocks one. So greedy order is complete: if any removal order clears the board, greedy does.
```dart
SolveResult solve(Level l) {
  final b = BoardState(l);
  var rounds = 0;
  while (b.active.isNotEmpty) {
    final free = b.freeThreads();
    if (free.isEmpty) return SolveResult.unsolvable;
    free.forEach(b.remove);
    rounds++;
  }
  return SolveResult.solved(depth: rounds);
}
```
`depth` (rounds of parallel removal) is the difficulty metric used by the generator. Also expose `initialFreeCount`.

## Hit testing
- Convert tap position to board space (inverse of the board transform, including zoom/pan).
- For each active thread compute the minimum distance from the point to its polyline segments (centre-line, in cell units). Pick the nearest thread; accept if distance <= `tapTolerance = 0.5` cells. Ties: lower distance wins, then the thread whose segment the point projects inside rather than at an endpoint.
- Precompute each thread's segment list once per level in board units. Use a coarse spatial index (bucket by cell) so a hit test is O(local threads), not O(all threads).
- Minimum on-screen cell size is 18dp, so tolerance is at least 9dp. On boards that would fall below that, enable InteractiveViewer pan/zoom (1x to 3x) instead of shrinking further.
- Taps during an exit animation of the same thread are ignored. Taps on other threads during animations are allowed and queued instantly (animations are independent).

## Game controller behaviour
States: `playing`, `completed`, `failed`. Tracked: active ids, mistakes, hintsUsed, moves, elapsed (display only, no pressure, hidden by default).
- Tap free thread: mark exiting, remove from occupancy immediately (so other taps see the freed space), play exit animation, increment cleared count, haptic light, soft sound.
- Tap blocked thread: record mistake (unless tutorial), play blocked animation with blocker id for the pulse, haptic medium, error sound. Consecutive taps on the same blocked thread within 600 ms count as one mistake.
- When active set empties and no exit animation is running: state `completed`, compute stars, save, show Complete sheet after a 350 ms beat.
- At 3 mistakes (non-tutorial): `failed`.
- Hint: choose a free thread with the greatest number of other threads whose rays it currently blocks (frees most); tie-break by lowest id. Highlight 2 s.
- Persist an in-progress snapshot (active ids, mistakes) on app pause so a killed process resumes mid-level.
