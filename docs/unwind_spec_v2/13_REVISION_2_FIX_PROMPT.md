# 13 Revision 2: UI, animation and level fix

This file overrides anything in 03 to 08 and 12 that conflicts with it. Paste the PROMPT section into Claude Code on the existing project. Do not rebuild from scratch: fix in place.

## What was wrong (measured from the Level 5 screenshot of the current build)
| # | Defect | Cause | Fix |
|---|---|---|---|
| 1 | A 5x5 board floats in the middle of a 800dp screen, about 70 percent of the screen is empty | Cell size was capped at 44dp and the board was sized from the grid, not from the screen | Lattice model below: the board spans the full page width |
| 2 | Arrowheads look huge and clumsy, lines look heavy | Chevron arm about 0.45 cell, stroke about 3dp | Arm 0.23 cell, stroke 1.6 to 2.4dp |
| 3 | Level 5 has only 4 straight threads | Level table started at 4x5 and coverage targets were too low | 200 new levels (assets included), level 1 already has 9 threads on 9x10 |
| 4 | Grid dots almost invisible, no structure | Dots at 10 percent contrast | New `gridDot` token, visible but quiet |
| 5 | Header and footer feel unfinished: hint badge shouts, "Threads left 4" floats bottom right, no dividers | No layout system for chrome | Header, hairlines, bottom bar below |
| 6 | Animation not smooth | See the animation section: likely static-layer flicker, delayed tap, discontinuous easing | Rewritten, with a slow-motion lab to prove it |

## Lattice model (replaces cell-centre layout)
Grid dots are the nodes. A thread runs from node to node. `rows` and `cols` in the level JSON are node counts.
- `pagePad = 20dp`.
- `cell = (screenWidth - 2*pagePad) / (cols - 1)`, then clamp to at most `(boardRegionHeight - 2*12dp) / (rows - 1)`, at most 46dp, snapped down to a whole physical pixel.
- Edge nodes sit exactly on the page margin when the width is the limiting side (it is for almost every level). The board is centred in the board region, shifted up 2 percent.
- If `cell < 20dp` (large and silhouette levels, up to 23 columns, so about 15dp on a 393dp phone): enable pinch zoom 1x to 3x with pan. No double-tap zoom (see animation, it delays taps).
- Node (r, c) is at `origin + (c*cell, r*cell)`. Ray rules from file 03 are unchanged.

## Screen layout, top to bottom (all dp)
1. System status bar area (edge to edge, transparent).
2. **Header**, height 64. Left: back arrow button (48x48 target, thin outline arrow, `ink`), then title "Level 5" in Newsreader 24 `ink`. Centre: mistake dots (3 dots, 8dp, 10dp gap, filled = remaining in `ink`, lost = `threadFaint`); hidden on tutorial levels 1 to 5 (reserve the space). Right: remaining counter, two lines, right-aligned: "12" in Newsreader 28 `ink`, "of 12" in Manrope 12 `inkMuted`. Page padding 20 left and right.
3. Hairline: 1dp `threadFaint`, margin 20 each side.
4. **Board region**: everything between the two hairlines.
5. Hairline, same style.
6. **Bottom bar**, height 56 plus bottom inset. Three text buttons spread: Restart (left aligned), Hint (centred, label "Hint" plus the bank count in `accent` as "Hint  6"), How to play (right aligned). Each: 20dp thin outline glyph + Manrope 14 w600 `inkMuted`, 48dp tall target. Disabled Hint shows `inkFaint`.
Remove: the hint badge in the header, "Threads left N", the green lightbulb in the header.
Restart opens no sheet during play if no thread has been cleared yet, otherwise shows a small confirm sheet. How to play opens a bottom sheet with the three-step explanation (not a new route, so the board state is kept).

## Thread and grid drawing (exact)
- `stroke = clamp(cell * 0.06, 1.6, 2.4)` dp, round caps and joins, anti-aliased.
- Arrowhead: open chevron, two arms each `clamp(cell * 0.23, 4, 9)` dp long, half-angle 40 degrees, tip exactly at the head node, arms drawn with the same stroke and round caps.
- Tail starts exactly at the tail node.
- Dots: radius `clamp(cell * 0.04, 1.0, 1.6)` dp in token `gridDot`, drawn under threads for every node of the lattice (for silhouettes draw only mask-adjacent nodes: nodes within 1 step of any thread node, so the shape stays readable and empty corners stay clean).
- New token `gridDot`: Sage Linen #B9BFAF, Ink and Brass #3A3F47, Fog Slate #B4C0C8, Rosewood #CDB5AC, Graphite Ember #46403A.
- No glow, no shadow, no per-thread colour. Hint outline and blocked pulse remain the only colour changes.

## Animation: exact definitions
Likely defects to eliminate first: (a) a cached static picture that is not refreshed in the same frame the dynamic copy starts, which shows as a flicker or a double line; (b) `onDoubleTap` registered on the board, which makes Flutter wait about 300 ms before firing `onTap`; (c) easing with a velocity jump between the anticipation and the main slide; (d) opacity done with `saveLayer`.

Rules:
1. **No static picture cache.** Boards have at most 59 threads. Paint every active thread every frame from cached `ui.Path` objects in one `CustomPainter` inside a `RepaintBoundary`. Remove the static/dynamic split from 06.
2. **Instant taps.** Use `Listener` (`onPointerDown` records position and time, `onPointerUp` fires if the pointer moved less than `kTouchSlop` and it was shorter than 400 ms). No `GestureDetector` double-tap or long-press on the board. Pinch zoom uses `InteractiveViewer` only when `cell < 20dp`, with `onInteractionStart` suppressing the tap if two pointers are down.
3. **One Ticker** drives all animating threads. Each animating thread stores its start timestamp; progress `u = clamp(elapsed / T, 0, 1)` is computed from the ticker's elapsed time, not from chained controllers.
4. **Exit motion**: let `L` be the thread length in px, `ray` the distance from head to the lattice edge in px, `D = ray + L + 0.6*cell` (the whole thread leaves the lattice), `A = 0.16*cell`.
   `p(u) = D * u^2.2  -  A * sin^2(pi * min(u / 0.20, 1))`
   This is continuous in position and velocity at every point (value and slope are both 0 at u = 0 and u = 0.2 for the anticipation term), so the thread first eases back about 0.16 cell, then accelerates away with no jerk. `T = clamp(300ms + 9ms * (D / cell), 340ms, 820ms)`.
   The extended path = a virtual backward stub of `0.3*cell` along the reverse of the first segment, then the thread's own path, then the straight ray, then `0.6*cell + L` of extra straight run. The visible window is `[p, p + L]` measured from the start of the thread's own path (so the thread moves rigidly along the path and its bent body follows corners). Draw it with `PathMetric.extractPath`; place the chevron with `getTangentForOffset(p + L)`.
   Fade: alpha multiplies 1 to 0 over `u` from 0.85 to 1.0 using the paint colour's alpha, never `saveLayer`. Clip to the screen rect, not the board.
5. **Blocked motion**: `k` = distance in nodes from head to the first blocker. Nudge distance `n = min(0.45, max(0.12, k - 0.6))` cells. Move forward by `n` over 90 ms with `easeOutCubic`, then `SpringSimulation(mass 1, stiffness 420, damping 26)` back to 0 (about 280 ms, at most one visible overshoot). The blocker's colour lerps to `danger` at 55 percent and back over 420 ms. Haptic medium at the moment of contact.
6. **Same frame bookkeeping**: when a thread is tapped, in that single frame: mark it exiting in the state, remove it from occupancy, start its animation. The counter "12 of 12" updates when the exit starts, with a 120 ms crossfade of the numeral.
7. **Level complete** unchanged from 06 (350 ms beat, then the sheet).
8. **Reduce motion** unchanged from 06.

### Animation lab (dev-only route `/dev/lab`, excluded from release)
A level picker, a speed slider (0.05x to 1x), a frame-step button, and a live plot of `p(u)`. Used to inspect the slide frame by frame. Unit test: `p(0) = 0`, `p(1) = D`, `p` is non-increasing on `[0, 0.1]` and non-decreasing on `[0.1, 1]`, and the finite-difference slope has no jump larger than 5 percent of `D` between consecutive 1/240 steps.

## Levels
The 200 levels are generated and verified for you: `assets/levels/chapter_01.json` to `chapter_10.json`. Copy them to the project `assets/levels/` and register the folder in pubspec. Format is the one in file 04 (`rows` and `cols` are node counts, threads are `[row, col]` lists from tail to head).
- Every level is valid and solvable (self-avoiding paths, no overlap, no self-blocking ray, greedy solver clears it), at least 3 threads are free at the start, and the dependency depth is at least 3.
- Chapter 1 is sparse and calm like a tutorial, with 9 to 20 threads on 9x10 to 11x14 nodes. Chapter 10 reaches 17x30 nodes with up to 58 threads. Silhouettes appear on every 5th level from level 25: diamond, hexagon, heart, leaf, mountain, house, drop, fish, moon, star, bolt, crown, on lattices up to 23x30.
- `assets/levels/LEVEL_REPORT.md` lists grid, shape, threads, fill, depth and free-at-start for every level.
- The Python generator (`tool/unwind_levelgen.py`) and independent verifier (`tool/verify_levels.py`) are the source of truth for the assets. Keep them in the repo. The Dart engine must re-verify every level in a unit test (parse JSON, run `valid` and `solve` from file 03), so the app and the generator are checked against each other. A Dart port of the generator is optional and can be done later.
- Replace the chapter table in file 04 with the real numbers in `LEVEL_REPORT.md`. Tutorial levels 1 to 5: unlimited mistakes, coach mark on level 1.
- `previews/` contains images of levels 1, 5, 20, 60, 100, 120 and 185 rendered by the Python script. They show the intended proportions (full-width lattice, thin strokes, small chevrons); they are not Flutter screenshots.

## PROMPT (paste into Claude Code)
You are fixing an existing Flutter project, Unwind. Read files 01 to 13 in the spec folder. File 13 wins over any conflict. Do not rewrite the app: change only what is needed.
Work in these steps and report after each, with before and after screenshots at 360x800, 393x852 and 411x915 dp, in Sage Linen and Ink and Brass:
1. Replace the board layout with the lattice model (cell from page width, 20dp margin, zoom only when cell < 20dp). Add the `gridDot` token to all five themes and draw the dot lattice.
2. Rebuild the game screen chrome: header (back, title, mistake dots, remaining counter), hairlines, bottom bar (Restart, Hint, How to play). Remove the hint badge and "Threads left".
3. Fix thread drawing to the exact stroke, chevron and dot sizes above.
4. Rewrite the animation system exactly as specified (single ticker, no static cache, `Listener` taps, the `p(u)` function, the blocked nudge and spring). Add `/dev/lab` and the unit tests described.
5. Copy `assets/levels/*.json` into the project, update the loader for node counts, delete the old level assets and old generator output, add the engine re-verification test.
6. Run `flutter analyze` and `flutter test`. Record profile-mode frame times on the largest level (200) with 6 threads exiting at once in `docs/PERF.md`. Target under 6 ms per frame.
Acceptance: level 1 looks like the preview (full-width dot lattice, thin lines, small chevrons, header and bottom bar with hairlines), tapping a free thread responds on the same frame with no flicker, the exit is a smooth pull-back-and-release, the blocked nudge is subtle, all 200 levels load and re-verify, no emoji anywhere.
If anything in the screenshots still looks off after your changes, say what and fix it before reporting.
