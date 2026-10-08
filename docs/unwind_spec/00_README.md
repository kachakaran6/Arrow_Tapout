# Unwind - Flutter game spec pack

Working title: **Unwind** (rename freely, but pick an original name, original icon and original title treatment. Do not reuse the reference game's name, banner style or artwork).

## What this pack is
A complete, ordered specification for building a production-ready, fully offline, Android-first Flutter puzzle game in which the player taps line-and-arrowhead "threads" and each thread slides smoothly out of the board along its own path.

## How to use it with Claude Code (or any coding agent)
1. Put the whole `unwind_spec/` folder in the root of an empty Flutter project (or in `docs/spec/`).
2. Paste the contents of `01_MASTER_PROMPT.md` as the first message. It is self-contained and points at the other files.
3. Then feed `12_BUILD_PHASES.md` one phase at a time. Each phase has its own prompt and acceptance criteria. Do not move to the next phase until the current one passes.
4. When a phase touches a topic, the agent must re-read the matching spec file.

## File map
| File | Purpose |
|---|---|
| 01_MASTER_PROMPT.md | The one prompt that governs everything |
| 02_PRODUCT_AND_SCOPE.md | Product definition, scope, non-goals |
| 03_GAME_RULES_AND_ENGINE.md | Rules, data model, geometry, hit testing, solver |
| 04_LEVEL_GENERATOR_AND_PROGRESSION.md | Offline level generator CLI, shapes, 200-level plan |
| 05_DESIGN_TOKENS_AND_THEMES.md | Token system, 5 themes, anti "AI look" rules |
| 06_ANIMATION_AND_RENDERING.md | Painter architecture, exit/blocked/complete animations |
| 07_ARCHITECTURE_AND_NAVIGATION.md | Folder layout, state, go_router, transitions |
| 08_SCREENS_AND_UX.md | Every screen, sheet, copy and behaviour |
| 09_PLAY_UPDATE_AND_REVIEW.md | Native Play in-app update and in-app review |
| 10_OFFLINE_PERSISTENCE_AUDIO_HAPTICS.md | Storage, audio, haptics, offline guarantees |
| 11_TESTING_QA_RELEASE.md | Tests, performance budget, release checklist |
| 12_BUILD_PHASES.md | 12 build phases, each with a prompt and exit criteria |
