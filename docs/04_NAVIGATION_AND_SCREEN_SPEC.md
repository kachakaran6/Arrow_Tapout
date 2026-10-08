# Navigation and Screen Specification

## Navigation model
Use a small, predictable route structure. Suggested routes:
- `/home`
- `/levels`
- `/game/:levelId`
- `/settings`
- `/themes`
- `/help`
- `/about`

Use Flutter Navigator or a lightweight declarative router only if it adds clear value. Avoid an oversized routing framework for a small offline game. Use named, typed route arguments and handle invalid level IDs gracefully.

## Home
- Product wordmark/title rendered as text or a custom vector mark; no emoji.
- Primary Continue action resumes the highest unlocked incomplete level.
- Secondary actions: Levels, Settings.
- Show a restrained progress summary.
- If no saved progress exists, Continue starts the tutorial/first level.
- Avoid unnecessary bottom navigation if there are only a few destinations.

## Level selection
- Group levels into chapters or a compact paginated grid.
- Completed, current, and locked states must be visually distinguishable without color alone.
- Locked levels are not tappable.
- Preserve scroll position when returning from gameplay.
- The content area may scroll; app shell/header should remain stable where appropriate.
- Do not show hundreds of tiny level buttons in one dense screen. Use chapter grouping and pagination.

## Gameplay
- Top row: back/pause, level label, remaining-arrow count, restart.
- Board centered and given the largest available region.
- Controls must remain reachable on small screens and with system text scaling.
- Back opens a pause/exit confirmation only when needed; never silently discard an active level.
- Tapping a line should resolve to its arrow ID using engine-backed geometry hit testing.
- A successful arrow exits smoothly; a blocked arrow remains with a short directional nudge.
- Do not let the board jump or reflow after a removal.
- Support safe areas, landscape gracefully if feasible, and tablets.
- Avoid scroll gestures competing with board taps.

## Pause
- Prefer a compact native-feeling modal/bottom sheet using standard Material components.
- Resume is primary. Restart and exit-to-levels are secondary.
- Dismiss via back, outside tap where appropriate, or explicit close.
- Save state before backgrounding.

## Completion
- Present level completion once, after all exit animations have settled.
- Show concise completion text, level number, and Next Level action.
- If the last bundled level is completed, show a clear finished-catalog state and replay options rather than a broken Next action.
- Avoid fireworks, loud celebratory effects, forced ratings, or blocking interstitials.

## Settings
- Theme selection (five options).
- Sound toggle.
- Haptics toggle.
- Reduced motion toggle, defaulting to system preference where available.
- Optional “Replay tutorial”.
- “Privacy and offline play” explanation.
- App version/build number.
- Native Play Store review action may be offered in About/Settings but must be invoked through official Play Core API and eligibility rules.

## Help/tutorial
Explain in short steps:
1. Each line belongs to an arrow.
2. The arrowhead shows its exit direction.
3. Tap an arrow only when its path to the edge is clear.
4. Blocked arrows stay in place.
5. Clear the whole board to finish.
Use diagrams rendered from actual sample level geometry, not screenshots with text baked in. Allow replay.

## Empty/error states
Handle no levels, corrupt progress, unsupported native APIs, and failed local persistence without a blank screen. Provide a retry/reset path and explain if local progress must be reset. Never erase saved progress automatically without confirmation.
