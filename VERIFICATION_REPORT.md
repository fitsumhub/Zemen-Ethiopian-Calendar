# EthioCal Pro – Feature Verification Report

> Kotlin source of truth: `app/` + `calendar-core/`  
> Flutter implementation: `lib/`

## Executive verdict

The Kotlin EthioCal Pro app has been migrated into a runnable Flutter application with matching package identity, calendar engine parity tests, full main navigation/screens, persistence, and release Android artifacts. Documented gaps remain for home-screen widgets, Firebase AI card generation, legacy Room DB import, and device screenshot parity.

## Automated results

| Check | Result |
|-------|--------|
| `dart analyze lib` | **0 errors** |
| `flutter test` | **22/22 passed** |
| Release APK | `build/app/outputs/flutter-apk/app-release.apk` (**54.3 MB**) |
| Release AAB | `build/app/outputs/bundle/release/app-release.aab` (**52.7 MB**) |

## Android identity parity

| Field | Kotlin | Flutter |
|-------|--------|---------|
| applicationId | `com.zemen.calendar` | `com.zemen.calendar` |
| label | EthioCal Pro | EthioCal Pro |
| minSdk | 24 | 24 |
| targetSdk | 36 | 37 (plugin requirement) |
| Permissions | boot, notifications, exact alarm, vibrate, wake lock, calendar R/W | same (+ INTERNET) |

## Screen / feature matrix

| Area | Status |
|------|--------|
| Onboarding (3 pages) | Migrated |
| Home (date hero, clock, holiday, actions, events, heritage) | Migrated |
| Calendar Month/Week/Day/Year | Migrated |
| Converter (date/time/age/Bahire Hasab/Ge'ez/world) | Migrated |
| Holidays (annual/fasting/saints/greeting studio UI) | Migrated |
| Events CRUD + ICS share | Migrated |
| Settings (language, numerals, theme, accents, toggles) | Migrated |
| Local notifications scheduler | Migrated (device permission validation recommended) |
| Home widgets (full/compact) | **Pending native port** |
| Firebase AI greeting generation | **Pending** |
| Room → sqflite existing-user import | **Pending** |
| Pixel screenshot comparison | **Pending device captures** — see `SCREENSHOT_COMPARISON_REPORT.md` |

## Calendar engine validation

Covered by `test/calendar_core_test.dart`, `test/bahire_hasab_test.dart`, `test/engines_test.dart`:

- Ethiopian leap-year / Evangelist cycle
- Known Eth↔Greg conversions + multi-year JDN round trips
- Pagume day counts
- Bahire Hasab movable feasts
- Ge'ez numerals + Ethiopian time
- Holidays / fasting / world clock engines

Algorithm is a direct Dart port of Kotlin `calendar-core` (epoch JDN `1724221`), not a third-party calendar package.

## Acceptance criteria

| Criterion | Met? |
|-----------|------|
| Every original primary screen exists | **Yes** |
| Core calendar/features work under automated tests | **Yes** |
| UI differences documented | **Yes** |
| Calendar comparison tests pass | **Yes** |
| Preferences persistence | **Yes** (SharedPreferences) |
| No critical crashes in automated suite | **Yes** |
| Flutter analysis 0 errors | **Yes** |
| Automated tests pass | **Yes** |
| Release APK + AAB build | **Yes** |
| 100% including widgets/Firebase AI/screenshots | **No — gaps listed above** |

## Install on connected device

```bash
flutter install --release
# or
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
