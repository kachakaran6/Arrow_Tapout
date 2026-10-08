# QA, Release, and Acceptance Criteria

## Product acceptance
- [ ] App launches to a complete Home screen.
- [ ] First-run tutorial explains the rules accurately and can be replayed.
- [ ] At least 60 authored levels are bundled for the first content release, unless the product owner explicitly approves a smaller verified launch catalog.
- [ ] Levels unlock sequentially and progress survives force-stop/relaunch.
- [ ] All levels pass deterministic solvability validation.
- [ ] Tapping a clear arrow removes it with a smooth exit animation.
- [ ] Tapping a blocked arrow leaves it active and gives restrained feedback.
- [ ] Simultaneous/rapid taps cannot remove an arrow twice or finish a level twice.
- [ ] Restart reliably restores the initial level.
- [ ] Completion advances to the next unlocked level.
- [ ] Last-level completion has a graceful terminal state.
- [ ] All five themes apply consistently across every screen and the board.
- [ ] Settings survive relaunch.
- [ ] Entire core game works in airplane mode.
- [ ] No account, network backend, analytics, ads, or remote assets are present.
- [ ] Native Play Core failure does not affect gameplay.
- [ ] No emoji are used in product UI.

## Technical acceptance
- [ ] `dart format` produces no changes.
- [ ] `flutter analyze` has no errors; warnings are reviewed.
- [ ] Unit tests cover geometry, collision, solver, progression, and persistence.
- [ ] Widget tests cover Home, Levels, Gameplay, Settings, pause, and completion.
- [ ] Integration test completes a level, restarts a level, and verifies saved progress after app restart where feasible.
- [ ] All bundled level JSON is schema-validated in CI/local tests.
- [ ] App handles narrow devices, tablet layouts, system font scaling, and safe areas.
- [ ] No unbounded rebuild/render cost from drawing the board.
- [ ] No crashes from invalid route args or corrupted local progress.
- [ ] Play update/review integrations are isolated and have no-op test implementations.

## Device test matrix
- Low/mid-range Android device.
- Recent Android device.
- Small phone viewport.
- Large phone viewport and large text.
- Tablet or emulator with wide viewport.
- Dark/system mode if shipped.
- Airplane mode.
- App background/resume during arrow animation.
- Force-stop/relaunch after a move.
- Play internal-test installation for native Play Core flows.

## Performance goals
Treat as targets, measure on physical hardware:
- Smooth 60 fps on supported mainstream devices during normal gameplay.
- No avoidable full-screen rebuild for every animation tick.
- No visible board layout shift after removing arrows.
- Fast cold launch and immediate touch response.
- Memory remains stable across long level sessions.

## Play Store readiness
- App icon and feature graphic.
- Phone screenshots matching the real shipped UI.
- Store listing description.
- Privacy policy and Data safety answers that match actual implementation and SDK behavior.
- Correct target SDK and signing setup according to current Play requirements.
- Test track verification for in-app updates/review.
- Content rating and app access declarations if applicable.
- No misleading offline claims: core puzzle is offline; Play Store flows may need Play services/network.
- Release build tested with minification/shrinking settings as applicable.

## Definition of done
A feature is done only when its behavior, error state, accessibility, persistence (where applicable), tests, and documentation are complete. Do not label a feature “production-ready” based only on a successful debug build.
