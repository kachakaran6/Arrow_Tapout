# 10 Offline, persistence, audio, haptics

## Offline guarantees
- No code path may require the network. No `http`, `dio`, `firebase_*`, `google_fonts`, `google_mobile_ads` or similar in pubspec.
- All fonts in `assets/fonts` (Newsreader and Manrope, SIL OFL, include licence files and register them in `LicenseRegistry`). All levels in `assets/levels`. All audio in `assets/audio`.
- Release manifest declares no `INTERNET` permission (see 09). Add a CI-style test script `tool/check_offline.sh` that fails if pubspec contains a banned package or the merged release manifest contains INTERNET.
- Privacy statement in About: nothing is collected or transmitted by the app itself.

## Persistence (`shared_preferences`, versioned JSON)
Keys, all under prefix `unwind.`:
- `schema` int, current 1; a migration function runs on startup.
- `settings` JSON: themeChoice, sound, haptics, reduceMotion.
- `progress` JSON: highestUnlocked, stars map (levelId -> 1..3), hintBank, stats counters, coachMarkShown, lastTapStreak.
- `snapshot` JSON: levelId, activeThreadIds, mistakes, hintsUsed, savedAt. Written on lifecycle `paused` and after every successful exit (debounced 300 ms); cleared on completion or restart.
- `play.lastUpdateCheck`, `play.lastUpdateDismiss`, `play.lastReviewRequest`, `play.reviewMilestonesTried`.
Writes are debounced and awaited on `paused`. Reads tolerate missing or malformed values by falling back to defaults.

## Audio (`audioplayers`, low-latency)
Four short effects, 44.1 kHz mono OGG or WAV, under 60 KB each, soft and wooden or fibre-like, not synthetic bleeps:
1. `pull.ogg` thread slides out (pitch varied +/- 6 percent with `setPlaybackRate`),
2. `block.ogg` soft muted tap,
3. `complete.ogg` gentle two-note resolve,
4. `ui.ogg` tiny tick for buttons.
Source: record or synthesise original sounds, or use CC0 packs and record the licence in `assets/audio/LICENSES.md`. Pool players (4 for `pull`) to allow overlap. Respect the Sound setting and `AudioContext` with `AndroidAudioFocus.none` and `ambient` usage so the user's music is not interrupted.

## Haptics
Use `HapticFeedback` only: `selectionClick` on UI taps, `lightImpact` on a successful exit, `mediumImpact` on a blocked tap, `heavyImpact` never. A single helper `Haptics.exit()` etc. so it is toggleable. Respect the Haptics setting.

## Lifecycle and resilience
- Kill the process mid-level and relaunch: Continue returns to the same level with the same active threads and mistake count.
- Update restart (Play flexible) behaves identically.
- Low-memory: only the current and next chapter JSON are kept in memory.
