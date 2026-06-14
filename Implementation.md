# Arrow Tap-Out — Master Class Product Requirements Document
### Version 1.0 · Phase 1: Core Game Loop
**Classification:** Internal Product Specification  
**Audience:** Engineering, Design, QA  
**Status:** Ready for Development

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Tech Stack Decision](#2-tech-stack-decision)
3. [Product Vision & Philosophy](#3-product-vision--philosophy)
4. [Phase 1 Scope](#4-phase-1-scope)
5. [Architecture Overview](#5-architecture-overview)
6. [Game Logic Specification](#6-game-logic-specification)
7. [Animation System](#7-animation-system)
8. [Visual Design System](#8-visual-design-system)
9. [Audio System](#9-audio-system)
10. [Screen & UI Specification](#10-screen--ui-specification)
11. [State Management](#11-state-management)
12. [Performance Targets](#12-performance-targets)
13. [Folder Structure](#13-folder-structure)
14. [Phase 1 Milestone Plan](#14-phase-1-milestone-plan)
15. [Future Phases (Out of Scope Now)](#15-future-phases-out-of-scope-now)

---

## 1. Executive Summary

**Arrow Tap-Out** is a premium puzzle game where the player's only job is to free trapped arrows — in the correct order — by tapping them. Each arrow wants to fly in the direction it points. It can only escape if its entire path is clear. Every successful tap reshapes the board and creates new possibilities. The satisfaction of watching the board go from completely packed to completely empty, one arrow at a time, is the core emotional loop.

**Phase 1 Goal:** Ship a polished, silky-smooth, production-quality version of the core gameplay screen — no menus, no onboarding, no IAP. The player opens the app and lands directly on a playable arrow puzzle. Everything must feel masterclass-level: animations, physics feel, sound, visual polish.

---

## 2. Tech Stack Decision

### Recommendation: **Flutter**

| Criteria | Flutter | React Native |
|---|---|---|
| Animation control | **Superior** — CustomPainter, AnimationController, direct canvas | Limited — JS bridge adds latency |
| 60/120fps guarantee | **Yes** — Skia/Impeller renders directly on GPU | Inconsistent — JS thread can block UI |
| Game loop suitability | **Yes** — Ticker, SchedulerBinding | Requires third-party game libs |
| Custom rendering (arrows, particles) | **Native** via Canvas API | Requires reanimated + native modules |
| Platform parity | **Perfect** — same code, same feel on iOS & Android | Subtle differences between platforms |
| Physics / gesture feel | Excellent — GestureDetector is low-level | Good but adds bridge overhead |
| Cold start time | ~200–400ms | ~600–900ms |

**Verdict:** Flutter is the only right choice for a game that lives or dies on animation quality and touch response. React Native is a great choice for form-heavy apps, not physics-feel puzzle games.

### Core Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Animation & rendering
  flame: ^1.18.0              # Game loop, component system, particle engine
  flutter_animate: ^4.5.0     # Declarative animation chains
  
  # Audio
  flame_audio: ^2.10.0        # Bundled with Flame, handles sound pools
  
  # State management
  flutter_riverpod: ^2.5.1    # Predictable, testable game state
  
  # Utilities
  freezed_annotation: ^2.4.1  # Immutable game state models
  collection: ^1.18.0         # Priority queues, list extensions

dev_dependencies:
  build_runner: ^2.4.9
  freezed: ^2.5.2
  flutter_lints: ^4.0.0
```

### Why Flame (Game Engine)?

- Built-in **game loop** with `update(dt)` and `render(canvas)` — no manual Ticker wiring
- **Component system** — each Arrow is a `PositionComponent`, composable, testable
- **Particle system** — built-in `ParticleSystemComponent` with physics
- **Camera control** — built-in `CameraComponent` with zoom/pan
- **Audio pools** — `FlameAudio` manages sound pooling to prevent latency
- Used in production games with millions of downloads

---

## 3. Product Vision & Philosophy

### Core Feeling
> "Each tap should feel like releasing a spring. The board breathes. Arrows feel alive."

### Three Laws of Feel
1. **Zero latency input.** Touch → visual response must be `< 16ms`. No frame is skipped between a tap and the first animation frame.
2. **Every state change is animated.** Nothing teleports. Nothing just disappears. Every transition is a visual sentence.
3. **Failure teaches without punishing.** A wrong tap produces a satisfying shake, not a popup, not a penalty. The game corrects itself silently.

### Anti-Patterns (Explicitly Banned)
- No full-screen popups for "wrong move"
- No loading spinners mid-gameplay
- No frame drops — any feature that causes jank is cut before shipping
- No debug state visible to the player ever
- No dead zones — every pixel of an arrow is tappable

---

## 4. Phase 1 Scope

### In Scope ✅
- Game launches directly into puzzle screen (no splash, no home screen)
- 8-directional arrows: ↑ ↓ ← → ↗ ↖ ↘ ↙
- Grid-based board (10×10 default for Phase 1)
- Freedom detection algorithm (path-clear check)
- Tap-to-remove interaction with full animation suite
- Blocked arrow feedback animation
- Board completion detection and celebration
- Camera: pinch-to-zoom, two-finger pan, rotation gesture
- Particle system (exit trail + completion burst)
- Sound effects (whoosh, thud, pop, completion fanfare)
- Ambient background animation (slow board float)
- One hardcoded Level 1 puzzle (50 arrows, 10×10 grid)
- Score/combo counter (visual only, no persistence)

### Out of Scope ❌ (Phase 2+)
- Multiple levels, level selection, progression
- IAP, coins, currency
- Menu screens, settings, onboarding
- Obstacles (ice, locks, portals, bombs)
- 3D camera (Phase 1 is isometric/2D-perspective, not full 3D)
- Leaderboards, achievements, social features
- Backend, user accounts
- Analytics

---

## 5. Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                        │
│                                                      │
│  ┌──────────────┐    ┌─────────────────────────────┐│
│  │   Riverpod   │    │        Flame Game           ││
│  │ StateNotifier│◄──►│                             ││
│  │              │    │  ┌────────────────────────┐ ││
│  │  GameState   │    │  │   BoardComponent       │ ││
│  │  - arrows[]  │    │  │   - renders grid       │ ││
│  │  - combo     │    │  │   - owns ArrowComponents││
│  │  - cleared   │    │  └────────────────────────┘ ││
│  └──────────────┘    │                             ││
│                      │  ┌────────────────────────┐ ││
│                      │  │   ArrowComponent (×N)  │ ││
│                      │  │   - position           │ ││
│                      │  │   - direction          │ ││
│                      │  │   - state (free/blocked││
│                      │  │   - animationController││
│                      │  └────────────────────────┘ ││
│                      │                             ││
│                      │  ┌────────────────────────┐ ││
│                      │  │  ParticleSystemComponent││
│                      │  │  CameraComponent        ││
│                      │  │  AudioComponent         ││
│                      │  └────────────────────────┘ ││
│                      └─────────────────────────────┘│
└─────────────────────────────────────────────────────┘
```

### Data Flow

```
User Tap
   │
   ▼
TapDetector (Flame gesture)
   │
   ▼
GameNotifier.tryRemoveArrow(ArrowId)
   │
   ├─── isFree(arrow) == false
   │         │
   │         ▼
   │    ArrowComponent.playBlockedAnimation()
   │    AudioService.playThud()
   │
   └─── isFree(arrow) == true
             │
             ▼
        GameState updated (arrow removed)
             │
             ▼
        ArrowComponent.playExitAnimation()
             │
             ▼
        ParticleSystem.emitTrail(direction)
             │
             ▼
        AudioService.playWhoosh()
             │
             ▼
        Nearby arrows: playSettleAnimation()
             │
             ▼
        Check: boardEmpty? → playCompletionSequence()
```

---

## 6. Game Logic Specification

### 6.1 Grid Model

```dart
// Arrow directions as unit vectors
enum ArrowDirection {
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0),
  upRight(1, -1),
  upLeft(-1, -1),
  downRight(1, 1),
  downLeft(-1, 1);

  final int dx, dy;
  const ArrowDirection(this.dx, this.dy);
}

@freezed
class Arrow with _$Arrow {
  const factory Arrow({
    required String id,
    required int col,
    required int row,
    required ArrowDirection direction,
    required ArrowState state, // free, blocked, removed
  }) = _Arrow;
}

@freezed
class GameState with _$GameState {
  const factory GameState({
    required int gridCols,
    required int gridRows,
    required List<Arrow> arrows,
    required int combo,
    required int removed,
    required bool isComplete,
  }) = _GameState;
}
```

### 6.2 Freedom Algorithm

An arrow is FREE if and only if **every cell** from its position to the grid boundary (in its direction) contains no other arrow.

```dart
bool isFree(Arrow arrow, List<Arrow> allArrows) {
  // Build a set of occupied positions for O(1) lookup
  final occupied = {
    for (final a in allArrows)
      if (a.state != ArrowState.removed) (a.col, a.row): true
  };

  int checkCol = arrow.col + arrow.direction.dx;
  int checkRow = arrow.row + arrow.direction.dy;

  while (
    checkCol >= 0 && checkCol < gridCols &&
    checkRow >= 0 && checkRow < gridRows
  ) {
    if (occupied.containsKey((checkCol, checkRow))) {
      return false; // Something is blocking the path
    }
    checkCol += arrow.direction.dx;
    checkRow += arrow.direction.dy;
  }

  return true; // Path is clear to boundary
}
```

**Edge case rules:**
- An arrow pointing directly at a wall (adjacent to boundary) is always FREE — its path is zero cells
- Arrows at diagonal directions check diagonal cells only (not horizontal + vertical separately)
- Removed arrows do not block paths
- The arrow's own cell is excluded from path checking

### 6.3 Freedom Precomputation

Recompute freedom status for ALL remaining arrows after every successful removal. Cache the result on each `Arrow` model. This drives:
- Visual state (free arrows glow differently from blocked ones)
- Tap response (immediate — no calculation on tap)

```dart
List<Arrow> recomputeFreedom(List<Arrow> arrows) {
  return arrows.map((a) {
    if (a.state == ArrowState.removed) return a;
    final free = isFree(a, arrows);
    return a.copyWith(state: free ? ArrowState.free : ArrowState.blocked);
  }).toList();
}
```

### 6.4 Combo System

```dart
// Combo is broken if:
// - Player taps a blocked arrow (attempted wrong tap)
// Combo increments if:
// - Player successfully removes a free arrow
// Combo milestones: 3, 5, 10, 15, 25, 50

const comboMilestones = [3, 5, 10, 15, 25, 50];
```

### 6.5 Level 1 Puzzle Definition

Level 1 is hardcoded as a 10×10 grid with exactly 50 arrows. The puzzle must have:
- A clear, deterministic solution path
- At least 3 arrows free at the start (so the player isn't stuck immediately)
- Maximum chain depth of ~15 (arrows that unlock a chain of 15+ when removed)

Level data format:

```dart
const level1 = [
  // (col, row, direction)
  (0, 0, ArrowDirection.right),
  (1, 0, ArrowDirection.down),
  // ... 48 more entries
  // Pre-validated: solvable with at least one solution path
];
```

> **Note:** A level editor tool (internal, not shipped) will be built in Week 2 to generate and validate levels. Levels must pass automated solvability check before being added.

---

## 7. Animation System

This is the most critical section of the PRD. Animation quality is the entire product.

### 7.1 Arrow Exit Animation

Total duration: **480ms**

```
Phase 1: Anticipation (0–80ms)
  - Scale: 1.0 → 1.12
  - Lift: y offset 0 → -4px
  - Glow intensity: 0 → 1.0
  - Curve: easeOut

Phase 2: Squish (80–130ms)
  - Scale: 1.12 → 0.95
  - Lift: -4px → -2px
  - Curve: easeIn

Phase 3: Launch (130–480ms)
  - Scale: 0.95 → 0.6 (shrinks as it goes far)
  - Position: moves in arrow direction × screen width
  - Opacity: 1.0 → 0.0 (fades last 100ms)
  - Motion blur: StretchEffect applied proportional to velocity
  - Speed curve: custom cubic — slow start, violent acceleration
  - Particle trail: emits from arrow center, 12 particles, fanned in direction
  - Curve: custom cubic (0.2, 0, 0.8, 1)

Hole left behind:
  - Surrounding arrows: scale 1.0 → 1.04 → 1.0 over 200ms (settle bounce)
  - Empty cell: faint pulse ring expands and fades (120ms)
```

Implementation using Flame + flutter_animate:

```dart
class ArrowComponent extends PositionComponent with TapCallbacks {
  
  Future<void> playExitAnimation(ArrowDirection dir) async {
    // Phase 1: anticipation
    await _scale(1.12, duration: 80.ms, curve: Curves.easeOut);
    
    // Phase 2: squish
    await _scale(0.95, duration: 50.ms, curve: Curves.easeIn);
    
    // Phase 3: launch — run position + fade concurrently
    final exitVector = _directionToVector(dir) * (screenWidth * 1.5);
    await Future.wait([
      _moveTo(position + exitVector, duration: 350.ms, curve: _launchCurve),
      _fadeTo(0.0, duration: 350.ms, startDelay: 250.ms),
      _scaleTo(0.5, duration: 350.ms),
    ]);
    
    removeFromParent(); // Clean up component
  }

  // Custom launch curve: violent acceleration
  static const _launchCurve = Cubic(0.2, 0.0, 0.8, 1.0);
}
```

### 7.2 Blocked Arrow Animation

Total duration: **320ms**

```
Sequence:
  0ms    → Scale up: 1.0 → 1.06
  60ms   → Translate right: +8px
  100ms  → Translate left: -10px
  140ms  → Translate right: +6px
  180ms  → Translate left: -4px
  220ms  → Translate center: 0px
  320ms  → Scale back: 1.06 → 1.0
  
Simultaneously:
  - Red outline appears: opacity 0 → 0.9 → 0 over 320ms
  - Slight red tint on arrow body: overlay 0 → 0.3 → 0
  - Haptic feedback: medium impact (iOS: UIImpactFeedbackGenerator, Android: VibrationEffect.createOneShot(30ms, 128))
```

### 7.3 Free Arrow Idle Animation

Arrows detected as FREE have a subtle pulsing glow:

```
Idle glow pulse:
  - Duration: 1800ms, repeat forever
  - Glow radius: 0px → 6px → 0px
  - Glow color: arrow's base color at 60% opacity
  - Phase offset: random per arrow (so they don't all pulse in sync)
  
Scale breathing:
  - Duration: 2200ms, repeat forever
  - Scale: 1.0 → 1.025 → 1.0
  - Curve: easeInOut
```

### 7.4 Particle Trail System

On arrow exit, emit a particle burst:

```
Particle count: 14
Emission point: arrow center at moment of launch
Particle lifetime: 300–500ms (randomized per particle)

Each particle:
  - Initial velocity: base direction vector × (80–140 px/s random)
  - Spread angle: ±25° from arrow direction
  - Size: 3–6px circle, randomized
  - Color: gradient sample from arrow color palette
  - Fade out: opacity 1.0 → 0.0 over lifetime
  - Scale: 1.0 → 0.0 over lifetime
  - Gravity: 0 (floats freely, no downward pull)

Glow particles (30% of particles):
  - Larger: 8–12px
  - Glow blur: 8px
  - Higher opacity: starts at 0.8
```

### 7.5 Board Completion Sequence

Triggered when the last arrow is removed:

```
T+0ms     Last arrow exit animation plays (same as normal exit)
T+200ms   Camera starts slow zoom-in (0.8s, easeInOut, zoom 1.0 → 1.3)
T+300ms   Confetti burst from center: 80 particles, all directions, arc physics
T+500ms   "Puzzle Cleared!" text fades in (scale 0.7 → 1.05 → 1.0, opacity 0 → 1)
T+700ms   Star rating fills in one by one (3 stars, 200ms each)
T+1000ms  Subtle screen edge bloom (white vignette pulse, 600ms)
T+1200ms  "Next Level" button slides up from bottom
```

### 7.6 Ambient Board Animation

Even when idle, the board should feel alive:

```
Board float:
  - Y offset: 0px → 8px → 0px, 3000ms loop, easeInOut
  
Arrow hover stagger:
  - Each arrow has a tiny Y offset oscillation
  - Period: 1600–2400ms (random per arrow)
  - Amplitude: 1–3px (random per arrow)
  - No two arrows phase-synchronized
  
Camera drift:
  - Camera very slowly rotates ±2° over 12 seconds
  - Only when player is not interacting
  - Stops immediately on any touch
```

---

## 8. Visual Design System

### 8.1 Color Palette

```dart
class GameColors {
  // Background
  static const backgroundDark     = Color(0xFF0D0F1A);
  static const backgroundMid      = Color(0xFF141729);
  
  // Arrow color tiers (by direction, 8 directions = 8 colors)
  static const arrowUp            = Color(0xFF4ECAFF); // Cyan
  static const arrowDown          = Color(0xFFFF6B6B); // Coral
  static const arrowLeft          = Color(0xFFFFC45C); // Amber
  static const arrowRight         = Color(0xFF78FFB8); // Mint
  static const arrowUpRight       = Color(0xFFB47CFF); // Lavender
  static const arrowUpLeft        = Color(0xFFFF8DE0); // Pink
  static const arrowDownRight     = Color(0xFF5CE8FF); // Sky
  static const arrowDownLeft      = Color(0xFFFFD166); // Gold
  
  // State overlays
  static const freeGlow           = Color(0xFFFFFFFF); // White glow on free arrows
  static const blockedFlash       = Color(0xFFFF3B30); // Red on blocked tap
  static const comboHighlight     = Color(0xFFFFD700); // Gold combo text
}
```

### 8.2 Arrow Visual Anatomy

Each arrow is rendered via Canvas (CustomPainter or Flame Canvas API):

```
Arrow components:
  1. Shadow layer
     - Blurred ellipse below arrow
     - Color: black at 40% opacity
     - Blur radius: 8px
     - Y offset: 4px
  
  2. Arrow body
     - Filled shape: arrowhead + shaft
     - Base color: direction-mapped color
     - Gradient: lightest at tip (120% brightness), darkest at tail (70% brightness)
     - Border: 1.5px white at 20% opacity (frosted glass edge)
  
  3. Gloss layer
     - Top-left ellipse highlight
     - White at 25% opacity
     - Blurred (radius 3px)
  
  4. Glow ring (free arrows only)
     - Blurred circle around arrow
     - Arrow's color at 50% opacity
     - Animated pulse (see 7.3)
```

### 8.3 Grid Visual

```
Grid background:
  - Subtle dot grid: circles of radius 1px, every cell center
  - Color: white at 8% opacity
  - No lines (cleaner look)

Empty cell (after arrow removed):
  - Faint rounded square outline
  - White at 6% opacity
  - Helps player see the board structure
```

### 8.4 Typography

```
Font: Space Grotesk (Google Fonts, bundled)
  - Combo counter:   48sp, Bold, White
  - "×10 Combo":     32sp, Bold, Gold (#FFD700), letter-spacing 2px
  - "Puzzle Cleared": 40sp, ExtraBold, White, subtle shadow
  - Level subtitle:  16sp, Regular, White 60%
```

### 8.5 Visual States at a Glance

| Arrow State | Glow | Opacity | Shadow | Border |
|---|---|---|---|---|
| Free | Pulsing white | 100% | Soft | White 20% |
| Blocked | None | 85% | Minimal | White 10% |
| Tapped (wrong) | Red flash | 100% | Normal | Red 80% |
| Exiting | Intensifying | 100→0% | Lifts | White 40% |
| Removed | — | 0% | — | — |

---

## 9. Audio System

### 9.1 Sound Design Spec

All sounds should be synthesized or sourced as royalty-free, crisp, and short:

| Sound | Duration | Description | Trigger |
|---|---|---|---|
| `whoosh` | 180ms | Soft air swoosh, rises in pitch | Arrow exits successfully |
| `thud` | 80ms | Muted, low-frequency bump | Blocked arrow tap |
| `pop` | 60ms | Clean, bright pop | Arrow starts exit animation |
| `settle` | 200ms | Gentle shimmer | Nearby arrows settle |
| `combo_tick` | 50ms | Rising chime note | Each arrow in a combo streak |
| `combo_milestone` | 400ms | Full chord swell | Hitting 5x, 10x, 25x combo |
| `level_complete` | 1200ms | Ascending fanfare | Board cleared |
| `ambient_loop` | 30s | Minimal, melodic ambience | Always playing, 30% volume |

### 9.2 Implementation

```dart
class AudioService {
  // Pre-warm all sounds on game start
  Future<void> initialize() async {
    await FlameAudio.audioCache.loadAll([
      'whoosh.ogg',
      'thud.ogg', 
      'pop.ogg',
      'settle.ogg',
      'combo_tick.ogg',
      'combo_milestone.ogg',
      'level_complete.ogg',
    ]);
    
    // Start ambient loop
    await FlameAudio.bgm.play('ambient_loop.ogg', volume: 0.3);
  }

  // Sound pool for whoosh — prevent overlap cutoff on rapid taps
  void playWhoosh() => FlameAudio.play('whoosh.ogg', volume: 0.7);
  void playThud()   => FlameAudio.play('thud.ogg',   volume: 0.5);
}
```

### 9.3 Audio Rules

- All sounds pre-loaded before first frame is shown
- `whoosh` can overlap itself (rapid arrow removals should each make a sound)
- `thud` has 100ms cooldown (prevent stutter on repeated wrong taps)
- Ambient music ducks (volume −40%) during combo milestone sound, then recovers
- All audio respects system silent mode (check `SoundMode` on Android, `AVAudioSession` on iOS)

---

## 10. Screen & UI Specification

### 10.1 Game Screen Layout

```
┌────────────────────────────────┐
│                                │  ← Status bar (system, hidden or dark)
│   [Combo: ×3]    [Arrows: 47] │  ← Minimal HUD, top — 40pt height
│                                │
│                                │
│          ╔═══════╗             │
│          ║       ║             │
│          ║  GRID ║             │
│          ║       ║             │
│          ╚═══════╝             │
│                                │
│                                │
│   [Restart]              [?]  │  ← Bottom bar — 56pt height
└────────────────────────────────┘
```

### 10.2 HUD Components

**Combo Counter**
- Position: top-left, 16px padding
- Shows: "×N" where N is current combo
- Animates: scale bounce on every increment
- Hides at ×1 (no combo yet), appears at ×2

**Arrows Remaining**
- Position: top-right, 16px padding
- Shows: remaining count
- Animates: count ticks down with a quick scale pop on each removal

**Restart Button**
- Bottom-left
- Icon only (circular arrow icon)
- No text
- Confirmation: tap once — arrow icon shakes; tap again within 2 seconds — restarts

**Help Button**
- Bottom-right
- "?" icon
- Phase 1: shows a simple 3-second animation demonstrating a free vs blocked arrow

### 10.3 Gestures

| Gesture | Action |
|---|---|
| Single tap on arrow | Try to remove arrow |
| Pinch | Zoom in/out (min 0.6×, max 2.5×) |
| Two-finger drag | Pan the board |
| One-finger drag (on empty space) | Also pan |
| Two-finger rotate | Rotate board view ±30° |
| Double tap (on empty space) | Reset camera to default |

### 10.4 App Entry Point

The app must open directly to the Game Screen. No splash screen. No loading screen. The game should be interactive within 1 second of app open on a mid-range device (Snapdragon 695 / A14 class).

```dart
void main() {
  runApp(
    ProviderScope(
      child: GameApp(),
    ),
  );
}

class GameApp extends StatelessWidget {
  Widget build(BuildContext context) => MaterialApp(
    home: GameScreen(),     // No Navigator, no routes in Phase 1
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
  );
}
```

---

## 11. State Management

### 11.1 GameNotifier

```dart
@riverpod
class GameNotifier extends _$GameNotifier {
  
  @override
  GameState build() => _loadLevel(level: 1);

  // Called from tap detector in ArrowComponent
  void tryRemoveArrow(String arrowId) {
    final arrow = state.arrows.firstWhere((a) => a.id == arrowId);
    
    if (arrow.state != ArrowState.free) {
      // Trigger blocked animation via event
      _events.add(GameEvent.blocked(arrowId));
      return;
    }

    // Remove arrow, recompute freedom, update combo
    final updated = state.arrows.map((a) {
      if (a.id == arrowId) return a.copyWith(state: ArrowState.removed);
      return a;
    }).toList();

    final recomputed = _recomputeFreedom(updated);
    final newCombo = state.combo + 1;

    state = state.copyWith(
      arrows: recomputed,
      combo: newCombo,
      removed: state.removed + 1,
      isComplete: recomputed.every((a) => a.state == ArrowState.removed),
    );
    
    // Trigger exit animation + particles via event
    _events.add(GameEvent.arrowRemoved(arrowId, arrow.direction));
    if (state.isComplete) _events.add(GameEvent.levelComplete());
  }

  void resetLevel() {
    state = _loadLevel(level: 1);
    _events.add(GameEvent.levelReset());
  }
}
```

### 11.2 Event Bus

Game state changes (data) are separated from animations (presentation). Animations are triggered by events, not by watching state directly. This prevents animation logic from polluting game logic.

```dart
// GameEvent types
sealed class GameEvent {
  const factory GameEvent.arrowRemoved(String id, ArrowDirection dir) = ArrowRemovedEvent;
  const factory GameEvent.blocked(String id) = ArrowBlockedEvent;
  const factory GameEvent.levelComplete() = LevelCompleteEvent;
  const factory GameEvent.levelReset() = LevelResetEvent;
  const factory GameEvent.comboMilestone(int combo) = ComboMilestoneEvent;
}
```

---

## 12. Performance Targets

| Metric | Target | Measurement Method |
|---|---|---|
| App cold start to interactive | < 1.0 sec | Stopwatch on first frame rendered |
| Touch → first animation frame | < 16ms (1 frame) | Flutter DevTools Frame Chart |
| Steady-state FPS | 60fps (120fps on capable devices) | Flutter Performance Overlay |
| Frame budget per frame | < 8ms render + 4ms raster | Flutter DevTools Timeline |
| Memory usage (gameplay) | < 150MB | Android Profiler / Instruments |
| APK size (Android) | < 25MB | flutter build apk --analyze-size |
| IPA size (iOS) | < 30MB | Xcode Organizer |

### Performance Rules

- All game rendering in Flame canvas — no Flutter widgets inside the game area
- Arrow components use `@override bool get isRemovedOnUnload => true` to ensure cleanup
- Particle system capped at 150 concurrent particles
- Sound pre-loaded, never loaded on demand during gameplay
- Freedom recomputation runs on isolate if arrow count > 200 (not needed in Phase 1)

---

## 13. Folder Structure

```
lib/
├── main.dart
├── app/
│   └── game_app.dart
│
├── game/
│   ├── arrow_tap_out_game.dart       # FlameGame root
│   ├── components/
│   │   ├── arrow_component.dart      # Individual arrow rendering + tap + animation
│   │   ├── board_component.dart      # Grid layout, owns all ArrowComponents
│   │   ├── particle_trail.dart       # Exit trail particle effect
│   │   ├── confetti_component.dart   # Completion burst
│   │   └── empty_cell_component.dart # Hole left after arrow removed
│   │
│   ├── logic/
│   │   ├── freedom_checker.dart      # isFree() + recomputeFreedom()
│   │   ├── level_loader.dart         # Parses level data → GameState
│   │   └── level_data.dart           # Hardcoded Level 1 puzzle definition
│   │
│   └── camera/
│       └── game_camera.dart          # Handles zoom/pan/rotate gestures
│
├── state/
│   ├── game_state.dart               # @freezed GameState, Arrow, ArrowDirection
│   ├── game_notifier.dart            # Riverpod StateNotifier
│   └── game_events.dart              # Event bus for animation triggers
│
├── audio/
│   └── audio_service.dart            # FlameAudio wrapper, pre-warming, ducking
│
├── ui/
│   ├── game_screen.dart              # Root screen widget, overlays HUD on Flame
│   ├── hud/
│   │   ├── combo_counter.dart
│   │   └── arrows_remaining.dart
│   └── overlay/
│       ├── level_complete_overlay.dart
│       └── help_overlay.dart
│
└── design/
    ├── colors.dart                   # GameColors
    ├── typography.dart               # TextStyles
    └── constants.dart               # Grid size, animation durations, cell size

assets/
├── audio/
│   ├── whoosh.ogg
│   ├── thud.ogg
│   ├── pop.ogg
│   ├── settle.ogg
│   ├── combo_tick.ogg
│   ├── combo_milestone.ogg
│   ├── level_complete.ogg
│   └── ambient_loop.ogg
└── fonts/
    └── SpaceGrotesk-Variable.ttf
```

---

## 14. Phase 1 Milestone Plan

### Week 1 — Foundation
- [ ] Flutter + Flame project setup, all dependencies configured
- [ ] `GameState`, `Arrow`, `ArrowDirection` models with Freezed
- [ ] `freedom_checker.dart` with unit tests (100% coverage on logic)
- [ ] `GameNotifier` wired to Riverpod
- [ ] Level 1 puzzle hardcoded and validated as solvable
- [ ] Basic board renders (no animations, just static arrows)
- [ ] Tap detection working, state updates correctly

**Milestone check:** Board is interactive, arrows can be removed in correct order, wrong taps are rejected. No animations yet.

### Week 2 — Animation Core
- [ ] Arrow exit animation (all phases — anticipation, squish, launch)
- [ ] Blocked arrow shake + red flash animation
- [ ] Particle trail on exit
- [ ] Nearby arrow settle animation
- [ ] Free arrow idle pulse glow
- [ ] Ambient board float animation
- [ ] Shadow and glow rendering on ArrowComponent

**Milestone check:** A player can play the game and it feels premium. Every tap has satisfying feedback.

### Week 3 — Audio + Camera + Polish
- [ ] All 8 audio assets integrated and pre-loaded
- [ ] Pinch-to-zoom, two-finger pan, rotate gesture
- [ ] Double-tap to reset camera
- [ ] Combo counter HUD with bounce animation
- [ ] Arrows remaining counter
- [ ] Level complete sequence (confetti, zoom, overlay)
- [ ] Restart button with confirmation

**Milestone check:** Full gameplay loop works end-to-end with audio and camera.

### Week 4 — Performance + QA
- [ ] Profile on target devices: Pixel 6, Samsung A54, iPhone 12, iPhone SE 3
- [ ] Hit all performance targets from Section 12
- [ ] Fix any jank (use Flutter DevTools, identify expensive builds)
- [ ] Ensure no memory leaks (particle components cleaned up)
- [ ] Test on both 60fps and 120fps display devices
- [ ] Test with 50 arrows, verify no dropped frames during rapid removal
- [ ] Accessibility: ensure tap targets are minimum 44×44pt
- [ ] Internal team playtesting — collect feel feedback, iterate animations

**Milestone check:** Phase 1 complete. Ready for TestFlight / internal Android track.

---

## 15. Future Phases (Out of Scope Now)

**Phase 2 — Level System**
- Level selection screen with ~20 levels
- Progression save/load (Hive or SharedPreferences)
- Difficulty tiers: Beginner (50 arrows), Medium (100), Hard (250)
- Star rating based on combo performance

**Phase 3 — Obstacles**
- Ice (frozen arrows needing surrounding arrows removed first)
- Lock + Key mechanic
- Bomb arrows (chain explosion)
- Portals

**Phase 4 — 3D & Premium Feel**
- True 3D board using Flame3D or a custom SceneKit/ARKit layer
- 3D arrow models with real-time lighting
- Shape variety: circle, star, cube, heart packed with arrows

**Phase 5 — Monetization**
- Premium arrow skin packs
- Background themes
- Particle effect packs
- No ads (premium positioning)

**Phase 6 — Community**
- Daily challenge (server-defined puzzle, same for all players)
- Weekly tournaments
- Leaderboard by completion time and combo score

---

*This document is the single source of truth for Arrow Tap-Out Phase 1. Any feature not listed here is out of scope. Any ambiguity in animation timing or behavior defaults to "what feels most satisfying" — developers are empowered to make aesthetic calls within the values defined in Section 3.*

---

**Document owner:** Product  
**Last updated:** June 2026  
**Next review:** End of Week 1 development