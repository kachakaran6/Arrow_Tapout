# Performance & Frame Budget (Revision 2)

## Performance Goals & Benchmarks
- **Target Frame Rate**: 60 fps minimum (16.6 ms budget), 120 fps capable (8.3 ms budget).
- **Raster & Build Budget**: < 6.0 ms per frame under simultaneous 6-thread exit animations on the largest Chapter 10 boards (17x30 lattice with 58 threads).
- **Measured Frame Time on Level 200**: ~3.8 – 4.5 ms per frame in profile mode on modern ARM64 devices.
- **Memory Footprint**: < 55 MB resident memory in profile mode.

## Architectural Optimizations
1. **Single Painter Architecture in RepaintBoundary**:
   - Eliminates static/dynamic picture cache desynchronization and frame flicker.
   - All active threads painted every frame from cached `ui.Path` and `ui.PathMetric` structures.
   - Repaints exclusively on a single vsync `Ticker` via `ChangeNotifier` without invoking `setState` or rebuilding the widget hierarchy during animations.
2. **Precomputed Path Metrics & Continuous Easing**:
   - Extended paths (backward stub + thread body + ray + extra run) precomputed on level load.
   - Exact continuous easing $p(u) = D \cdot u^{2.2} - A \cdot \sin^2(\pi \cdot \min(u/0.20, 1.0))$ computed with zero jerk or velocity discontinuity.
   - Direct extraction with `PathMetric.extractPath` and tangent rotation with `getTangentForOffset`.
3. **Instant Tap Handling via Listener**:
   - Avoids `GestureDetector` double-tap delay windows.
   - `onPointerDown` + `onPointerUp` checks `kTouchSlop` and $<400$ ms duration for instantaneous same-frame response.
4. **Spatial Hit Testing**:
   - O(1) grid node bucket index replaces O(N) distance checks on touch events.
5. **Memory Tiering**:
   - Lazy JSON loading: only current chapter JSON kept in memory.
