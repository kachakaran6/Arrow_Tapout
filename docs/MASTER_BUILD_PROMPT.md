# MASTER BUILD PROMPT — Arrow Puzzle (Flutter)

Act as a principal Flutter engineer, mobile game designer, interaction designer, and QA lead. Build a production-quality, fully offline arrow-removal puzzle game based on the four supplied reference screenshots. The references show a quiet cream paper-like background, tiny low-contrast dot texture, dark brown line-art arrows, and compact editorial titles with one rust-colored accent. The core interaction is to tap an arrow/path; if it can leave the board unobstructed in its pointing direction, it smoothly exits the play area. If blocked, it remains in place and the player receives clear, restrained feedback. The board gradually forms satisfying patterns and later levels become more complex.

Do not merely create a mockup. Deliver a maintainable Flutter project with a working game engine, real local level data, persistence, settings, progression, native Android Play Core integration, tests, and release documentation.

## Required working method
- Inspect the existing repository before changing anything. Preserve working code and project conventions.
- If the repository is empty, create a clean Flutter application using the current stable Flutter/Dart APIs and document the exact versions used.
- Before implementation, write a short architecture proposal and a task checklist in `/docs/IMPLEMENTATION_PLAN.md`.
- Implement phase-by-phase using `10_IMPLEMENTATION_PHASES.md`. Keep changes small, buildable, and testable.
- After each phase run formatting, static analysis, unit tests, widget tests, and relevant integration tests. Fix failures before moving on.
- Do not claim a test passed unless it was actually run.
- Avoid TODO-only screens, fake buttons, placeholder levels, mock native flows, and decorative controls that do nothing.
- Do not add cloud services or network dependencies for game functionality. No login, account, telemetry, analytics, ads, remote config, cloud backup, online leaderboard, or server-side level delivery.
- Do not use emojis. Use a consistent icon library or custom vector icons.
- Do not blindly copy screenshot dimensions. Build responsive layouts for phones and tablets, portrait first, with safe areas and dynamic board sizing.
- Prefer straightforward, strongly typed, testable code over abstractions without a clear benefit.

## Product outcome
A calm, premium arrow-path puzzle game. The player progresses through levels one at a time. Each board contains connected orthogonal paths with directional arrowheads. Tapping an arrow tests whether its exit ray is clear. A valid arrow travels out of the board with a clean, fluid animation and is removed. An invalid move does not remove the arrow and shows a short, non-punitive blocked response. Continue until the board is empty. A level is completed only when every arrow is removed. Add restart, pause, optional undo only if implemented robustly, sound/haptics settings, theme selection, progress map/list, and an offline help screen.

## Source-of-truth specifications
Read and obey:
- `01_PRODUCT_REQUIREMENTS.md`
- `02_GAME_ENGINE_AND_LEVEL_FORMAT.md`
- `03_DESIGN_SYSTEM_AND_THEMES.md`
- `04_NAVIGATION_AND_SCREEN_SPEC.md`
- `05_OFFLINE_ARCHITECTURE_AND_PERSISTENCE.md`
- `06_NATIVE_PLAY_CORE_INTEGRATIONS.md`
- `07_MOTION_AUDIO_ACCESSIBILITY.md`
- `08_QA_RELEASE_AND_ACCEPTANCE.md`
- `09_LEVEL_CONTENT_PLAN.md`
- `10_IMPLEMENTATION_PHASES.md`

When requirements conflict, prioritize privacy/offline requirements, correct game rules, accessibility, and the explicit acceptance criteria. Record any unavoidable platform limitation rather than hiding it.

## Core game rules
Implement the game rules as a pure Dart engine independent from Flutter widgets:
1. A level contains uniquely identified arrow paths. Each path is an orthogonal polyline on a normalized grid and has exactly one exit-facing direction.
2. A tap identifies a specific arrow by stable ID, not by nearest pixel guessing.
3. An arrow is removable only when the ray from its designated arrowhead to the board boundary in its exit direction does not intersect any other active arrow path. Define collision semantics precisely and test edge cases.
4. If clear, mark the arrow as exiting and animate its path/visual representation out of the board; remove it from active gameplay after animation completes. Keep engine state and rendered animation state consistent.
5. If blocked, preserve board state and show a subtle shake/nudge plus optional haptic tick. Never use a harsh red flash or a modal dialog for a routine invalid move.
6. Level completes exactly once when no active arrows remain. Prevent double completion during animation races.
7. Restart restores the original level state. App pause/resume must not corrupt a move.
8. The engine must be deterministic and fully offline.

## Technical requirements
- Flutter + Dart. Use a feature-first structure with clear domain/data/presentation boundaries.
- Use a custom `CustomPainter` or an equivalently efficient vector-rendering approach for the board. Do not create one heavy widget per line segment.
- Use typed immutable models for level definitions and runtime state.
- Use a locally bundled level catalog. JSON or Dart constants are acceptable; validate every bundled level in tests.
- Persist progress, settings, selected theme, unlock state, and optional per-level best stats locally. Use a small local database or robust key-value store appropriate to the data size; hide it behind repositories.
- All core gameplay, navigation, settings, themes, help, and progression must work in airplane mode after install.
- Avoid permissions unless essential. Do not request contacts, location, microphone, camera, or storage access for core gameplay.
- No external webview, web-based game board, or remote asset requirement.
- Keep native Android integration isolated behind a service interface. Google Play update and review flows must use official native Play Core APIs and only show where eligible/available. No custom imitation of a Play Store review/update sheet.
- Support system back navigation correctly. Do not trap users in a screen.
- Use semantic labels, scalable text, adequate contrast, and tap targets that meet platform guidance.
- Use adaptive layout, handle system text scaling, and avoid overflow on narrow and large screens.
- Add unit tests for collision/ray tracing, level validation, progress persistence, and level transitions; widget tests for critical screens; integration tests for complete level flow.

## Visual direction
Use `03_DESIGN_SYSTEM_AND_THEMES.md` as the single source of truth for tokens. Default theme: Warm Paper. Offer exactly five coherent theme choices initially. All are muted, sophisticated, and accessible. Avoid gradients unless exceptionally subtle and justified; the default board should be flat, warm, and quiet. The dot texture must be low contrast and cheap to render, with a reduced-motion/low-power fallback. No AI-generated decorative art is needed; board geometry itself is the art.

## Motion direction
A successful arrow should move along its own vector/path toward the nearest valid board exit with a confident, polished ease-in/ease-out curve. Use a short stagger only if multiple visual segments are part of the same arrow. Fade slightly near exit, but do not blur or glow. Keep the board stable; other arrows must not jump to fill gaps. Blocked taps get a tiny 100–160 ms directional nudge and return to rest. Completion transitions should feel quiet and earned, not explosive. Respect reduced motion.

## Product-quality details
- Show level number, concise progress (remaining arrows), pause/settings access, and a clear restart action without clutter.
- Use an unobtrusive completion transition and a next-level action.
- Save progress immediately after important state changes; protect against app termination mid-animation.
- Do not mark a move as removed until it is accepted by the engine; use a pending-exit state to avoid race conditions.
- Use a single centralized token system across all screens.
- Keep scroll behavior intentional: screen shell remains stable while only designated content areas scroll.
- Handle empty, locked, completed, interrupted, and corrupted-progress states gracefully.
- Provide a local privacy statement explaining that progress and preferences stay on the device. Do not claim that the Play Store review/update operations are offline; they require Google Play services and network availability.
- The app must still be fully playable when Play Core is unavailable. Hide or disable only those native store actions gracefully.

## Deliverables
1. Complete Flutter source code.
2. Bundled, validated levels and a scalable authoring format.
3. Five premium themes and centralized design tokens.
4. All screens and navigation described in the docs.
5. Local persistence and recovery behavior.
6. Official native Play update/review integration, with platform eligibility checks and graceful fallback.
7. Tests and documented test results.
8. README with setup, run, test, build, and release instructions.
9. Android release checklist, privacy/data-safety notes, and app icon/source asset guidance.
10. A final implementation report listing files changed, features completed, tests run with actual results, known limitations, and exact commands to reproduce.

## Final gate
Do not call the project production-ready until the acceptance checklist in `08_QA_RELEASE_AND_ACCEPTANCE.md` is met. If a requirement cannot be completed in the environment, implement the correct interface and document the exact remaining native/platform work. Never fabricate completion.
