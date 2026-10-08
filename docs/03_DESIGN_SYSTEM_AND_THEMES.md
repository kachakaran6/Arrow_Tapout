# Design System and Five Themes

## Principles
Quiet, crafted, tactile, premium. Flat surfaces, fine strokes, generous spacing, restrained contrast, consistent type hierarchy. No neon, glow, heavy gradients, glassmorphism, emoji, random color generation, or mixed component libraries. Do not make the UI look like a generic AI-generated dashboard.

## Theme options
Offer exactly these five named palettes at launch. Names are text labels, not badges. Provide a small visual preview and persist the selected theme locally.

### 1. Warm Paper — default
- primary: `#A44F35`
- primaryPressed: `#87402C`
- background: `#F4E8D4`
- surface: `#FBF4E8`
- surfaceAlt: `#EDE0CA`
- text: `#4F382B`
- textMuted: `#8C7765`
- border: `#D8C5AA`
- boardLine: `#604633`
- boardDot: `#E5D5BD`
- success: `#58745E`
- error: `#9B5144`

### 2. Mist Blue
- primary: `#477FA6`
- primaryPressed: `#356786`
- background: `#EAF0F3`
- surface: `#F7FAFB`
- surfaceAlt: `#DDE7EC`
- text: `#293D49`
- textMuted: `#71838C`
- border: `#C8D5DC`
- boardLine: `#425B68`
- boardDot: `#D7E2E7`
- success: `#55796B`
- error: `#9A5A55`

### 3. Sage Studio
- primary: `#667D63`
- primaryPressed: `#50644E`
- background: `#EDF0E5`
- surface: `#F8F9F3`
- surfaceAlt: `#E0E6D6`
- text: `#354638`
- textMuted: `#7B8979`
- border: `#CDD6C5`
- boardLine: `#4B5D49`
- boardDot: `#DCE3D3`
- success: `#4F765C`
- error: `#965D53`

### 4. Stone & Ink
- primary: `#6D6A64`
- primaryPressed: `#55534E`
- background: `#ECEAE5`
- surface: `#F8F7F3`
- surfaceAlt: `#DFDDD6`
- text: `#343632`
- textMuted: `#7B7C75`
- border: `#CFCEC6`
- boardLine: `#454741`
- boardDot: `#DCDAD2`
- success: `#5D765D`
- error: `#96584F`

### 5. Plum Dusk
- primary: `#88677E`
- primaryPressed: `#6D5064`
- background: `#F0E8EE`
- surface: `#FAF5F9`
- surfaceAlt: `#E5D9E3`
- text: `#493744`
- textMuted: `#887888`
- border: `#D8C7D5`
- boardLine: `#5D4659`
- boardDot: `#E3D5E1`
- success: `#597566`
- error: `#9B5A5A`

## Dark mode
Release one may support system/light/dark if the design can be executed consistently. Do not simply invert colors. Define deliberate dark tokens for every palette. If the team cannot test all palette/mode combinations adequately, ship light themes first and keep the architecture ready for dark mode rather than shipping broken dark colors.

Suggested Warm Paper dark baseline:
- background `#171715`
- surface `#22211E`
- surfaceAlt `#2B2924`
- text `#F1E9DC`
- textMuted `#B5A99A`
- border `#484239`
- primary `#D18A6E`
- boardLine `#D8C5AA`
- boardDot `#34312B`

## Token architecture
Create one immutable `AppTokens`/`GameThemeTokens` model and a single theme controller. Components must consume semantic tokens, never hard-coded hex values outside the theme definitions. Define:
- color roles
- spacing scale: 4, 8, 12, 16, 20, 24, 32, 40
- radii: 8, 12, 16, 24, and pill only where appropriate
- stroke widths: 1, 1.5, 2, 2.5 logical px for hierarchy
- typography: display, title, body, label, caption
- motion durations and curves
- board geometry/tap target rules
- shadows: none or extremely subtle; avoid floating-card overload
- icon size scale: 16, 20, 24
- minimum touch target: 48 logical px where practical

## Type
Use a clean system sans-serif or one locally bundled licensed family. Keep titles compact and confident. Use sentence case, not all caps. Ensure font fallback and dynamic text scaling work. Avoid decorative display fonts that reduce readability.

## Board rendering
- Draw paths and arrowheads as vector lines with rounded joins/caps.
- Keep board line color separate from text color.
- Dot texture is optional and extremely low contrast; render efficiently and disable it in low-power/reduced-motion contexts.
- Arrow hit testing must use geometry and an enlarged invisible hit corridor, without visually thickening the path.
- Maintain consistent stroke width across screen sizes, with carefully capped scaling.
- Board must remain visually centered and legible across portrait phone sizes and tablets.
