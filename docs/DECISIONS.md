# Architecture & Design Decisions

## 1. Naming & Package Identity
- **Working Title**: Unwind
- **Application Label**: Unwind
- **Pubspec Package**: arrowtapout (matches workspace directory, no external collisions)

## 2. Dependencies
- Strictly limited to the approved offline stack:
  - `flutter_riverpod`: State management with zero code generation
  - `go_router`: Declarative routing with custom fade-through transitions and guards
  - `shared_preferences`: Lightweight local key-value store for progress, settings, and snapshots
  - `in_app_update`: Google Play native in-app updates
  - `in_app_review`: Google Play native in-app review
  - `audioplayers`: Low-latency audio playback with ambient audio context
  - `package_info_plus`: Version inspection for About dialog/sheet
- Zero network, ad, analytics, or remote font packages.

## 3. Bundled Typography
- **Newsreader** (SIL OFL 1.1): Variable serif font used for display numerals, level numbers, and titles.
- **Manrope** (SIL OFL 1.1): Clean geometric sans-serif for UI, buttons, and captions.
- Bundled directly in `assets/fonts/` with SIL OFL license declarations.

## 4. Audio & Haptics Strategy
- 4 short, organic acoustic sound effects (`pull.ogg`, `block.ogg`, `complete.ogg`, `ui.ogg`) under 60 KB each.
- Audio players pooled for simultaneous pull effects without clipping.
- Ambient audio context configured to prevent interrupting user background media.
- Standard platform `HapticFeedback` toggled by user preference.

## 5. Pure-Dart Engine Isolation
- `lib/engine/` has zero Flutter imports, enabling 100% pure unit testing and CLI tool re-use.
