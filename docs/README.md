# Arrow Puzzle — Production Product Kit

This kit is the product and implementation brief for building a polished, fully offline Flutter arrow-removal puzzle game inspired by the supplied visual references.

## How to use this kit
1. Read `MASTER_BUILD_PROMPT.md` and give it to your coding agent as the main instruction.
2. Give the remaining Markdown files to the agent as required project specifications. Keep them in the repository under `/docs`.
3. Implement in small, reviewable phases. Do not generate the entire app in one unreviewable change.
4. Treat the screenshots as visual inspiration, not pixel-perfect assets. Rebuild the board as vector geometry and data-driven paths.

## Files
- `MASTER_BUILD_PROMPT.md` — master end-to-end implementation prompt.
- `01_PRODUCT_REQUIREMENTS.md` — game definition, rules, progression, UX.
- `02_GAME_ENGINE_AND_LEVEL_FORMAT.md` — deterministic offline puzzle model, validation, level schema.
- `03_DESIGN_SYSTEM_AND_THEMES.md` — tokens and five user-selectable premium palettes.
- `04_NAVIGATION_AND_SCREEN_SPEC.md` — app structure and screen behavior.
- `05_OFFLINE_ARCHITECTURE_AND_PERSISTENCE.md` — architecture, storage, privacy, resilience.
- `06_NATIVE_PLAY_CORE_INTEGRATIONS.md` — native Play update and review flows.
- `07_MOTION_AUDIO_ACCESSIBILITY.md` — animation, haptics, accessibility, performance.
- `08_QA_RELEASE_AND_ACCEPTANCE.md` — tests, acceptance criteria, release checklist.
- `09_LEVEL_CONTENT_PLAN.md` — level progression and content authoring standards.
- `10_IMPLEMENTATION_PHASES.md` — ordered implementation plan and definition of done.

## Non-negotiable product principles
- Flutter mobile app, Android-first with clean cross-platform boundaries.
- Entire game works offline after installation. No account, analytics SDK, ads, remote config, network backend, or cloud save.
- No emoji in UI, documentation-derived UI copy, icons, or game content. Use consistent vector icons where needed.
- Calm, restrained, editorial visual design. No neon, artificial glow, noisy gradients, glassmorphism, or generic AI-looking styling.
- All levels are authored/validated locally and all progress is stored locally.
- Never fake native Google Play update or review UI. Use the official Play Core integrations and gracefully handle unsupported states.
