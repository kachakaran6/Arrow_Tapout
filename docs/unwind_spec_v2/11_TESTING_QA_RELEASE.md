# 11 Testing, QA and release

## Automated tests
| Area | Tests |
|---|---|
| Engine | ray generation for all four directions and edges; occupancy; canExit; firstBlocker distance; solver solved/unsolvable/depth; validity rules (self-ray, overlap, length) |
| Levels | every asset parses; every level valid and solvable; coverage and initial-free targets hold; ids contiguous 1..200 |
| Controller | free tap removes and counts; blocked tap counts one mistake (debounced); tutorial has no failures; third mistake fails; hint picks the most freeing thread; snapshot round trip |
| Hit tester | nearest-thread selection, tolerance edges, parallel adjacent threads, zoomed transforms, drag-then-release is not a tap |
| Persistence | defaults on corrupt data; schema migration; debounce flush on pause |
| Theme | contrast gates from 05 for all five themes; lerp endpoints equal inputs |
| Navigation | locked level redirect; unknown route to home; back on game opens pause; next level uses replacement |
| Play services | services are no-ops on exception; review eligibility logic (levels, stars, 45 day gap, milestones) with a fake clock |
| Golden | board painter in each theme at three sizes; theme picker tile; Complete sheet |
| Integration | auto-play all 200 levels via solver taps without mistakes; kill and resume snapshot |

CI script `tool/check_all.sh`: `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`, `dart run tool/generate_levels.dart --verify`, `tool/check_offline.sh`.

## Manual QA checklist (device)
- Smooth exit on a low-end Android (2 GB RAM) and a 120 Hz device, no jank in profile mode.
- Rapid tapping many threads in a row; tapping during blocked animations; tapping while pinch-zooming.
- Rotate device (locked portrait), split screen, font scale 1.3, display size large, dark mode switch mid-level.
- Airplane mode for a full session; background for 30 minutes then resume; force stop mid-level.
- TalkBack: all controls reachable and labelled; board announces threads left.
- All 5 themes on every screen, check no hard-coded colour appears (grep for `Color(0x` outside design/).
- Reduce motion on: no sliding or stagger, still clear feedback.
- Play update and review flows per 09 on an internal testing track.

## Performance and size
- Profile-mode frame times recorded in `docs/PERF.md` for the largest board.
- Release app bundle under 20 MB. Cold start under 1 s on a mid-range device.
- R8 and resource shrinking on. No debug banners or logs in release.

## Release checklist
- [ ] Original app name, applicationId, icon (adaptive plus monochrome themed icon), splash, feature graphic, screenshots in at least two themes
- [ ] Version name and code set, `versionCode` increments tracked in `docs/RELEASE.md`
- [ ] Upload keystore created and backed up outside the repo, `key.properties` gitignored
- [ ] `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols`
- [ ] Merged release manifest reviewed: only intended permissions, `allowBackup` decided, portrait orientation, predictive back flag
- [ ] Data safety form in Play Console: no data collected, no data shared
- [ ] Content rating questionnaire, target audience (all ages, not designed for children unless COPPA reviewed)
- [ ] Privacy policy URL ready even though nothing is collected (Play requires one for most listings)
- [ ] Licences screen lists fonts and packages
- [ ] Internal test, then closed test (20 testers for 14 days where the account type requires it), then production
- [ ] Update priority set on first update release to verify the update flow
