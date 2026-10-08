# Offline Architecture and Persistence

## Offline contract
All puzzle gameplay and progression must work in airplane mode after installation. Do not ship a dependency on remote APIs, remote fonts, remote images, sign-in, analytics, crash reporting that uploads data, ads, or cloud storage. Native Play Store update/review actions are optional platform services and are not part of the offline gameplay guarantee.

## Suggested structure
```text
lib/
  app/
    app.dart
    router.dart
    theme/
      app_tokens.dart
      theme_controller.dart
  core/
    accessibility/
    audio/
    persistence/
    platform/
    widgets/
  features/
    home/
    levels/
    game/
      domain/
      data/
      presentation/
    settings/
    help/
    about/
  main.dart
assets/
  levels/
  audio/
  fonts/
test/
integration_test/
docs/
```

## State ownership
- Domain engine owns rules and runtime board state.
- Level repository owns bundled level definitions and validation.
- Progress repository owns unlocks, completions, best stats, and last played level.
- Settings repository owns theme, sound, haptics, reduced motion.
- Presentation state owns transient animation and sheet visibility.
- Native store service owns Play Core calls behind an interface.

## Local storage
Choose a reliable local store based on expected scale. Preferences can use a key-value store; progress can use SQLite/Drift/Isar/Hive or a similarly suitable local database. Do not introduce multiple persistence systems without a reason. Document schema versioning and migration. Store atomically where possible.

Persist:
- completed level IDs
- highest unlocked level/chapter
- last played level
- optional move counts and completion time if tracked
- theme ID
- sound/haptics/reduced-motion settings
- tutorial completion state

Never persist a partially animated pixel offset as game truth. Persist stable engine state and restore pending moves deterministically. Write after committed moves and completion. Debounce only non-critical preference writes.

## Data and privacy
- No account or personal profile.
- No collection or transmission of gameplay behavior.
- No advertising identifier.
- No analytics events.
- No remote telemetry.
- Provide a plain-language privacy screen that accurately says gameplay progress/settings are stored locally.
- Do not promise that Google Play in-app update/review interactions are offline or that Play services never process anything; describe those as optional Google Play features.

## Reliability
- Handle storage read/write exceptions.
- If saved progress is invalid, attempt a safe migration/recovery. Do not silently wipe.
- Use a schema version.
- Test cold launch, force-stop during animation, process death, app upgrade, and repeated completion callbacks.
- Ensure app resume does not trigger duplicate animation or duplicate level completion.
