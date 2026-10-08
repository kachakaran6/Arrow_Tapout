# 08 Screens and UX

General: page padding 20 dp, safe-area aware, all tap targets >= 48 dp, all text from the type scale, all colours from tokens. Semantics labels on every interactive element and on the board ("Board, 12 threads left").

## Splash
Flat `bg`. Centre: the app mark (a single thread drawing itself out of a square, 600 ms) then crossfade to Home. No spinner. Native Android 12 splash configured with the same bg colour and mark so there is no flash.

## Home
- Top-left: small wordmark in Newsreader. Top-right: settings glyph button.
- Centre: large current level numeral (display style) with "Level 17" and the chapter name beneath in `inkMuted`.
- Primary button: "Continue" (accent fill). Secondary: "Levels" (outline). Tertiary text button: "How to play".
- A faint decorative board of 6 to 8 threads behind the content, rendered with the real painter at 10 percent ink opacity, slowly (one thread every 3 s) sliding out and redrawing. Disabled under reduce motion.

## Level select
- Sticky chapter header: name, one-line description, "x of 20" progress.
- 5-column grid of tiles (min 56 dp). States: locked (outline only, small lock glyph, `inkFaint`), unlocked (outline, numeral), current (accent outline 2 dp), completed (filled `surfaceRaised`, three tiny star ticks underneath filled by accent).
- Tapping a locked tile: a 120 ms horizontal shake and a snackbar-free hint line under the header reading "Finish level N first". Auto-scroll to current level on open.

## Game
Layout, top to bottom:
1. Top bar: back (opens Pause), "Level 17" centred (title style), hint button right with remaining bank count as a small badge.
2. Board, centred, takes all remaining height.
3. Mistake dots row (3 dots, filled = remaining; hidden in tutorial levels), and a quiet "Threads left 9" caption.
- Level 1 coach mark: a single line "Tap a thread that has a clear path." with the free thread outlined. Dismisses on first tap. Show-once flag stored.
- Pause sheet (native-style bottom sheet, our own UI): Resume, Restart, Levels, Sound toggle, Haptics toggle.
- Complete sheet: "Level complete" (title), three stars drawing in, one line of stats ("12 threads, 1 mistake"), buttons "Next level" (accent) and "Levels". If this was the last level of a chapter, the headline becomes the chapter name plus "complete". After the final level (200): "Nothing left to unwind" with Levels only.
- Failed sheet: "Out of mistakes", buttons "Retry" and "Levels". No guilt copy.
- Board input is disabled while a sheet is open.

## Settings
Grouped list on `surface` with hairline separators: Appearance (Theme row opens `/settings/theme`), Feedback (Sound, Haptics, Reduce motion switches), Help (How to play), About (version, Licences, "Nothing is collected. The game works fully offline."), Danger (Reset progress, confirm sheet with destructive `danger` button). Switches are custom-tinted with accent.

## Theme picker
Full screen. 2-column grid of five tiles plus a first "Follow system" tile. Each tile paints a mini board (same level 12 board) in that theme. Tapping applies instantly with the 280 ms colour lerp so the whole screen behind transitions live. Selected tile shows an accent outline.

## How to play
Three short steps with tiny looping painter animations: 1 Tap a thread with a clear path. 2 A thread in the way blocks it. 3 Clear the board in the right order. Each step is two lines of copy at most.

## Stats
Five figures in a calm two-column list, Newsreader numerals: levels cleared, total stars, threads cleared, perfect levels, best perfect streak.

## Empty, error and edge states
- Missing or corrupt level asset: show a quiet full-screen message "This level could not be loaded" with a Back button, log to debug console only.
- Corrupt preferences: fall back to defaults silently.
- Hint bank empty: button disabled, label "No hints left".

## Copy rules
Sentence case, no exclamation marks, no emoji, no all-caps, numbers as numerals, no marketing voice.
