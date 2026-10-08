# Product Requirements

## Product summary
A minimal, premium, offline-first arrow-removal puzzle. Levels are played in order and gradually increase in complexity. The reference images communicate the visual style and path-art direction, not a fixed board size or final content.

## Core loop
1. Open the next unlocked level.
2. Inspect the direction of each arrow.
3. Tap an arrow whose exit lane is unobstructed.
4. Watch it travel out of the board.
5. Repeat until the board is empty.
6. See a restrained completion state and continue to the next level.

## Rules
- The arrow's tip indicates the exit direction.
- A clear ray to the board edge allows removal.
- Any active arrow geometry intersecting the exit ray blocks that move.
- A blocked arrow remains on the board.
- No timer is required for the core experience. Avoid artificial urgency.
- The player may restart at any time.
- Level completion is based on removing all arrows, not on a score threshold.
- Level order is sequential. Future levels remain locked until the prior level is completed.
- Optional stars or move-efficiency ratings must never block progression and should be omitted from the first release unless fully designed and tested.

## Release-one feature scope
- Home screen with Continue, level selection/progress, settings, and help.
- Gameplay screen.
- Level completion sheet/screen.
- Level map or paginated level selection grouped into chapters.
- Theme selection: five palettes.
- Sound and haptics toggles.
- Reduced motion option, plus system accessibility preference support.
- Restart confirmation only when progress would be lost; otherwise restart directly if that is clearer.
- Pause overlay or bottom sheet.
- Local privacy/about screen.
- Native Google Play in-app update and review prompts, invoked sparingly and only through official APIs.
- Fully offline game content and persistence.

## Not in release one
- Accounts, cloud sync, online leaderboard, multiplayer, ads, analytics, remote level delivery, user-generated public levels, subscriptions, energy systems, lives, or forced daily rewards.
- A custom imitation of Android system review/update dialogs.
- Permission requests unrelated to gameplay.

## UX principles
- Calm, direct, low-clutter screens.
- One obvious primary action per screen.
- The board owns visual focus.
- Avoid excessive badges, counters, and gamification.
- Explain rules through a concise first-run tutorial that can be replayed.
- Never punish a blocked tap with a dialog.
- Make settings immediately persistent.
- Preserve progress across app restarts and process death.
