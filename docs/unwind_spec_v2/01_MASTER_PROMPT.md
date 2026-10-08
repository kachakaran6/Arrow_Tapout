# MASTER PROMPT

You are a senior Flutter engineer and product designer. Build **Unwind**, a production-ready, fully offline Android puzzle game in Flutter. Quality bar: it could be published to Google Play tomorrow and nobody should be able to tell it was machine-generated.

## The game in one paragraph
The board is a grid filled with "threads". A thread is an orthogonal polyline through grid-cell centres, with a tail and a head. The head carries an arrowhead pointing in the direction of the last segment. When the player taps a thread, it slides out along its own path and then in a straight line in its arrow direction until it has fully left the board, but only if nothing is in the way. If another thread sits anywhere on that straight line, the tap is a mistake: the thread nudges forward, stops short of the blocker, and springs back. Clear every thread to finish the level. Levels grow from tiny boards to large rectangles and silhouettes (star, moon, heart, and so on) as the player progresses, one level unlocking the next.

## Hard requirements
1. Flutter (stable channel, Dart 3), Android first. Material 3 base, fully custom visual language through a design-token system.
2. 100 percent offline. No network packages, no analytics, no ads, no remote fonts, no remote config. All levels, fonts, sounds ship in the app. The only network-touching features are the two native Google Play ones below, which are owned by Play Services and must fail silently when offline.
3. Interaction: tapping a thread makes it glide out with a professional, smooth transition (spec in 06). 60 fps minimum, 120 fps capable. Never drop a frame on a 14x26 board.
4. Levels: 200 pre-generated, solvable, verified levels in 10 chapters, produced by an offline Dart CLI generator committed to the repo (spec in 04). Unlocked one by one.
5. Theming: a proper design-token system and 5 hand-tuned themes the user can switch between in Settings (spec in 05). All colours smooth, premium, elegant, restrained. No emojis anywhere in UI, copy, code comments, commit messages or assets.
6. Navigation: go_router with a clean route table, custom fade-through transitions, correct back-button behaviour (spec in 07).
7. In-app update: Google Play In-App Updates API, shown through the native Play bottom sheet. No custom update UI (spec in 09).
8. In-app review: Google Play In-App Review API, shown through the native Play bottom sheet. No custom pre-prompt, no custom rating dialog (spec in 09).
9. Persistence via local storage only (spec in 10). Progress must survive app kill, update and process death.
10. Accessibility: contrast targets, text scaling to 1.3, reduced-motion support, semantic labels, minimum 48dp targets on all chrome (spec in 08 and 11).

## Non-goals
Online leaderboards, accounts, ads, in-app purchases, iOS-specific work, level editor UI, multiplayer.

## Engineering rules
- Pure-Dart engine (no Flutter imports) in `lib/engine/`, fully unit tested.
- Immutable state objects, Riverpod for state, no code generation unless unavoidable.
- No magic numbers in widgets: every colour, spacing, radius, duration, curve and text style comes from tokens.
- Null-safe, lints on (flutter_lints plus `prefer_const_constructors`, `avoid_print`), zero analyzer warnings.
- Small files, one responsibility each. Public APIs documented with one-line doc comments. No commented-out code.
- No emojis, no exclamation-mark-heavy copy, sentence case everywhere.
- Never invent package APIs. If unsure of an API, read the package source in the pub cache before using it.

## Process
1. Read every file in this folder first, in numeric order.
2. Work phase by phase from `12_BUILD_PHASES.md`. At the end of each phase: run `flutter analyze` and `flutter test`, fix everything, then summarise what was done and what to verify manually. Stop and wait for approval before the next phase.
3. If a spec is ambiguous, choose the option that is simplest, most elegant and most consistent with the spec, state the decision in `docs/DECISIONS.md`, and continue. Ask the user only for things that cannot be decided from the spec (app name, applicationId, signing keys, store assets).
4. Never silently drop a requirement. If one is impossible, say so and propose the closest alternative.

## Definition of done
All 12 phases accepted, 200 levels verified solvable by test, release app bundle builds, release manifest requests no unnecessary permissions, checklist in 11 fully ticked.
