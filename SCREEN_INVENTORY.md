# EthioCal Pro – Screen Inventory

> Primary screens migrated; see VERIFICATION_REPORT.md for remaining gaps.  
> Routes use `go_router` path conventions.

---

## Screen Map

| # | Screen | Route | Key Widgets | Nav Trigger | Status |
|---|--------|-------|-------------|-------------|--------|
| 1 | OnboardingScreen | `/onboarding` | `PageView`, step indicators, permission requests, "Get Started" CTA | Auto on first launch (onboardingCompleted == false) | DONE |
| 2 | HomeScreen | `/home` | `TodayDateCard`, `UpcomingHolidayCard`, `QuickActionsRow`, `TodayEventsList`, `DailyHeritageProverb` | Bottom nav tab 1 | DONE |
| 3 | CalendarScreen | `/calendar` | `MonthViewGrid`, `WeekView`, `YearView`, `DayView`, `EventMarkerDots`, `CustomDualDatePicker`, view-mode `SegmentedButton` | Bottom nav tab 2 | DONE |
| 4 | ConverterScreen | `/converter` | `TabBar` (10 sub-tabs), `DateConverterTab`, `AgeCalculatorTab`, `DateDiffTab`, `GeezNumeralTab`, `TimeConverterTab`, `TimezoneTab`, `FastingGuideTab`, `BahireHasabTab`, `MonthlySaintsTab`, `GreetingCardTab` | Bottom nav tab 3 | DONE |
| 5 | HolidaysScreen | `/holidays` | Grouped `ListView` of holidays, `HolidayListTile`, year filter chip row | Bottom nav tab 4 | DONE |
| 6 | EventsScreen | `/events` | `EventListView`, search `TextField`, category filter chips, FAB (add), `EventListTile`, swipe-to-delete | Bottom nav tab 5 | DONE |
| 7 | SettingsScreen | `/settings` | `LanguageSelector`, `NumeralTypeSelector`, `ThemeModeSelector`, `AccentPaletteSelector`, `FirstDayOfWeekSelector`, fasting/saints toggles, notifications toggle | Bottom nav tab 6 | DONE |

---

## Overlay / Dialog Screens

| # | Dialog / Bottom Sheet | Trigger | Key Widgets | Status |
|---|-----------------------|---------|-------------|--------|
| D1 | `AddEditEventDialog` | FAB on Events / long-press on calendar day | Dual date fields, title, description, category, recurrence, reminder, color picker, all-day toggle | DONE |
| D2 | `HolidayDetailDialog` | Tap on a holiday list tile | Holiday name, date (Eth + Greg), description, share button, reminder button | DONE |
| D3 | `HolidayCardShareDialog` | Share button in HolidayDetailDialog | Generated card preview, social share options | DONE |
| D4 | `SetHolidayReminderDialog` | Reminder button in HolidayDetailDialog | Time picker, notification preview | DONE |
| D5 | `EthiopianClockDialog` | Clock icon on HomeScreen / ConverterScreen | Analog Ethiopian clock face, standard↔traditional toggle | DONE |
| D6 | `WidgetManagementDialog` | Settings → Widget Management | Full/compact widget selector, preview | DONE |
| D7 | `CustomDualDatePicker` | Date fields in AddEditEvent / DateConverter | Side-by-side Ethiopian + Gregorian calendar grids, synchronized selection | DONE |

---

## Detailed Screen Specifications

### 1. OnboardingScreen (`/onboarding`)

| Property | Value |
|----------|-------|
| Shown when | `onboardingCompleted == false` in AppSettings |
| Transition | Replaces the route stack; navigates to `/home` on completion |
| Pages | 3 (Welcome, Features overview, Permission request) |
| State | Local `PageController`; no Riverpod needed |
| Persistence | Writes `onboardingCompleted = true` via `settingsProvider` on "Get Started" |

**Key Widgets:**
- `PageView` with 3 `OnboardingPage` widgets
- Animated dot indicator
- "Skip" TextButton (top-right)
- "Next" / "Get Started" ElevatedButton
- Permission request tile (notifications)

---

### 2. HomeScreen (`/home`)

| Property | Value |
|----------|-------|
| Nav tab | Index 0, icon: `home_outlined` / `home` |
| State provider | `homeProvider` (Riverpod `StateNotifier`) |
| Data sources | `todayEthiopianDate`, `upcomingHoliday`, `todayEvents`, `dailyProverb` |
| Scroll | `CustomScrollView` with `SliverAppBar` + slivers |

**Key Widgets:**
- `TodayDateCard` – Large card: Ethiopian date (Geez or Arabic numerals), Gregorian date, season, week day
- `UpcomingHolidayCard` – Next holiday name, days remaining chip
- `QuickActionsRow` – Row of `IconButton`s: Add Event, Converter, Holidays, Calendar
- `TodayEventsList` – `ListView` of `EventListTile`; "No events" empty state
- `DailyHeritageProverb` – Expandable card showing today's Ethiopian proverb

---

### 3. CalendarScreen (`/calendar`)

| Property | Value |
|----------|-------|
| Nav tab | Index 1, icon: `calendar_month_outlined` / `calendar_month` |
| State provider | `calendarProvider` |
| View modes | Month (default), Week, Day, Year |
| Data sources | `EventRepository`, `HolidayRepository` |

**Key Widgets:**
- `SegmentedButton` – Month / Week / Day / Year toggle
- `MonthViewGrid` – 7-column grid of `DayCell`s; event marker dots; today highlight; selected day highlight
- `WeekView` – Horizontal 7-day strip with time slots
- `DayView` – Time-slot list for a single day with event blocks
- `YearView` – 12 mini-month grids
- `EventMarkerDots` – Up to 3 color dots under a day cell
- `CustomDualDatePicker` – Triggered by tapping the app-bar title; shows Eth+Greg pickers in sync

---

### 4. ConverterScreen (`/converter`)

| Property | Value |
|----------|-------|
| Nav tab | Index 2, icon: `swap_horiz_outlined` / `swap_horiz` |
| State provider | Per-tab sub-providers |
| Sub-tabs | 10 tabs in a `DefaultTabController` + `TabBar` |

**Sub-tab Widgets:**

| Tab | Route Segment | Key Widgets |
|-----|---------------|-------------|
| Date Converter | (tab 0) | Input date fields (Eth/Greg), `ElevatedButton` convert, result card |
| Age Calculator | (tab 1) | Birthdate picker, two result cards (Eth age, Greg age) |
| Date Difference | (tab 2) | Two date pickers, difference display (years/months/days) |
| Geez Numeral | (tab 3) | Number `TextField`, Geez numeral display, reverse lookup |
| Time Converter | (tab 4) | Standard time picker, Ethiopian time display, `EthiopianClockDialog` trigger |
| Country Comparator | (tab 5) | Country dropdown × 2, time zone offset, world clock cards |
| Fasting Guide | (tab 6) | Calendar month view with fasting-day highlights, legend |
| Bahire Hasab | (tab 7) | Year input, computed movable feast table |
| Monthly Saints | (tab 8) | Month selector, saint list with descriptions |
| Greeting Card Studio | (tab 9) | Occasion selector, AI-generated card preview, share/download |

---

### 5. HolidaysScreen (`/holidays`)

| Property | Value |
|----------|-------|
| Nav tab | Index 3, icon: `celebration_outlined` / `celebration` |
| State provider | `holidaysProvider` |
| Data source | `HolidayRepository` |
| Grouping | By category: Orthodox, Islamic, Public, Cultural |

**Key Widgets:**
- Year selector chip row (current year ± 2)
- `SliverStickyHeader` per category
- `HolidayListTile` – holiday name, Eth date, Greg date, days-remaining chip
- Tapping a tile opens `HolidayDetailDialog`

---

### 6. EventsScreen (`/events`)

| Property | Value |
|----------|-------|
| Nav tab | Index 4, icon: `event_outlined` / `event` |
| State provider | `eventsProvider` |
| Data source | `EventRepository` |
| Interaction | FAB → AddEditEventDialog; swipe left → delete; tap → detail/edit |

**Key Widgets:**
- `SearchBar` (top) with debounce
- Category filter `FilterChip` row
- `AnimatedList` / `ListView.builder` of `EventListTile`
- `EventListTile` – colored left border (colorHex), title, Eth date, category icon, completion checkbox
- `FloatingActionButton` – add event
- Empty state illustration + "Add your first event" CTA

---

### 7. SettingsScreen (`/settings`)

| Property | Value |
|----------|-------|
| Nav tab | Index 5, icon: `settings_outlined` / `settings` |
| State provider | `settingsProvider` |
| Data source | `AppSettingsRepository` |

**Key Widgets:**
- `SettingsSectionHeader` per group
- `LanguageSelector` – `DropdownButton` (English / አማርኛ)
- `NumeralTypeSelector` – `SegmentedButton` (1 2 3 / ፩ ፪ ፫)
- `ThemeModeSelector` – `SegmentedButton` (Light / Dark / AMOLED)
- `AccentPaletteSelector` – 4-swatch `ChoiceChip` row
- `FirstDayOfWeekSelector` – Sunday / Monday / Saturday
- `SwitchListTile` × 3 (fasting, saints, notifications)
- Widget management link tile → `WidgetManagementDialog`

---

## Navigation Flow Diagram

```
App Launch
    │
    ├─ onboardingCompleted == false ──► OnboardingScreen ──► HomeScreen
    │
    └─ onboardingCompleted == true  ──► HomeScreen
                                            │
                              ┌─────────────┼─────────────┐
                              │             │             │
                        CalendarScreen ConverterScreen HolidaysScreen
                              │             │             │
                        EventsScreen   SettingsScreen     │
                              │                           │
                     AddEditEventDialog           HolidayDetailDialog
                                                       │        │
                                            HolidayCardShareDialog
                                            SetHolidayReminderDialog
```

