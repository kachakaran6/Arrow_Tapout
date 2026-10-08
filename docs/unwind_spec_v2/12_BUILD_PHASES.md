> REVISION 2 applies: see 13_REVISION_2_FIX_PROMPT.md. Where it conflicts with this file, 13 wins.

# 12 Build phases

Feed one phase at a time. Each phase ends with: `flutter analyze` clean, `flutter test` green, a short report, and a stop for approval. Always re-read the referenced spec files before starting.

---
## Phase 0 - Bootstrap
Read: 01, 07.
Prompt: Create the Flutter project (Android only, org and name placeholders to confirm with me). Set up pubspec with the allowed packages, lints, folder layout from 07, portrait lock, edge-to-edge, `docs/DECISIONS.md`, `tool/check_all.sh`. Bundle fonts and register them. App launches to a blank `bg` screen.
Exit: app runs, analyzer clean, folder layout matches 07, no banned packages.

## Phase 1 - Tokens and themes
Read: 05.
Prompt: Implement primitives, `AppTokens` ThemeExtension with copyWith and lerp, the five themes, typography, component tokens, `context.tokens`, and the theme provider with Follow system. Build a temporary gallery screen showing every token and a swatch of every theme, with a theme switcher that lerps. Write the contrast test.
Exit: contrast test passes for all themes, gallery switches smoothly, no raw colours outside `design/`.

## Phase 2 - Engine
Read: 03.
Prompt: Implement `lib/engine/` exactly as specified with full unit tests: model, rays, BoardState, validity, solver, depth, hit-test geometry helpers (pure math). No Flutter imports.
Exit: engine tests green, 100 percent branch coverage on rays, canExit, solver.

## Phase 3 - Level generator and assets
Read: 04, 03.
Prompt: Implement `tool/generate_levels.dart` and `tool/shapes.dart` using reverse construction. First produce chapter 1 and `tool/level_report.md`, show me the stats, then wait. After approval generate all 10 chapters. Add `--verify` and the levels test.
Exit: 200 levels, all valid and solvable, targets met, report committed, verify wired into tests.

## Phase 4 - Renderer and animation
Read: 06, 05.
Prompt: Build `board_view`, static and dynamic painter layers, thread path caching, arrowhead chevron, exit animation with anticipation and acceleration, blocked bounce with spring, hint outline, level-start stagger, reduce-motion variants, board layout and zoom. Create a dev-only playground screen that loads any level id and lets me tap threads. No game rules beyond engine calls yet.
Exit: tapping a free thread glides out smoothly with bent bodies following the path, blocked taps bounce and pulse the blocker, 60 fps in profile on the largest board, golden tests for painter in all themes.

## Phase 5 - Game controller and Game screen
Read: 03, 08.
Prompt: Implement `GameController` and state (mistakes, hints, completion, failure, snapshot), hit tester wiring, top bar, mistake dots, threads-left caption, Pause, Complete and Failed sheets, coach mark on level 1, star calculation.
Exit: a level can be played start to finish; controller tests green; integration test auto-plays several levels.

## Phase 6 - Navigation and screens
Read: 07, 08.
Prompt: Implement go_router with the route table, guards, transitions, PopScope behaviour, Splash, Home (with ambient board), Level select, Settings, Theme picker, How to play, Stats. Replace the dev playground.
Exit: navigation tests green, every flow in 08 works, back button behaves per spec, all screens correct in all five themes.

## Phase 7 - Persistence and progression
Read: 10, 04.
Prompt: Implement repositories, schema and migration, progress, unlocking, stars, hint bank growth, stats, snapshot save and resume, reset progress. Wire Continue on Home.
Exit: kill and resume works, progress survives restarts, persistence tests green.

## Phase 8 - Audio and haptics
Read: 10.
Prompt: Implement audio service with pooled players and haptics helper, settings wiring. Source or synthesise original sounds and document licences. Tell me exactly which sound files I should review.
Exit: sounds play with low latency, respect settings, do not steal audio focus.

## Phase 9 - Play update and review
Read: 09.
Prompt: Implement `UpdateService` and `ReviewService` with the exact rules in 09, interface plus no-op, eligibility logic with a fake clock, hooks on Home and Level select. Verify the installed package APIs from source. Write `docs/PLAY_TESTING.md` and `docs/PERMISSIONS.md`. Do not create any custom update or review UI.
Exit: unit tests green, grep shows no custom rating or update UI, merged release manifest permissions documented.

## Phase 10 - Polish and accessibility
Read: 05, 06, 08, 11.
Prompt: Audit every screen for token use, spacing, copy, motion quality and anti "AI look" rules. Add semantics, text scale 1.3 checks, reduce-motion pass, small-screen (320 dp) pass, tablet sanity. Fix jank found in profile mode and record `docs/PERF.md`. Design the app icon and splash mark from the thread motif.
Exit: manual QA checklist items for visuals and accessibility pass; screenshots of five themes produced.

## Phase 11 - QA and release prep
Read: 11.
Prompt: Run the full CI script, the manual checklist, offline check, and produce a signed release app bundle with R8 and obfuscation. Fill `docs/RELEASE.md` with every step left for me in Play Console. Report remaining risks.
Exit: all boxes in the 11 release checklist that can be done in code are done; a list of manual Play Console tasks remains for the user.
