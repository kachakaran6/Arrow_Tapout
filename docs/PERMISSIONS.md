# Permissions Audit

## Release Manifest Permissions
The Unwind application operates 100% offline.

### Declared Permissions
- None. `android.permission.INTERNET` is strictly prohibited and absent from `AndroidManifest.xml`.
- Zero runtime dangerous permissions requested.

### Plugin Verification
- `in_app_update`: Integrates with Google Play Core client library locally without injecting extra permissions into the merged manifest.
- `in_app_review`: Uses Play Review client library via local IPC without internet permissions.
- `shared_preferences`: Local device private storage only.
- `audioplayers`: Plays local asset audio files without microphone or network access.
