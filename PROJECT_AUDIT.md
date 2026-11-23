# EthioCal Pro — Original Application Audit (PROJECT_AUDIT.md)

**Audit Date:** November 2026  
**Auditor:** Senior Mobile Application Architect & Ethiopian Calendar Specialist  
**Original Architecture:** Android Native (Kotlin + Jetpack Compose + Room + Coroutines/Flow)  
**Target Migration Architecture:** Flutter (Dart + Clean Feature-First Architecture + Riverpod + sqflite)

---

## 1. Executive Summary

This audit represents an exhaustive technical examination of the original Android Kotlin application `EthioCal Pro` located in `app/` and its mathematical calendar engine library in `calendar-core/`. The original implementation provides a feature-rich, culturally grounded Ethiopian and Gregorian dual-calendar experience built with modern Android native technologies (Kotlin 2.0+, Jetpack Compose Material 3, Room SQLite persistence, AndroidX DataStore, AlarmManager, and native AppWidgetProvider home-screen widgets).

The goal of this audit is to catalogue every component, data structure, business logic rule, permission, and asset to guarantee 100% functional and visual fidelity throughout the Flutter migration.

---

## 2. Source Code & Module Structure

```
Ethiopian-Calander-main/
├── app/                                    # Android Application Module
│   ├── build.gradle.kts                    # App build configuration & dependencies
│   ├── proguard-rules.pro                  # R8/Proguard shrinking rules
│   └── src/
│       ├── main/
│       │   ├── AndroidManifest.xml         # Manifest, permissions, receivers, widgets
│       │   ├── java/com/example/           # Kotlin source code root
│       │   │   ├── MainActivity.kt         # Single activity host with Jetpack Compose
│       │   │   ├── calendar/
│       │   │   │   ├── data/               # Persistence layer (Room DB, DAO, Repositories)
│       │   │   │   ├── domain/             # Domain models (Month, CalendarDomain)
│       │   │   │   ├── engine/             # Core engines (Computus, Holidays, Heritage, World)
│       │   │   │   ├── localization/       # Multi-lingual dictionary (5 languages)
│       │   │   │   ├── notification/       # AlarmReceiver, BootReceiver, NotificationScheduler
│       │   │   │   ├── ui/                 # Jetpack Compose UI (Screens, Dialogs, ViewModel)
│       │   │   │   └── widget/             # Android AppWidgetProviders (Full & Compact)
│       │   │   └── ui/theme/               # Jetpack Compose Theme, Colors, Typography
│       │   └── res/                        # Android resources (Drawables, XMLs, Layouts)
│       └── test/                           # Unit tests
└── calendar-core/                          # Pure Kotlin Calendar Logic Module
    ├── build.gradle.kts
    └── src/
        ├── main/java/com/example/calendar/core/
        │   ├── BahireHasab.kt              # Computus calculation engine
        │   ├── EthiopianDate.kt            # Core value object with leap rules
        │   ├── EthiopianDateConverter.kt   # Astronomical Julian Day Number converter
        │   ├── EthiopianMonth.kt           # 13 months enum with names
        │   ├── EthiopianSeason.kt          # 4 Ethiopian seasons
        │   ├── EthiopianTime.kt            # Traditional 12-hour clock engine
        │   ├── GeezNumeral.kt              # Ge'ez numeral encoder/decoder
        │   ├── GregorianDate.kt            # Gregorian date value object
        │   ├── GregorianToEthiopianConverter.kt
        │   └── LeapYearCalculator.kt       # 4-year Evangelist cycle (Luke leap)
        └── test/                           # Mathematical & algorithmic test suite
```

---

## 3. Detailed Component Breakdown

### 3.1. Calendar Core Engines (`calendar-core/` and `app/.../engine/`)

| File | Purpose & Responsibilities | Key Functions & Formulas |
|---|---|---|
| `EthiopianDate.kt` | Immutable value object representing an Ethiopian date (Year, Month 1..13, Day 1..30). | Validates month ranges (1..13), checks Pagume limit (5 or 6 days depending on `isLeapYear`), equality, comparison, string formatting. |
| `GregorianDate.kt` | Immutable value object representing a Gregorian date (Year, Month 1..12, Day 1..31). | Validates Gregorian month days including leap February (29 days). |
| `LeapYearCalculator.kt` | Determines Ethiopian and Gregorian leap years and Evangelist years. | `year % 4 == 3` defines Ethiopian leap year (Luke/ሉቃስ). Evangelists: John (0), Matthew (1), Mark (2), Luke (3). |
| `EthiopianDateConverter.kt` | Astronomical Julian Day Number (JDN) conversions between Ethiopian and Gregorian. | Ethiopian Epoch JDN: `1724221` (August 29, 8 CE Gregorian Julian). Rigorous mathematical transformation without lookup tables. |
| `BahireHasabCalculator.kt` | Traditional Ethiopian Orthodox Computus calculation engine. | Computes: Amete Alem (`year + 5500`), Medeb (`ameteAlem % 19`), Wenber (`(medeb + 18) % 19`), Abeqte (`(wenber * 11) % 30`), Metqi (`(wenber * 19) % 30`), Tinte Qemer, Mebaja Hamer, and all 11 movable feasts (Nenewe, Abiy Tsom, Debre Zeit, Hosanna, Siklet, Fasika, Rikbe Kahnat, Erget, Paraklitos, Tsome Hawaryat, Tsome Dihnet). |
| `GeezNumberFormatter.kt` / `GeezNumeral.kt` | Bidirectional converter between Arabic numbers (1..99999) and Ge'ez script. | Uses canonical units (፩..፱), tens (፲..፺), and hundred/ten-thousand markers (፻, ፼). |
| `EthiopianTimeConverter.kt` | Traditional Ethiopian 12-hour day/night timekeeping engine. | Ethiopian 1:00 Day = Gregorian 7:00 AM (07:00). Ethiopian 1:00 Night = Gregorian 7:00 PM (19:00). Computes day phase (*Ke’at*), Amharic diurnal names, and analog clock angles. |
| `HolidayEngine.kt` | Repository and calculator for all Ethiopian observances. | Calculates annual public holidays, Orthodox movable feasts (via Bahire Hasab), Islamic Hijri observances (Eid, Ramadan), regional cultural festivals (Irreecha, Fichee, Ashenda), 7 canonical fasts, and all 30 monthly saints. |
| `DailyHeritageEngine.kt` | Cultural wisdom repository containing 36 traditional proverbs. | Maps daily proverbs to days 1..30 of each month plus days 1..6 of Pagume, with English translations, Amharic originals, categories, and life applications. |
| `WorldCountryEngine.kt` | Comparative world clock engine. | Features 26 global cities with timezone offsets from Addis Ababa (UTC+3), local civic times, business hours, and dual calendar displays. |

### 3.2. Data Persistence Layer (`app/.../data/`)

| File | Type | Purpose | Schema / Key Details |
|---|---|---|---|
| `EventEntity.kt` | Room Entity (`@Entity(tableName = "events")`) | Represents personal calendar events and reminders. | Fields: `id` (Long PK autoincrement), `title` (String), `description` (String), `ethiopianYear`, `ethiopianMonth`, `ethiopianDay`, `gregorianYear`, `gregorianMonth`, `gregorianDay`, `hour`, `minute`, `category` (PERSONAL, WORK, RELIGIOUS, BIRTHDAY, ANNIVERSARY, HOLIDAY), `color` (Int hex), `reminderMinutesBefore` (Int), `isRecurring` (Boolean), `recurrenceType` (NONE, DAILY, WEEKLY, MONTHLY_ETHIOPIAN, YEARLY_ETHIOPIAN, YEARLY_GREGORIAN), `isCompleted` (Boolean), `createdAt` (Long). |
| `EventDao.kt` | Room DAO | Database access methods. | Queries: `getAllEvents()`, `getEventsForDate(eYear, eMonth, eDay)`, `getEventsForMonth(eYear, eMonth)`, `searchEvents(query)`, `insertEvent()`, `updateEvent()`, `deleteEvent()`, `toggleEventCompleted()`. |
| `AppDatabase.kt` | RoomDatabase (`version = 1`) | SQLite Room database initialization. | Database file: `calendar_database.db`. Migration strategy defined. |
| `UserPreferencesRepository.kt` | AndroidX DataStore | Stores user configurations and preferences. | Settings: `language` (AMHARIC, ENGLISH, OROMO, TIGRINYA, FRENCH), `themeMode` (SYSTEM, LIGHT, DARK, AMOLED), `accentPalette` (GOLD_EMERALD, ROYAL_INDIGO, AXUM_CRIMSON, SIMIEN_TERRACOTTA), `numeralType` (ARABIC, GEEZ), `calendarFormat` (ETHIOPIAN, GREGORIAN), `firstDayOfWeek` (SUNDAY, MONDAY), `showFasting` (Boolean), `showSaints` (Boolean), `dailyReminderEnabled` (Boolean), `onboardingCompleted` (Boolean). |
| `IcsExporter.kt` | Data Exporter | Generates standard RFC 5545 iCalendar (`.ics`) format strings. | Enables exporting application events to Google Calendar, Apple Calendar, and Outlook. |

### 3.3. Notification & Background Scheduling (`app/.../notification/`)

- `AlarmReceiver.kt`: Broadcast receiver that wakes up on scheduled exact alarm, triggers heads-up notification with high priority, custom sound, and vibration pattern.
- `BootReceiver.kt`: Listens to `BOOT_COMPLETED`, `TIME_SET`, `TIMEZONE_CHANGED`, and `MY_PACKAGE_REPLACED` to reschedule active event reminders after system reboots.
- `NotificationScheduler.kt`: Interfaces with Android `AlarmManager` using `setExactAndAllowWhileIdle()` to ensure timely reminders even in Doze mode.

### 3.4. Android Home-Screen Widgets (`app/.../widget/`)

- `EthioCalWidgetProvider.kt`: Full 4x3 home screen widget featuring:
  - Dual Ethiopian (Ge'ez and Arabic) & Gregorian current dates.
  - Traditional 12-hour daytime/nighttime clock reading.
  - Orthodox fasting indicator badge.
  - Daily commemorative saint name.
  - Quick action buttons (Open Calendar, Launch Clock, Add Event, Refresh).
  - Midnight alarm auto-reschedule via `MIDNIGHT_ALARM_REQUEST_CODE`.
- `EthioCalCompactWidgetProvider.kt`: Compact 2x1 widget featuring:
  - Quick-glance dual date badge.
  - Current Ethiopian day of week and month.

### 3.5. User Interface & Jetpack Compose Screens (`app/.../ui/`)

| Screen / Component | Description & Key UI Elements |
|---|---|
| `MainActivity.kt` | Single activity host configuring Edge-to-Edge window insets and hosting `NavScreen`. |
| `NavScreen.kt` | Scaffold with TopAppBar and NavigationBar (6 items: Home, Calendar, Converter, Holidays, Events, Settings). |
| `HomeScreen.kt` | Hero card with live date, interactive traditional clock dial, daily fasting banner, daily saint card, daily Ethiopian wisdom/proverb, upcoming holidays countdown, quick action cards, today's event list. |
| `CalendarScreen.kt` | Comprehensive calendar view: Ethiopian/Gregorian switch, 4 views (Month, Week, Year, Day), inline dual date picker accordion, return-to-today banner, 7x6 month grid with Sunday highlighted in red (`#DC2626`), dual date badges in every cell, selected date inspector with Ge'ez numerals and fasting/saints pills. |
| `ConverterScreen.kt` | 6 sub-tabs: Date Converter (ET ⇄ GD), Time Converter (12-hr Ethiopian ⇄ 24-hr Gregorian), Age & Date Difference, Bahire Hasab Computus Explorer, Ge'ez Numeral Converter, World Country Comparator (26 cities). |
| `HolidaysScreen.kt` | 4 sub-tabs: Annual Holidays (National, Religious, Cultural), Fasting Guide (7 canonical fasts), Monthly Saints (days 1..30), Greeting Card Studio (8 holiday presets, 5 themes, image share). |
| `EventsScreen.kt` | SQLite personal event manager: search bar, category chips, event list with completion checkbox, swipe actions, add/edit event modal dialog, ICS export. |
| `SettingsScreen.kt` | Application preferences: language picker, numeral type, theme mode, accent palette, calendar format, first day of week, notifications toggle, about dialog. |
| `OnboardingScreen.kt` | 3-page walkthrough for first-time users introducing the Ethiopian calendar, dual-date conversion, and cultural heritage features. |

---

## 4. Dependencies & Permissions Audit

### 4.1. Android Permissions (`AndroidManifest.xml`)
- `android.permission.RECEIVE_BOOT_COMPLETED`: Reschedules event reminders on device reboot.
- `android.permission.POST_NOTIFICATIONS`: Android 13+ runtime notification permission.
- `android.permission.VIBRATE`: Haptic feedback on alarms and reminders.
- `android.permission.SCHEDULE_EXACT_ALARM`: Ensures exact delivery for calendar alarms.
- `android.permission.WAKE_LOCK`: Wakes CPU briefly to show reminder dialog.
- `android.permission.READ_CALENDAR` / `WRITE_CALENDAR`: Calendar provider access for device calendar synchronization.

### 4.2. Gradle Dependencies (`app/build.gradle.kts`)
- `compileSdk = 35` (or 36/37)
- `minSdk = 24`
- `targetSdk = 35`
- Jetpack Compose BOM (`androidx.compose:compose-bom`)
- Room Database (`androidx.room:room-runtime`, `androidx.room:room-ktx`)
- AndroidX DataStore Preferences (`androidx.datastore:datastore-preferences`)
- Kotlin Coroutines & Flow (`kotlinx-coroutines-android`)
- Material Design 3 (`androidx.compose.material3:material3`)

---

## 5. Architectural Quality & Technical Debt Assessment

1. **Strengths of Original Implementation:**
   - Pure separation of calendar mathematics (`calendar-core`) from Android framework code.
   - Rigorous Computus and Julian Day Number formulas without approximations.
   - Native home-screen widget support with automatic midnight updates.
   - Comprehensive multi-lingual text repository covering 5 languages.

2. **Migration Considerations for Flutter:**
   - Maintain the pure Dart calendar engine without any third-party black-box packages to ensure complete transparency and zero licensing risks.
   - Implement native Android `AppWidgetProvider` layouts so that widgets continue to work natively without requiring flutter engine spin-up.
   - Ensure Ge'ez fonts are bundled locally in the APK/AAB to prevent blank square ("tofu") rendering on devices without built-in Ethiopic fonts.
   - Preserve exact SQLite schema to allow seamless database migration for existing users.
