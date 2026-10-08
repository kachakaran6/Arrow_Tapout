# 05 Design tokens and themes

## Token architecture
Three layers, in `lib/design/`:
1. **Primitives** (`primitives.dart`): raw values only, never used directly by widgets. Palette hex values, a 4pt spacing scale, radius scale, duration scale, curve set.
2. **Semantic tokens** (`app_tokens.dart`): a `ThemeExtension<AppTokens>` with colour roles, plus static non-colour tokens. Widgets read `context.tokens`.
3. **Component tokens** (`component_tokens.dart`): derived values for board, thread, sheet, button, chip. Built from semantic tokens.

`AppTokens` implements `copyWith` and `lerp` so switching theme animates (280 ms, easeInOutCubic) via `AnimatedTheme` or a `TweenAnimationBuilder<AppTokens>`.

### Colour roles
`bg` page, `surface` panels and sheets, `surfaceRaised` cards and buttons, `ink` primary text and thread colour, `inkMuted` secondary text, `inkFaint` disabled, `thread` default thread stroke (equals ink by default), `threadFaint` hairlines and dividers, `accent` the single brand colour, `onAccent`, `danger` blocked-flash colour, `success` completion tick, `scrim` modal barrier (ink at 40 percent), `boardEdge` optional board outline.
Rule: one accent per theme. Danger is used only for the blocked pulse and destructive confirms.

### Non-colour tokens
- Spacing: 4, 8, 12, 16, 20, 24, 32, 40, 56.
- Radius: 8 (chips), 14 (buttons, cards), 22 (sheets top corners).
- Stroke: thread stroke = `cell * 0.11` clamped to [2.0, 3.2] dp; arrowhead arm length = `cell * 0.34`.
- Durations: `instant 90`, `fast 160`, `base 240`, `slow 360`, `page 280`, `exitMin 320`, `exitMax 900` ms.
- Curves: `standard = Curves.easeInOutCubic`, `enter = Cubic(0.16, 1, 0.3, 1)`, `exitIn = Cubic(0.5, 0, 0.9, 0.5)`, `spring` for bounce-back via `SpringSimulation(mass 1, stiffness 420, damping 26)`.
- Elevation: avoid shadows. Separate layers by tone, not blur. If a shadow is needed: one soft layer, blur 24, y 8, ink at 8 percent.
- Typography (bundled fonts, no google_fonts fetching): **Newsreader** (serif, display: level numbers, titles) and **Manrope** (UI). Scale: display 40/44 w500 Newsreader, title 24/30 w500 Newsreader, heading 18/24 w700 Manrope, body 15/22 w500, label 13/16 w700 with +0.2 tracking, caption 12/16 w500. Tabular figures for numbers. Respect system text scale up to 1.3 then clamp.

## The five themes
All light themes sit on warm or cool paper tones, never pure white. All dark themes sit on tinted charcoal, never pure black. No gradients on surfaces or buttons. Hex values below are the starting point; adjust by at most a few points only to hit contrast targets.

| Role | 1. Sage Linen (light) | 2. Ink and Brass (dark) | 3. Fog Slate (light) | 4. Rosewood (light) | 5. Graphite Ember (dark) |
|---|---|---|---|---|---|
| bg | #ECEEE4 | #14161A | #E8ECEE | #F1E6E0 | #1A1816 |
| surface | #F5F6EF | #1B1E23 | #F2F5F6 | #F8F0EB | #221F1C |
| surfaceRaised | #FAFBF6 | #23272D | #FBFCFC | #FCF8F5 | #2B2723 |
| ink / thread | #25302A | #ECE6D8 | #22303A | #3A2626 | #E9E2D6 |
| inkMuted | #5D6757 | #9A9484 | #586873 | #7C6460 | #A0978A |
| threadFaint | #C9CEBF | #343840 | #C4CED4 | #D9C5BD | #3A3530 |
| accent | #55774E | #C7A15A | #3F6E85 | #8A3F55 | #D17B4A |
| onAccent | #F5F6EF | #14161A | #F2F5F6 | #F8F0EB | #1A1816 |
| danger | #B0503F | #D0705A | #B5513F | #A86A14 | #D95C4E |
| success | #5C7F55 | #8FA874 | #4C7F6A | #6E8A52 | #8FA874 |

Default: Sage Linen in light mode, Ink and Brass in dark mode. Settings offers "Follow system" (default) plus each of the five explicitly. The picker shows five tiles, each a small live-rendered mini board in that theme with real threads, plus the theme name. Selected tile has a 2dp accent outline and a check glyph drawn with CustomPainter (no emoji, no icon-font surprise).

## Contrast and quality gates (enforced by a test)
- `ink` on `bg` and on `surface`: at least 7:1.
- `inkMuted` on `bg`: at least 4.5:1.
- `accent` on `bg`: at least 3:1 (it is used for strokes and large text only). `onAccent` on `accent`: at least 4.5:1.
- `danger` on `bg`: at least 3:1.
- Write `test/theme_contrast_test.dart` computing WCAG contrast for every theme and role pair above and failing under the limits.

## Anti "AI look" rules (must follow)
- No purple, indigo-to-pink, teal-to-blue or neon gradients. No gradient buttons, no gradient text, no glassmorphism, no glowing outlines, no sparkle particles.
- No emoji, no stock icon sets with cartoonish style. Use a small set of custom-painted glyphs or thin outline icons (Material Symbols Rounded at weight 300, optical size 24) used consistently.
- One accent colour per screen. Large calm areas of background. Generous margins (min 20 dp page padding).
- Hairline separators in `threadFaint` rather than boxes around everything.
- Buttons: solid fill or 1.5 dp outline, radius 14, label 13/16 bold. No bouncing icons, no confetti.
- Motion is purposeful: slides, fades and small springs only.
- Copy is plain and specific, never breathless.
- Icon, splash and feature graphic derive from the thread motif: a single line exiting a square. No letter-in-circle placeholder.
