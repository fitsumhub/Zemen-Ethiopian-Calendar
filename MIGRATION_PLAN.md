# EthioCal Pro – Kotlin → Flutter Migration Plan

## Overview

This document describes the phased plan to migrate **EthioCal Pro** (Android Jetpack Compose, Kotlin) to a cross-platform **Flutter** application targeting Android and iOS.

- **Source app ID:** `com.zemen.calendar`
- **Flutter package:** `com.ethiocal` (or same ID for seamless Play Store update)
- **State management:** Riverpod 2.x
- **Local DB:** Drift (SQLite wrapper, mirrors Room schema)
- **Preferences:** `shared_preferences` / `flutter_secure_storage`
- **Calendar engine:** Pure Dart port of `calendar-core`

---

## Phased Plan

### Phase 0 – Project Bootstrap (Week 1)
**Goal:** Establish the Flutter project skeleton and CI pipeline.

| Task | Owner | Notes |
|------|-------|-------|
| Create Flutter project (`flutter create`) | Dev | Package name matches Kotlin app |
| Configure `pubspec.yaml` with all dependencies | Dev | See Technical Architecture doc |
| Set up folder structure (feature-first) | Dev | See Technical Architecture doc |
| Configure Android `build.gradle` (minSdk 24) | Dev | Match Kotlin minSdk |
| Configure iOS `Podfile` / `Info.plist` | Dev | Notifications, permissions |
| Set up GitHub Actions / CI for lint + tests | Dev | flutter analyze, flutter test |
| Create flavors: dev / prod | Dev | Different package IDs |

**Exit criterion:** `flutter run` launches a blank Material3 scaffold on both platforms.

---

### Phase 1 – Calendar Engine Port (Weeks 2–3)
**Goal:** Pure Dart port of all `calendar-core` logic, fully unit-tested.

| Component | Kotlin Source | Dart Target | Notes |
|-----------|--------------|-------------|-------|
| `EthiopianDate` | `EthiopianDate.kt` | `ethiopian_date.dart` | Value class |
| `GregorianDate` | `GregorianDate.kt` | `gregorian_date.dart` | Value class |
| `EthiopianMonth` | `EthiopianMonth.kt` | `ethiopian_month.dart` | 13 months enum |
| `EthiopianDateConverter` | `EthiopianDateConverter.kt` | `ethiopian_date_converter.dart` | JDN bidirectional |
| `LeapYearCalculator` | `LeapYearCalculator.kt` | `leap_year_calculator.dart` | |
| `BahireHasab` | `BahireHasab.kt` | `bahire_hasab.dart` | Full Orthodox Computus |
| `GeezNumeral` | `GeezNumeral.kt` | `geez_numeral.dart` | Arabic↔Geez |
| `EthiopianTimeConverter` | `EthiopianTimeConverter.kt` | `ethiopian_time_converter.dart` | Traditional 12-hr |
| `EthiopianSeason` | `EthiopianSeason.kt` | `ethiopian_season.dart` | 4 seasons |

**Exit criterion:** ≥95% unit-test coverage, all JDN round-trip tests pass.

---

### Phase 2 – Data Layer (Week 4)
**Goal:** Drift database + SharedPreferences/AppSettings provider.

| Task | Notes |
|------|-------|
| Define Drift `EventTable` mirroring `EventEntity` | Same columns, types |
| Implement Drift DAO (`EventDao`) with CRUD + search/filter | Match Room queries |
| Implement `AppSettingsRepository` using `shared_preferences` | All 10 DataStore keys |
| Riverpod providers for DB + settings | `eventRepositoryProvider`, `settingsProvider` |
| Data migration strategy (export/import from Kotlin Room DB) | SQLite file copy on first launch |

**Exit criterion:** Events can be created, read, updated, and deleted; settings persist across restarts.

---

### Phase 3 – Holidays & Fasting Engine (Week 5)
**Goal:** Port all holiday, fasting, and saints data and logic.

| Task | Notes |
|------|-------|
| Port 30 monthly saints data | Dart `List<Saint>` |
| Port fixed Orthodox holidays (Enkutatash, Meskel, Genna, Timket, …) | Data-driven |
| Port movable Orthodox feasts via `BahireHasab` | Nenewe, Fasika, Erget, Paraclete, … |
| Port Islamic holidays | Lunar calculation or data table |
| Port national public + cultural holidays | Data table |
| `FastingStatus` per-day calculation | Dart enum + logic |
| `HolidayRepository` Riverpod provider | |

**Exit criterion:** All holidays for years 2015–2025 EC match Kotlin output.

---

### Phase 4 – Core UI Shell & Navigation (Week 6)
**Goal:** Bottom navigation, theming, and onboarding.

| Task | Notes |
|------|-------|
| `AppTheme` – Material3, 4 accent palettes, Light/Dark/AMOLED | Match Kotlin colors |
| `AppRouter` (go_router) – 6 tabs + onboarding route | |
| `OnboardingScreen` | 3-step walkthrough |
| `AppScaffold` with `NavigationBar` (6 tabs) | |
| `DailyHeritageEngine` – 30 proverbs | Day-of-year selection |
| Localization scaffolding (English + Amharic) | `flutter_localizations` + ARB |

**Exit criterion:** 6-tab navigation works; theme switches live; onboarding shows on first run.

---

### Phase 5 – Feature Screens (Weeks 7–10)
Implement each of the 6 main feature screens. Work can be parallelised across developers.

| Screen | Target Week |
|--------|------------|
| Home | 7 |
| Calendar | 7–8 |
| Converter | 8–9 |
| Holidays | 9 |
| Events (CRUD) | 9–10 |
| Settings | 10 |

**Exit criterion:** All screens are interactive and match Kotlin UX parity.

---

### Phase 6 – Notifications & Background Tasks (Week 11)
**Goal:** Event reminder notifications and boot-rescheduling.

| Task | Notes |
|------|-------|
| `flutter_local_notifications` integration | Exact-time alarms |
| `NotificationScheduler` service | Mirrors `AlarmManager` logic |
| Boot reschedule via `WorkManager` / background fetch | Android + iOS |
| Permissions: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM` | Runtime request |

**Exit criterion:** Reminders fire at correct times; reboot reschedule works on Android.

---

### Phase 7 – Home Screen Widgets & ICS Export (Week 12)
**Goal:** Android home screen widgets and calendar export.

| Task | Notes |
|------|-------|
| Android widget (full + compact) via `home_widget` package | Kotlin glue still required |
| ICS calendar export / `READ_CALENDAR` / `WRITE_CALENDAR` | `add_2_calendar` or manual ICS |
| iOS widget (WidgetKit, via native extension) | Optional / post-launch |

**Exit criterion:** Widgets display today's date and upcoming event on Android.

---

### Phase 8 – Firebase AI & Remote Features (Week 13)
**Goal:** Port Firebase AI integration.

| Task | Notes |
|------|-------|
| `firebase_core` + `firebase_ai` Flutter SDK | Match Kotlin `com.google.firebase:firebase-ai` |
| Greeting card studio AI generation | Use Gemini API via Flutter SDK |
| Retrofit → Dio HTTP client | For any remote API calls |
| Moshi → `freezed` + `json_serializable` | DTO models |

**Exit criterion:** Greeting card generation works end-to-end in Flutter.

---

### Phase 9 – QA, Polish & Release (Weeks 14–15)
| Task | Notes |
|------|-------|
| Integration tests (`integration_test`) | Full happy-path coverage |
| Accessibility audit (semantics labels) | |
| Performance profiling (DevTools) | Jank budget < 16 ms |
| RTL layout check (Amharic) | |
| Play Store / App Store submission | |
| Phased rollout (10% → 50% → 100%) | |

---

## Timeline Summary

| Phase | Weeks | Deliverable |
|-------|-------|-------------|
| 0 – Bootstrap | 1 | Runnable skeleton |
| 1 – Calendar Engine | 2–3 | Pure Dart core, tested |
| 2 – Data Layer | 4 | Drift DB + settings |
| 3 – Holidays & Fasting | 5 | All holiday logic |
| 4 – UI Shell | 6 | Nav + theming |
| 5 – Feature Screens | 7–10 | All 6 screens |
| 6 – Notifications | 11 | Reminders working |
| 7 – Widgets & ICS | 12 | Android widgets |
| 8 – Firebase AI | 13 | AI features |
| 9 – QA & Release | 14–15 | Store submission |
| **Total** | **~15 weeks** | **Full parity + cross-platform** |

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| BahireHasab computus bugs | Medium | High | Port unit tests verbatim from Kotlin |
| Android exact-alarm permission changes (API 33+) | High | Medium | Use `USE_EXACT_ALARM` where available; fall back to inexact |
| iOS notification restrictions | Medium | Medium | Use `flutter_local_notifications` with proper entitlements |
| Home screen widgets on iOS | High | Low | Defer to post-launch WidgetKit native extension |
| Firebase AI SDK differences | Low | Medium | Confirm Flutter SDK feature parity before Phase 8 |
| Room SQLite migration for existing users | Medium | High | Detect existing DB on first Flutter launch; copy + migrate |
| Geez font rendering on iOS | Low | Medium | Bundle Noto Serif Ethiopic; test on physical device |
| App size increase (Flutter engine) | Low | Low | Enable tree-shaking; use deferred components |

---

## Dependencies (Flutter Packages)

```yaml
# Core
flutter_riverpod: ^2.5.1
go_router: ^13.0.0
drift: ^2.18.0
shared_preferences: ^2.2.3
freezed_annotation: ^2.4.1
json_annotation: ^4.9.0

# UI
flutter_localizations: sdk: flutter
google_fonts: ^6.2.1

# Firebase
firebase_core: ^3.x
firebase_ai: ^1.x          # or google_generative_ai

# Notifications
flutter_local_notifications: ^17.x
permission_handler: ^11.x

# Networking
dio: ^5.4.3

# Widgets & Calendar
home_widget: ^0.5.0
add_2_calendar: ^3.0.1

# Dev
build_runner: ^2.4.9
drift_dev: ^2.18.0
freezed: ^2.5.2
json_serializable: ^6.8.0
flutter_test: sdk: flutter
integration_test: sdk: flutter
```
