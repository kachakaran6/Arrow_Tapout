# 04 Level generator and progression

## Principle
Levels are generated at development time by `tool/generate_levels.dart` (pure Dart, uses `lib/engine`), verified, and written to `assets/levels/chapter_01.json` ... `chapter_10.json`. The app only reads JSON. Output is deterministic from a seed so levels are reproducible and diffable.

## JSON format
```json
{ "v": 1, "chapter": 1, "name": "First Threads",
  "levels": [
    { "id": 1, "rows": 5, "cols": 4, "shape": "rect", "par": 0,
      "threads": [ [[0,0],[0,1],[0,2]], [[1,3],[2,3]] ] }
  ] }
```
Threads are listed tail to head. `par` is reserved. The seed is `fnv1a("unwind|chapter|index")`.

## Generation algorithm: reverse construction
Solvable by construction, then re-verified.

1. Build the mask: all cells for `rect`, or rasterised polygon for a silhouette (see Shapes). Mask cells are the fillable set.
2. Maintain `placed` threads in placement order. Placement order is the reverse of removal order: the first thread placed is removed last.
3. Repeat until no candidate exists:
   a. Take free mask cells (not covered by a placed thread). Sample a start cell weighted toward cells with few free neighbours (fills pockets first, avoids stranded single cells).
   b. Random self-avoiding walk through free cells, target length drawn from the chapter's length range, with a turn bias from the chapter profile (spiral bias for chapter 5, long straights for chapter 3, and so on). Walk must reach at least length 2.
   c. Try both ends of the walk as the head. For an end with penultimate cell p, direction = end - p. The candidate is accepted if the ray from the end (to the grid edge) contains **no cell of any already-placed thread and no cell of this walk**. Rays over free cells are fine, because threads placed later are removed earlier.
   d. If either end is acceptable, choose among acceptable candidates by score (below) and place it. Otherwise retry with a different walk; after N failed walks (e.g. 60) mark the start cell as a leftover.
4. Leftover repair: for each leftover cell, try extending the tail of an adjacent placed thread into it (tail extension never changes a head or ray, but it can occupy a cell on another thread's ray, so re-run validity afterwards and revert if it breaks). If repair fails, leave a hole. Holes are allowed up to 8 percent of mask cells (rect) or 10 percent (silhouette).
5. Run the full validity check from file 03 and compute `depth` and `initialFreeCount`.
6. Run 200 to 800 seeds per level and keep the best by score. Reject any level that fails the targets below.

### Candidate score
Higher is better: coverage gain, plus variety (do not repeat the same direction for the head more than 3 times in a row spatially), plus a mild reward for a head pointing toward a nearer edge (keeps ray lengths varied), minus a penalty for threads that are perfectly straight when length >= 4 (visual boredom), minus a penalty for threads hugging an edge for their full length.

### Targets per level
| Metric | Rule |
|---|---|
| Coverage | >= 92 percent of mask cells (rect), >= 90 percent (silhouette) |
| Min thread length | 2 |
| Initial free threads | >= 2, and <= 35 percent of threads from chapter 3 on |
| Depth | within chapter band (table below) |
| Visual | no 2x2 fully-filled block of the same thread; arrowheads must not touch an adjacent parallel thread's head |

Also write `tool/level_report.md` with a table per level: size, thread count, coverage, depth, initial free, seed. Commit it.

## Shapes
Silhouette boards fit a polygon into the bounding grid. Implement a polygon rasteriser (cell centre inside polygon) with these shape keys: `diamond, hexagon, heart, moon, star, leaf, drop, mountain, bolt, house, fish, crown`. Shapes must be connected after rasterisation (flood fill check); if not, nudge scale until they are. Moon and bolt need thick-enough strokes (min 3 cells wide). Draw polygons as normalised point lists in `tool/shapes.dart`.

## Progression plan: 200 levels, 10 chapters of 20
Levels 5, 10, 15, 20 of each chapter from chapter 2 on are silhouette showpieces. Level 20 is the chapter finale and the largest.

| Ch | Name | Grid (start -> end) | Thread length | Depth band | Notes |
|---|---|---|---|---|---|
| 1 | First Threads | 4x5 -> 7x9 | 2-4 | 2-4 | Levels 1-5 hand-curated tutorial, unlimited mistakes |
| 2 | Loose Ends | 6x8 -> 8x11 | 2-6 | 3-5 | Shapes: diamond, hexagon, heart, leaf |
| 3 | Straight Talk | 7x10 -> 9x13 | 3-8 | 4-6 | Long straights, ray length variety |
| 4 | Corners | 8x12 -> 10x16 | 3-8 | 5-7 | High turn density |
| 5 | Spirals | 9x13 -> 11x18 | 4-10 | 5-8 | Spiral bias, nested pockets |
| 6 | Crosscurrents | 10x15 -> 12x20 | 3-9 | 6-9 | Many long rays crossing |
| 7 | Dense Weave | 10x16 -> 12x22 | 3-10 | 7-10 | Coverage >= 95 percent |
| 8 | Labyrinth | 11x17 -> 13x24 | 4-12 | 8-12 | Few initial frees (2-4) |
| 9 | Long Form | 12x18 -> 14x25 | 5-14 | 9-13 | Long threads, deep chains |
| 10 | Masterworks | 12x20 -> 14x26 | 4-14 | 10-15 | Largest boards, all shapes return |

Within a chapter, grid size interpolates linearly with level index. Cell size on device is derived from the available board area (see 06), so the 14x26 maximum never drops below 18dp on a 360dp-wide phone (14 cols fit at about 23dp).

## Verification
- `dart run tool/generate_levels.dart --verify` loads every JSON and re-checks validity and solvability. Wire this into `flutter test` (test/levels_test.dart) so CI fails if any level is broken.
- Add a test that solves every level by simulating the real `GameController` taps in greedy order and expects `completed` with zero mistakes.
