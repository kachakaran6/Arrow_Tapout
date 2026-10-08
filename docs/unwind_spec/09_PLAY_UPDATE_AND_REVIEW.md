# 09 Native Google Play in-app update and in-app review

Both features must use the native Play UI only. Do not build any custom dialog, banner, bottom sheet, snackbar, rating prompt or "rate us" row for them. They are Android-only and run only for builds installed from Google Play (they silently do nothing otherwise).

## In-app update (`in_app_update`)
`lib/platform/play_update_service.dart`, called from Home.

Flow:
1. When Home first appears in a session, and at most once per 12 hours (store last check time), call `InAppUpdate.checkForUpdate()` inside try/catch. Any exception (not from Play, offline, API not available) is swallowed.
2. If `updateAvailability == UpdateAvailability.updateAvailable`:
   - If `immediateUpdateAllowed` and the update priority is >= 4 (set per release in Play Console), call `InAppUpdate.performImmediateUpdate()`. Play shows its own full-screen native flow.
   - Else if `flexibleUpdateAllowed`, call `InAppUpdate.startFlexibleUpdate()`. Play shows its own native bottom sheet. The download then runs in the background.
3. If `updateAvailability == developerTriggeredUpdateInProgress` on launch, resume the immediate update.
4. When a flexible download finishes (`installStatus == InstallStatus.downloaded` via `checkForUpdate` on resume, or the install-status stream if the package exposes it), call `InAppUpdate.completeFlexibleUpdate()` only at a safe moment: when the user is on Home or Level select, never during a level. If the user is mid-level, defer to the next time Home appears. The Play framework applies the update by restarting the app, which is acceptable because progress is persisted (see 10).
5. Never ask the user anything in our own UI, never show our own progress indicator.
6. Rate limit: if the user dismisses the native flexible sheet, do not call again for 3 days (store the timestamp).

Notes for the implementer:
- Verify the exact API of the installed `in_app_update` version in the pub cache before coding; do not guess names.
- Wrap the service behind an interface (`UpdateService`) with a no-op implementation for tests and debug builds.
- Android manifest needs no extra permission for this API.
- Test with Play Console internal app sharing or an internal testing track: install version code N, upload N+1 to the track, open N. Document the steps in `docs/PLAY_TESTING.md`.

## In-app review (`in_app_review`)
`lib/platform/play_review_service.dart`.

Rules:
1. Never ask during a level, on Splash, on Home at cold start, after a failure, or after any mistake in the just-finished level.
2. Eligibility (all must hold): level 8 or higher completed in total, the just-finished level was completed with 2 or 3 stars, user is returning to Level select or tapping Next level (the Complete sheet has been dismissed or acted on), `await InAppReview.instance.isAvailable()` is true, and no request in the last 45 days.
3. Milestone schedule: attempt at the first eligible moment after completed-level counts 8, 30, 70 and 130, each at most once (store which milestones were attempted).
4. Call `InAppReview.instance.requestReview()`. Play decides whether to show the native bottom sheet and enforces its own quotas, so a call may display nothing. Treat it as fire and forget: do not branch on whether the sheet appeared, do not read a result, store the request timestamp regardless.
5. Do not add any custom pre-prompt ("Do you like the game?"), no star picker of our own, no Settings row that mimics rating. If the user wants to rate, Play's own sheet is the only path. Do not call `openStoreListing` from the UI.
6. Wrap in try/catch; failures are silent.
7. Never delay game flow: schedule the call with a 600 ms delay after the user lands on Level select, and cancel it if they navigate away.

## Manifest and Gradle
- minSdk 23, targetSdk current stable.
- `in_app_update` and `in_app_review` pull in Play Core / Play Review libraries via their plugins; confirm the merged release manifest with `aapt dump permissions` and make sure no `INTERNET` or other unneeded permission was added. Document the result in `docs/PERMISSIONS.md`. If a plugin adds a permission, pin or patch it and explain why.

## Acceptance
- On a Play-installed older build with a newer one on the testing track, launching Home triggers the native update sheet.
- On a Play-installed build with sufficient completed levels, the native review sheet can appear after returning to Level select; zero custom review UI exists anywhere in the codebase (grep for "rate", "review", "star prompt").
- Sideloaded or debug builds behave normally with no errors surfaced.
