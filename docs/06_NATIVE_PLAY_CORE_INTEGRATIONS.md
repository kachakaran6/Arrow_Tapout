# Native Google Play Core Integrations

## Scope and truthfulness
Use official Google Play in-app update and in-app review APIs through a maintained Flutter plugin or a small native Android platform-channel implementation. Verify plugin maintenance, supported Android/Flutter versions, Play distribution requirements, and current Play policy before choosing. Keep the game playable if these APIs are unavailable.

Do not build a custom bottom sheet that imitates Google's review or update interface. The app may show its own neutral explanation or settings row, but the actual review prompt/update UI must be system/Play-provided.

## In-app updates
- Check availability at sensible moments, such as app launch or return to Home, not during a puzzle.
- Use flexible update flow when appropriate and supported; use immediate update only for a justified critical release.
- Follow Play Core state callbacks, including download progress/completion and restart requirements.
- Handle unavailable, already-current, developer-triggered update, user cancellation, failure, and non-Play-installed builds.
- Never trap the player in a forced update loop.
- Do not assume a local APK/debug install can exercise production update behavior.
- Document internal testing requirements and how to verify the flow using Play internal testing tracks.

## In-app review
- Invoke only at a natural positive moment, such as after several completed levels, with a cooldown and local attempt bookkeeping.
- The API is quota-limited and may decide not to display UI. Do not promise the prompt will appear.
- Do not ask for a positive rating or gate features behind a review.
- If the review API does not show a prompt, continue normally. Do not automatically open a fake review dialog.
- If providing a separate “Rate this app” action, use the official Play Store listing URL only when the app is installed/distributed in a context where it is valid. If the Play Store is unavailable, fail gracefully.
- Keep the review trigger behind an interface so the core game remains fully offline and testable.

## Native architecture
Define interfaces such as:
- `UpdateService.checkAndStartUpdateIfAvailable()`
- `ReviewService.requestReviewAtEligibleMoment()`
Implement no-op/fallback implementations for unsupported platforms and tests. The game domain must never depend on Play Core classes.

## Verification
Test service interface behavior with fakes. Validate actual native flows on a Play-distributed internal-test build. Clearly distinguish simulated unit tests from real Play Console/device verification in the final report.
