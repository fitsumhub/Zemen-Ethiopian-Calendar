# EthioCal Pro — Architecture Analysis & Technical Blueprint

**Document Version:** 1.0.0  
**Date:** November 2026  
**Architect:** Senior Flutter Architect & Mobile Systems Engineer  
**Target Architecture:** Clean Architecture + Feature-First (Flutter / Dart)

---

## 1. Architectural Philosophy & Principles

The architectural design of **EthioCal Pro** adheres to four core engineering standards:
1. **Clean Architecture Separation of Concerns:** Domain mathematics, business rules, persistence, and UI rendering are decoupled into strict, one-way dependency layers.
2. **Feature-First Modularity:** Code is grouped by bounded business domains (`calendar`, `converter`, `holidays`, `events`, `settings`, `home`) rather than generic technical types (`widgets/`, `models/`), simplifying maintenance and testing.
3. **Reactive State Management with Riverpod:** Immutable state flows, compile-safe dependency injection, and fine-grained UI re-renders without unnecessary widget rebuilds.
4. **Offline-First Resilience:** 100% of calendar conversions, Computus calculations, holiday derivations, and event operations execute locally on-device with zero network latency and complete privacy.

---

## 2. Kotlin vs. Flutter Architectural Mapping

| Android Native (Original Kotlin) | Flutter Target Implementation | Architectural Rationalization |
|---|---|---|
| **Kotlin `calendar-core` Module** | **Pure Dart `lib/core/calendar/`** | Zero Flutter dependencies; runs in pure Dart CLI, unit tests, and across platforms (Android, iOS, Web). |
| **Jetpack Compose UI** | **Flutter Material 3 Widgets** | Declarative UI paradigm; direct mapping of `@Composable` functions to `ConsumerWidget` and `StatelessWidget`. |
| **Android ViewModel (`MainViewModel`)** | **Riverpod StateNotifier / NotifierProviders** | Replaces Android-specific Lifecycle ViewModel with platform-agnostic, testable state providers. |
| **Room SQLite (`AppDatabase` + `EventEntity`)** | **`sqflite` Local SQLite Database (`AppDatabase`)** | Maintains exact identical SQL schema (`events` table) enabling seamless backward compatibility and data migration. |
| **AndroidX DataStore / SharedPreferences** | **`shared_preferences` (`UserPreferencesRepository`)** | Key-value store for app settings, theme modes, locale selections, and onboarding flags. |
| **Android `AlarmManager` + `BroadcastReceiver`** | **`flutter_local_notifications` + Android Native Alarm Receiver** | Native Android exact alarm scheduling with reboot persistence (`RECEIVE_BOOT_COMPLETED`). |
| **AppWidgetProvider (`widget_ethiocal.xml`)** | **Native Android AppWidgetProvider XML & Kotlin Receiver** | High-performance home-screen widgets rendered directly by Android system RemoteViews without waking Flutter engine. |
| **Android XML Resources & Mipmaps** | **Flutter Assets + Android Native Resources** | App launcher icons and widget drawables preserved in `android/app/src/main/res/`. |

---

## 3. Directory & Layer Organization

```
lib/
├── main.dart                                   # Application bootstrap, DI scope, Theme initialization
├── core/                                       # Cross-cutting foundational modules
│   ├── calendar/                               # Pure Dart Ethiopian Calendar Engine
│   │   ├── ethiopian_date.dart                 # Immutable value object & validation
│   │   ├── gregorian_date.dart                 # Gregorian value object
│   │   ├── ethiopian_month.dart                # 13 months enum & metadata
│   │   ├── leap_year_calculator.dart           # Evangelist & leap year rules
│   │   ├── ethiopian_date_converter.dart       # Julian Day Number conversion engine
│   │   ├── bahire_hasab.dart                   # Orthodox Computus calculations
│   │   ├── geez_numeral.dart                   # Ge'ez numeral conversion (፩ .. ፼)
│   │   ├── ethiopian_time_converter.dart       # Traditional 12-hour day/night cycle
│   │   ├── ethiopian_season.dart               # 4 canonical Ethiopian seasons
│   │   └── ethiopian_calendar_engine.dart      # Unified facade, arithmetic, & day resolvers
│   ├── holidays/                               # Holiday engine (National, Orthodox, Islamic, Cultural)
│   │   └── holiday_engine.dart
│   ├── heritage/                               # Cultural wisdom & daily proverbs
│   │   └── daily_heritage_engine.dart
│   ├── world/                                  # Comparative world cities engine
│   │   └── world_country_engine.dart
│   ├── localization/                           # Multi-lingual dictionary (5 languages)
│   │   ├── app_language.dart
│   │   └── locale_strings.dart
│   ├── notifications/                          # Local notifications scheduler
│   │   └── notification_scheduler.dart
│   ├── theme/                                  # Design system tokens & Material 3 theming
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   ├── export/                                 # RFC 5545 iCalendar (.ics) exporter
│   │   └── ics_exporter.dart
│   └── utils/                                  # Platform helpers (sharing, formatting)
│       └── share_helper.dart
├── data/                                       # Data access & persistence
│   ├── local/                                  # SQLite database
│   │   └── app_database.dart
│   ├── models/                                 # Data transfer objects & entities
│   │   └── event_entity.dart
│   └── preferences/                            # Key-value persistent settings
│       └── user_preferences_repository.dart
├── features/                                   # Feature-first presentation & state
│   ├── home/                                   # Home dashboard & daily overview
│   │   └── home_screen.dart
│   ├── calendar/                               # Interactive multi-view calendar
│   │   ├── calendar_screen.dart
│   │   └── widgets/
│   │       └── dual_date_day_cell.dart
│   ├── converter/                              # Date, time, age, and numeral converters
│   │   ├── converter_screen.dart
│   │   └── tabs/
│   ├── holidays/                               # Holiday center, fasts, & greeting studio
│   │   ├── holidays_screen.dart
│   │   ├── dialogs/
│   │   └── tabs/
│   ├── events/                                 # Personal event management & reminders
│   │   ├── events_screen.dart
│   │   └── dialogs/
│   ├── settings/                               # Application preferences & customization
│   │   └── settings_screen.dart
│   ├── onboarding/                             # First-time introductory walkthrough
│   │   └── onboarding_screen.dart
│   └── shared/                                 # Shared presentation components & providers
│       ├── providers.dart
│       └── components/
```

---

## 4. State Management Architecture

Riverpod manages state predictably without tight coupling to the Flutter widget hierarchy:

1. **`userSettingsProvider`:**
   - Type: `StateNotifierProvider<UserSettingsNotifier, UserSettings>`
   - Responsibilities: Language, theme mode, accent palette, numeral format (Arabic vs Ge'ez), calendar format (Ethiopian vs Gregorian), first day of the week (Sunday vs Monday), fasting/saints display toggles.
   - Persistence: Automatically persists state changes to `UserPreferencesRepository` (SharedPreferences).

2. **`calendarStateProvider` (`selectedDateProvider`, `viewYearProvider`, `viewMonthProvider`):**
   - Type: `StateProvider<EthiopianDate>`, `StateProvider<int>`
   - Responsibilities: Synchronizes selected date and active calendar viewing coordinates across Home, Calendar, Converter, and Navigation Shell.

3. **`eventsProvider`:**
   - Type: `StateNotifierProvider<EventsNotifier, List<EventEntity>>`
   - Responsibilities: Asynchronous CRUD actions on SQLite `AppDatabase`, event completion toggling, filtering by date/category, and automatic alarm scheduling.

4. **`todayEthiopianProvider` & `currentTimeProvider`:**
   - Type: `Provider<EthiopianDate>`, `StreamProvider<DateTime>`
   - Responsibilities: Emits current date and real-time second ticks for the animated traditional Ethiopian clock face.

---

## 5. Offline Data Storage & Migration Strategy

### 5.1. SQLite Database Schema
EthioCal Pro uses SQLite via `sqflite`. The table structure mirrors the Room schema:

```sql
CREATE TABLE events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  ethiopianYear INTEGER NOT NULL,
  ethiopianMonth INTEGER NOT NULL,
  ethiopianDay INTEGER NOT NULL,
  gregorianYear INTEGER NOT NULL,
  gregorianMonth INTEGER NOT NULL,
  gregorianDay INTEGER NOT NULL,
  hour INTEGER NOT NULL,
  minute INTEGER NOT NULL,
  category TEXT NOT NULL,
  color INTEGER NOT NULL,
  reminderMinutesBefore INTEGER NOT NULL,
  isRecurring INTEGER NOT NULL,
  recurrenceType TEXT NOT NULL,
  isCompleted INTEGER NOT NULL,
  createdAt INTEGER NOT NULL
);
CREATE INDEX idx_events_date ON events(ethiopianYear, ethiopianMonth, ethiopianDay);
```

### 5.2. Backward Compatibility & Migration from Android Room
When an existing user updates from the Kotlin app to the Flutter app, the SQLite database file `calendar_database.db` located in the Android application sandbox (`/data/data/com.zemen.calendar/databases/`) is automatically recognized and opened by `sqflite`. No data loss occurs because column names, types, and primary key structures are identical.

---

## 6. Performance & Quality Benchmarks

- **Startup Latency:** < 600ms on mid-range Android devices (cold start).
- **Frame Rate:** Sustained 60/120 fps during continuous calendar swiping and page transitions.
- **Memory Footprint:** < 65 MB resident set size (RSS).
- **Battery Impact:** Zero background drain; widget updates triggered by system alarms only at midnight.
