# 07 Architecture and navigation

## Packages (keep this list minimal, pin versions in pubspec)
`flutter_riverpod`, `go_router`, `shared_preferences`, `in_app_update`, `in_app_review`, `audioplayers` (low-latency mode), `package_info_plus`. Dev: `flutter_lints`, `flutter_test`, `integration_test`. Nothing else without a written reason in `docs/DECISIONS.md`. No networking, analytics, ads or remote-font packages.

## Folder layout
```
lib/
  main.dart
  app.dart                  MaterialApp.router, theme wiring
  engine/                   pure Dart (03)
  design/                   primitives, app_tokens, themes, typography, component tokens
  features/
    splash/  home/  levels/  game/  settings/  howto/  stats/
    game/
      game_controller.dart  game_state.dart  board_painter.dart
      board_view.dart  thread_animator.dart  hit_tester.dart
      sheets/ (complete, failed, pause)
  data/
    level_repository.dart   loads assets/levels/*.json lazily per chapter
    progress_repository.dart  settings_repository.dart  snapshot_repository.dart
  platform/
    play_update_service.dart  play_review_service.dart
    audio_service.dart  haptics_service.dart
  router/
    app_router.dart  routes.dart  transitions.dart
tool/  generate_levels.dart  shapes.dart  level_report.md
assets/ levels/  fonts/  audio/
test/  integration_test/  docs/
```
Dependency rule: `features` -> `data`, `design`, `engine`, `platform`. `engine` depends on nothing. `platform` depends on nothing in `features`.

## State (Riverpod)
- `settingsProvider` (theme choice, sound, haptics, reduce motion).
- `progressProvider` (highest unlocked level, stars per level, hint bank, stats).
- `levelRepositoryProvider` (async chapter loading, in-memory cache of the current and next chapter).
- `gameControllerProvider.family<GameController, int>` (one per level id, autoDispose).
- `themeProvider` derives `AppTokens` from settings plus platform brightness.
Immutable state classes with hand-written `copyWith`. Repositories are thin and injectable so tests can override them.

## Route table (go_router)
| Path | Screen | Notes |
|---|---|---|
| `/` | Splash | redirects to `/home`, under 700 ms |
| `/home` | Home | Continue button, Levels, Settings |
| `/levels` | Level select | chapters as sections, grid of level tiles |
| `/play/:id` | Game | validates id is unlocked, else redirects to `/levels` |
| `/settings` | Settings | |
| `/settings/theme` | Theme picker | full screen, live preview |
| `/howto` | How to play | single scrolling page with 3 small animated diagrams |
| `/stats` | Stats | |

- Use `GoRouter` with `redirect` guards (locked level, bad id) and `errorBuilder` that returns to `/home`.
- Navigation from Home to Levels to Play uses `push`; completing a level uses `pushReplacement` to the next `/play/:id` so back from a level returns to `/levels`, not through a stack of old levels.
- Typed route helpers in `routes.dart` (`Routes.play(id)`), no raw strings in widgets.
- Transitions: every route uses `CustomTransitionPage` with the fade-through in `transitions.dart` (see 06). Game route uses a shorter 220 ms fade because the board draws itself in.
- Back handling: on `/play/:id` wrap in `PopScope(canPop: false)` and open the Pause sheet on back; Pause has Resume, Restart, Levels, Settings-lite (sound, haptics). On `/home` back exits the app (default).
- System bars: edge-to-edge, transparent status and navigation bars, icon brightness follows theme.
- Orientation: portrait only (`SystemChrome.setPreferredOrientations`), declared in the manifest too.
- App lifecycle: on `paused`, save the in-progress snapshot; on cold start, Home shows Continue pointing at the saved level.
- Deep links: none. Android back gesture predictive-back enabled via `android:enableOnBackInvokedCallback="true"`.
