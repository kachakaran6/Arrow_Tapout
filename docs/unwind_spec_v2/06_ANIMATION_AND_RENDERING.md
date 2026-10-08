> REVISION 2 applies: see 13_REVISION_2_FIX_PROMPT.md. Where it conflicts with this file, 13 wins.

# 06 Animation and rendering

The tactile feel of the game is the product. Spend the effort here.

## Render architecture
- Board is a `RepaintBoundary` containing a `CustomPaint` stack:
  1. **Static layer**: all idle threads, painted once into a cached `ui.Picture` and re-recorded only when the active set, theme or size changes.
  2. **Dynamic layer**: only threads currently animating (exiting, bouncing, hinted, pulsing). Repaints each frame via `repaint: Listenable` (a single `AnimationController` or `Ticker` driving a lightweight `ChangeNotifier`), never `setState`.
- Do not clip the dynamic layer to the board rect. Exiting threads continue sliding across the surrounding page margin and are clipped by the board viewport widget (which is larger than the grid by one thread-length of padding where space allows) and fade out over the last 12 percent of travel so nothing pops.
- Pre-build per thread a `ui.Path` of the thread centre-line, and a `PathMetric` for the **extended path** = thread cells + straight ray to the board edge + exit margin. Cache both. Never allocate Paths per frame in the dynamic layer except the `extractPath` window.
- Pixel snap strokes: use `StrokeCap.round`, `StrokeJoin.round`, `isAntiAlias = true`. Draw the arrowhead as an open chevron (two arms) at the head, rotated by the path tangent, not a filled triangle.

## Exit animation (the signature interaction)
Treat the thread as a window sliding along the extended path.
- Let `L` = thread path length in px. Initially the visible window is `[0, L]` (tail at 0, head at L). The window slides to `[T, T + L]` where `T = rayLenPx + L + marginPx`, so the tail leaves the board completely.
- Draw `metric.extractPath(s, s + L)` and place the chevron at `getTangentForOffset(s + L)`. Corners bend naturally because the body follows the path like a thread being pulled.
- Timing: `duration = clamp(260ms + 11ms * travelCells, 320ms, 900ms)`.
- Easing: custom two-phase curve. A short anticipation of 6 percent of travel at ease-out (a gentle lift, the head moves 0.12 cell backward along the path first, then goes), followed by `exitIn` acceleration (`Cubic(0.5, 0, 0.9, 0.5)`), so it feels like a pull and release, not a linear slide. Implement the anticipation as a negative offset term, not a separate controller.
- Opacity: 1.0 until 88 percent progress, then to 0.
- Stroke subtly thins from 100 percent to 85 percent over the same last 12 percent (suggests tension).
- Several threads can exit simultaneously; each has its own controller from a pooled set (max 12 live), all driven by one shared Ticker.

## Blocked animation
- Resolve `firstBlocker` for the thread. Head advances along the ray to `blockerDistance - 0.55` cells (never overlapping the blocker), duration 110 ms, easeOutCubic.
- Spring back to the origin with `SpringSimulation(mass 1, stiffness 420, damping 26)`, about 260 ms, one visible overshoot at most.
- During the nudge, the tapped thread colour lerps toward `danger` (30 percent), and the blocker thread pulses to `danger` 55 percent then back over 420 ms. Colour is never the only signal because the motion also communicates it.
- Haptics: `HapticFeedback.mediumImpact` at contact.

## Hint animation
Outline the chosen thread with `accent` at 3.2 dp stroke plus a slow 1.6 s sine opacity pulse (0.55 to 1.0), for 2 s, then fade 200 ms.

## Level complete
- After the last exit finishes: 350 ms stillness, the empty board fades its border hairline to accent (180 ms), then the Complete bottom sheet slides up with `enter` curve (360 ms). No confetti. Stars appear one by one, 120 ms apart, each as a thread-drawn star outline that "draws itself" via PathMetric over 320 ms.

## Level start
Threads draw in staggered: each thread's window grows from tail to full length, staggered by 8 ms per thread index (cap 600 ms total), `enter` curve. Skipped under reduce motion.

## Navigation and sheet motion
- Page transitions: fade-through, 280 ms: outgoing fades 0 to 1 over the first 35 percent, incoming fades and rises 12 dp with `enter`.
- Bottom sheets: 360 ms `enter` in, 240 ms `standard` out, drag-to-dismiss enabled.
- Theme change: colour lerp 280 ms.
- Buttons: 90 ms scale to 0.98 on press, no ripple colour mismatch (use theme-tinted `InkResponse` with accent at 10 percent).

## Board layout
- Compute `cell = min((availW) / cols, (availH) / rows)` where avail excludes page padding, top bar and the dots row. Clamp to [18dp, 44dp] and snap down to a whole logical pixel multiple (`floor(cell * dpr) / dpr`) to keep lines crisp.
- If the clamped cell makes the board exceed available space, wrap in `InteractiveViewer` (min 1x, max 3x, pan bounded, double-tap toggles 1x/2x). Pan gestures must not cause mistaken taps: a tap counts only if the pointer moved less than `kTouchSlop`.
- Board is centred; silhouette boards centre on their bounding grid.

## Reduce motion
When `MediaQuery.disableAnimations` or the in-app Reduce motion is on: exit becomes a 180 ms linear slide with fade, blocked becomes a 120 ms colour flash with no movement, no level-start stagger, sheets fade instead of slide.

## Performance budget
- Frame build plus raster < 6 ms on a mid-range device (profile mode) on the largest board while 6 threads animate.
- Zero allocations of `Paint` or large objects in `paint()`; reuse final `Paint` fields.
- Verify with the Performance overlay and `flutter run --profile`; write the numbers into `docs/PERF.md`.
