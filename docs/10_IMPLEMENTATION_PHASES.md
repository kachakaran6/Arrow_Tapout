# Implementation Phases

## Phase 0 — Repository and design audit
- Inspect repository, Flutter/Dart versions, current dependencies, and existing assets.
- Record architecture and dependency choices.
- Establish design tokens and a runnable baseline.
- Exit gate: app builds and runs before game implementation.

## Phase 1 — Pure game domain
- Implement geometry, arrow/level models, collision checks, move results, solver, validator.
- Create focused unit tests for all four directions and boundary conditions.
- Exit gate: domain tests pass without Flutter widgets.

## Phase 2 — Renderer and interaction
- Build efficient vector board painter and deterministic hit testing.
- Implement success exit animation and blocked nudge.
- Handle rapid taps and pending-exit state.
- Exit gate: one playable sample level with correct rules.

## Phase 3 — Local level catalog
- Add authored level schema and bundled level loading.
- Validate all bundled levels and test solvability.
- Exit gate: every included level is validated and playable.

## Phase 4 — Persistence and progression
- Store completion, unlocks, current level, settings, and recovery state locally.
- Add restart, pause, completion, and next-level transitions.
- Exit gate: progress survives app restart and animation interruption.

## Phase 5 — Complete UI and navigation
- Home, level selection, gameplay, pause, completion, settings, theme picker, help, about/privacy.
- Correct back navigation and responsive layout.
- Exit gate: no dead links or inert controls.

## Phase 6 — Design polish and accessibility
- Apply five themes through semantic tokens.
- Tune typography, board scaling, line quality, touch targets, motion, haptics, semantics.
- Exit gate: test all themes and accessibility settings.

## Phase 7 — Native Play integrations
- Implement official in-app update and review interfaces.
- Verify fallback behavior on debug/non-Play installs.
- Exit gate: game works without Play Core; native flows verified on internal test track where possible.

## Phase 8 — Quality and release
- Run formatting, analyzer, tests, level validation, performance profiling, and airplane-mode test.
- Prepare store assets, privacy/data safety notes, and release checklist.
- Exit gate: all acceptance criteria pass or remaining limitations are clearly documented.

## Engineering cadence
- Keep commits small and descriptive.
- Suggested commit sequence: `chore: establish Flutter app baseline`, `feat: implement arrow puzzle domain`, `feat: render interactive board`, `feat: bundle validated levels`, `feat: persist local progression`, `feat: add navigation and settings`, `feat: add five themes`, `feat: integrate Play Core services`, `test: add release acceptance coverage`.
- Never combine a broad UI rewrite, game engine change, and native integration into one opaque commit.
