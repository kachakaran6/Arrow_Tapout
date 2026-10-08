# Level Content Plan

## Launch catalog
Target at least 60 validated levels across six chapters of ten levels. Every level is local and solvable without network access. Prioritize handcrafted quality over algorithmic filler.

## Difficulty progression
- Chapter 1 — Learn the language (1–10): sparse layouts, obvious exits, introduce one interaction at a time.
- Chapter 2 — Plan ahead (11–20): moderate crossings and blockers, teach removal order.
- Chapter 3 — Read the shape (21–30): denser arrangements, varied board silhouettes.
- Chapter 4 — Nested routes (31–40): more turns, longer paths, stronger dependency chains.
- Chapter 5 — Precision (41–50): denser but still legible geometry, require deliberate order.
- Chapter 6 — Mastery (51–60): complex but fair boards, multiple valid solution orders where practical.

## Design standards
- Each level should have a recognizable silhouette or composition, not just a rectangular mass of random lines.
- Vary density, negative space, path length, and board shape.
- Preserve generous tap corridors, especially on small phones.
- Do not create visually ambiguous overlaps.
- Make the intended exit direction obvious with a consistent arrowhead.
- Every level must have at least one valid first move.
- Avoid requiring pixel-perfect tapping.
- Difficulty should come from reasoning about blockers, not tiny lines or confusing visuals.
- Avoid repeating the same generated template with minor coordinate changes.
- Include levels inspired by abstract silhouettes (e.g., geometric forms, simple objects) only if they remain clear and do not use emoji or copyrighted character shapes.
- Treat the supplied screenshots as inspiration for arrow density and visual language, not as level assets.

## Authoring workflow
1. Create a candidate level using integer-grid polylines.
2. Run schema and geometry validation.
3. Run deterministic solvability solver.
4. Preview at target phone sizes and five themes.
5. Check hit targets and visual density.
6. Play-test with a human.
7. Record solution metadata in development-only data.
8. Include it in bundled catalog only after validation.

## Content quality metrics
Track in development tooling:
- number of arrows
- path segment count
- number of valid first moves
- minimum path separation
- solution depth / number of moves
- board occupancy and silhouette
- approximate tap corridor width at smallest supported viewport
- play-test notes

Do not expose internal solver metadata to players by default.
