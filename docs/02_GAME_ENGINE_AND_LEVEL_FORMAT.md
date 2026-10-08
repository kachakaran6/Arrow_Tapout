# Game Engine and Level Format

## Engine boundaries
The domain engine must be pure Dart and must not import Flutter. Use immutable level definitions and explicit runtime state. UI code requests a move; engine code returns a typed result.

Suggested types:
- `LevelDefinition`
- `ArrowDefinition`
- `GridPoint`
- `Direction` (`up`, `right`, `down`, `left`)
- `GameState`
- `ArrowState` (`active`, `pendingExit`, `removed`)
- `MoveResult` (`removed`, `blocked`, `alreadyExiting`, `notFound`, `levelComplete`)
- `LevelValidator`

## Geometry
Use integer grid coordinates for authoring. Render using a uniform transform into the available board rectangle. Store each arrow as an orthogonal polyline plus an explicit arrow-tip point and exit direction. Do not infer direction from the last segment if a level could be ambiguous.

Recommended conceptual schema:
```json
{
  "schemaVersion": 1,
  "id": "chapter_01_level_001",
  "chapter": 1,
  "levelNumber": 1,
  "grid": { "columns": 12, "rows": 16 },
  "arrows": [
    {
      "id": "a01",
      "points": [[2, 3], [2, 6], [5, 6]],
      "tip": [5, 6],
      "direction": "right"
    }
  ],
  "parMoves": 8,
  "difficulty": "intro"
}
```
This is an example shape, not a valid level unless its geometry passes all validators. Use a documented coordinate convention: origin at top-left, x increases right, y increases down. All paths must be orthogonal, in bounds, non-zero length, and free of self-intersection unless self-intersection is explicitly supported and proven unambiguous.

## Collision semantics
Document and test the chosen geometry model before authoring large amounts of content. Recommended rule: an arrow exits from its designated tip in its explicit direction. The open ray from tip toward and through the board boundary is blocked if it intersects any segment of another active arrow. Exclude the moving arrow itself. Define whether touching a segment endpoint or sharing a grid vertex counts as collision; default to collision for predictable gameplay. Do not let the arrow's own path block its ray.

Important: decide whether arrows can point from interior segments or must point outward from a terminal endpoint. Prefer terminal tip at the endpoint of the polyline and require the first exit ray to continue collinearly from the last segment when practical. If references require a different construction, document it and test it.

## Move lifecycle
1. Hit testing resolves an arrow ID from the painted geometry, with deterministic priority when paths are close.
2. Engine evaluates the move.
3. If blocked, return blocker information for feedback; do not mutate active state.
4. If clear, transition to `pendingExit` and reserve the move so repeated taps cannot start duplicate animations.
5. Presentation animates the arrow out.
6. Animation completion commits `removed` in engine state and persists progress.
7. Evaluate level completion exactly once.
8. On interruption/resume, normalize pending exits safely: either finish their removal or restore them as active. Pick one deterministic policy and test it.

## Level validation
Reject any level that has:
- Duplicate IDs.
- Invalid grid size or coordinates outside the grid.
- Diagonal segments.
- Zero-length segments.
- Invalid direction or tip not at a valid path endpoint.
- Self-intersections or overlaps if unsupported.
- Duplicate/overlapping geometry between arrows if unsupported.
- Unsolvable deadlock under the intended rules.
- Incorrect solution metadata.
- Excessive visual density or too-small tap targets at the target display size.

## Solvability
Create a deterministic solver/validator. A simple elimination solver repeatedly removes any arrow with a clear exit ray. If no arrow can be removed while arrows remain, the level is deadlocked. For small levels, optionally run a search to validate solvability under the full state space. Store a known valid solution order in development metadata if helpful, but never show it to the player by default.

## Bundled content
- Bundle all release-one levels locally.
- Validate every level in automated tests.
- Do not depend on a remote catalog.
- Version level schema and migration logic.
- A malformed level must fail safely with a friendly error and a way to return to level selection; it must not crash the app.

## Testing
Test clear and blocked rays in all four directions, edge and corner cases, endpoint-touch behavior, removed arrows no longer blocking, self-exclusion, double taps, simultaneous animations, restart, app interruption, exact completion, and unsolvable levels.
