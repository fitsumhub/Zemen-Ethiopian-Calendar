# EthioCal Pro – Feature Inventory

> **Legend — Priority:** P0 = Blocker / Core, P1 = High, P2 = Medium, P3 = Low / Nice-to-have  
> **Status for migrated items is DONE; remaining gaps listed in VERIFICATION_REPORT.md until a developer marks otherwise.

---

## 1. Calendar Engine

| Feature | Kotlin Location | Flutter Target | Priority | Status |
|---------|----------------|----------------|----------|--------|
| Ethiopian↔Gregorian date conversion (JDN-based) | `calendar-core/EthiopianDateConverter.kt` | `lib/core/calendar/ethiopian_date_converter.dart` | P0 | DONE |
| `EthiopianDate` value class | `calendar-core/EthiopianDate.kt` | `lib/core/calendar/ethiopian_date.dart` | P0 | DONE |
| `GregorianDate` value class | `calendar-core/GregorianDate.kt` | `lib/core/calendar/gregorian_date.dart` | P0 | DONE |
| `EthiopianMonth` enum (13 months) | `calendar-core/EthiopianMonth.kt` | `lib/core/calendar/ethiopian_month.dart` | P0 | DONE |
| Leap year calculation | `calendar-core/LeapYearCalculator.kt` | `lib/core/calendar/leap_year_calculator.dart` | P0 | DONE |
| `BahireHasab` Orthodox Computus | `calendar-core/BahireHasab.kt` | `lib/core/calendar/bahire_hasab.dart` | P0 | DONE |
| Nenewe (movable feast) | `calendar-core/BahireHasab.kt` | `lib/core/calendar/bahire_hasab.dart` | P0 | DONE |
| Fasika / Easter (movable feast) | `calendar-core/BahireHasab.kt` | `lib/core/calendar/bahire_hasab.dart` | P0 | DONE |
| Erget / Ascension (movable feast) | `calendar-core/BahireHasab.kt` | `lib/core/calendar/bahire_hasab.dart` | P0 | DONE |
| Paraclete / Pentecost (movable feast) | `calendar-core/BahireHasab.kt` | `lib/core/calendar/bahire_hasab.dart` | P0 | DONE |
| Geez numeral Arabic↔Geez conversion | `calendar-core/GeezNumeral.kt` | `lib/core/calendar/geez_numeral.dart` | P1 | DONE |
| Ethiopian traditional 12-hr time | `calendar-core/EthiopianTimeConverter.kt` | `lib/core/calendar/ethiopian_time_converter.dart` | P1 | DONE |
| Ethiopian season enum (4 seasons) | `calendar-core/EthiopianSeason.kt` | `lib/core/calendar/ethiopian_season.dart` | P1 | DONE |

---

## 2. Data Layer

| Feature | Kotlin Location | Flutter Target | Priority | Status |
|---------|----------------|----------------|----------|--------|
| `EventEntity` schema (Room DB) | `data/db/EventEntity.kt` | `lib/data/local/event_table.dart` (Drift) | P0 | DONE |
| `EventDao` – insert, update, delete | `data/db/EventDao.kt` | `lib/data/local/event_dao.dart` | P0 | DONE |
| `EventDao` – query by date | `data/db/EventDao.kt` | `lib/data/local/event_dao.dart` | P0 | DONE |
| `EventDao` – search / filter | `data/db/EventDao.kt` | `lib/data/local/event_dao.dart` | P1 | DONE |
| `EventRepository` | `data/repository/EventRepository.kt` | `lib/data/repositories/event_repository.dart` | P0 | DONE |
| Recurrence types (7 types) | `data/model/RecurrenceType.kt` | `lib/data/models/recurrence_type.dart` | P1 | DONE |
| Event categories (8 types) | `data/model/EventCategory.kt` | `lib/data/models/event_category.dart` | P1 | DONE |
| DataStore – language preference | `data/datastore/AppPreferences.kt` | `lib/data/preferences/app_settings.dart` | P0 | DONE |
| DataStore – numeral type preference | `data/datastore/AppPreferences.kt` | `lib/data/preferences/app_settings.dart` | P0 | DONE |
| DataStore – calendar format preference | `data/datastore/AppPreferences.kt` | `lib/data/preferences/app_settings.dart` | P0 | DONE |
| DataStore – theme mode | `data/datastore/AppPreferences.kt` | `lib/data/preferences/app_settings.dart` | P1 | DONE |
| DataStore – accent palette | `data/datastore/AppPreferences.kt` | `lib/data/preferences/app_settings.dart` | P1 | DONE |
| DataStore – first day of week | `data/datastore/AppPreferences.kt` | `lib/data/preferences/app_settings.dart` | P1 | DONE |
| DataStore – show fasting | `data/datastore/AppPreferences.kt` | `lib/data/preferences/app_settings.dart` | P1 | DONE |
| DataStore – show monthly saints | `data/datastore/AppPreferences.kt` | `lib/data/preferences/app_settings.dart` | P1 | DONE |
| DataStore – notifications enabled | `data/datastore/AppPreferences.kt` | `lib/data/preferences/app_settings.dart` | P1 | DONE |
| DataStore – onboarding completed | `data/datastore/AppPreferences.kt` | `lib/data/preferences/app_settings.dart` | P0 | DONE |
| Room → Drift migration (existing users) | N/A (migration script) | `lib/data/local/migration_helper.dart` | P0 | PENDING |

---

## 3. Holidays & Fasting Engine

| Feature | Kotlin Location | Flutter Target | Priority | Status |
|---------|----------------|----------------|----------|--------|
| 30 monthly saints data | `data/holidays/MonthlySaints.kt` | `lib/features/holidays/data/monthly_saints.dart` | P1 | DONE |
| Fixed Orthodox holidays | `data/holidays/OrthodoxHolidays.kt` | `lib/features/holidays/data/orthodox_holidays.dart` | P0 | DONE |
| Enkutatash (Ethiopian New Year) | `data/holidays/OrthodoxHolidays.kt` | `lib/features/holidays/data/orthodox_holidays.dart` | P0 | DONE |
| Meskel (Finding of the True Cross) | `data/holidays/OrthodoxHolidays.kt` | `lib/features/holidays/data/orthodox_holidays.dart` | P0 | DONE |
| Genna (Christmas) | `data/holidays/OrthodoxHolidays.kt` | `lib/features/holidays/data/orthodox_holidays.dart` | P0 | DONE |
| Timket (Epiphany) | `data/holidays/OrthodoxHolidays.kt` | `lib/features/holidays/data/orthodox_holidays.dart` | P0 | DONE |
| Movable Orthodox feasts (BahireHasab) | `calendar-core/BahireHasab.kt` | `lib/core/calendar/bahire_hasab.dart` | P0 | DONE |
| Islamic holidays | `data/holidays/IslamicHolidays.kt` | `lib/features/holidays/data/islamic_holidays.dart` | P1 | DONE |
| National public holidays | `data/holidays/PublicHolidays.kt` | `lib/features/holidays/data/public_holidays.dart` | P0 | DONE |
| Cultural events | `data/holidays/CulturalEvents.kt` | `lib/features/holidays/data/cultural_events.dart` | P1 | DONE |
| `FastingStatus` per-day calculation | `data/holidays/FastingCalculator.kt` | `lib/features/holidays/data/fasting_calculator.dart` | P1 | DONE |
| `HolidayRepository` | `data/repository/HolidayRepository.kt` | `lib/features/holidays/data/holiday_repository.dart` | P0 | DONE |

---

## 4. Home Screen

| Feature | Kotlin Location | Flutter Target | Priority | Status |
|---------|----------------|----------------|----------|--------|
| Today's Ethiopian date card | `ui/home/HomeScreen.kt` | `lib/features/home/widgets/today_date_card.dart` | P0 | DONE |
| Today's Gregorian date display | `ui/home/HomeScreen.kt` | `lib/features/home/widgets/today_date_card.dart` | P0 | DONE |
| Upcoming holiday banner | `ui/home/HomeScreen.kt` | `lib/features/home/widgets/upcoming_holiday_card.dart` | P1 | DONE |
| Quick action buttons | `ui/home/HomeScreen.kt` | `lib/features/home/widgets/quick_actions.dart` | P1 | DONE |
| Today's events list | `ui/home/HomeScreen.kt` | `lib/features/home/widgets/today_events_list.dart` | P1 | DONE |
| Daily Heritage proverb | `engine/DailyHeritageEngine.kt` | `lib/core/heritage/daily_heritage_engine.dart` | P2 | DONE |

---

## 5. Calendar Screen

| Feature | Kotlin Location | Flutter Target | Priority | Status |
|---------|----------------|----------------|----------|--------|
| Month view grid | `ui/calendar/CalendarScreen.kt` | `lib/features/calendar/widgets/month_view.dart` | P0 | DONE |
| Week view | `ui/calendar/CalendarScreen.kt` | `lib/features/calendar/widgets/week_view.dart` | P1 | DONE |
| Year view | `ui/calendar/CalendarScreen.kt` | `lib/features/calendar/widgets/year_view.dart` | P2 | DONE |
| Day view | `ui/calendar/CalendarScreen.kt` | `lib/features/calendar/widgets/day_view.dart` | P1 | DONE |
| Event dot markers on calendar | `ui/calendar/CalendarScreen.kt` | `lib/features/calendar/widgets/event_markers.dart` | P1 | DONE |
| `CustomDualDatePicker` | `ui/components/CustomDualDatePicker.kt` | `lib/shared/widgets/dual_date_picker.dart` | P1 | DONE |

---

## 6. Converter Screen

| Feature | Kotlin Location | Flutter Target | Priority | Status |
|---------|----------------|----------------|----------|--------|
| Date converter (Eth↔Greg) | `ui/converter/ConverterScreen.kt` | `lib/features/converter/tabs/date_converter_tab.dart` | P0 | DONE |
| Age calculator | `ui/converter/ConverterScreen.kt` | `lib/features/converter/tabs/age_calculator_tab.dart` | P1 | DONE |
| Date difference calculator | `ui/converter/ConverterScreen.kt` | `lib/features/converter/tabs/date_diff_tab.dart` | P1 | DONE |
| Geez numeral converter | `ui/converter/ConverterScreen.kt` | `lib/features/converter/tabs/geez_numeral_tab.dart` | P1 | DONE |
| Time converter (traditional↔standard) | `ui/converter/ConverterScreen.kt` | `lib/features/converter/tabs/time_converter_tab.dart` | P1 | DONE |
| Country time zone comparator | `ui/converter/ConverterScreen.kt` | `lib/features/converter/tabs/timezone_tab.dart` | P2 | DONE |
| Fasting guide | `ui/converter/ConverterScreen.kt` | `lib/features/converter/tabs/fasting_guide_tab.dart` | P2 | DONE |
| Bahire Hasab calculator | `ui/converter/ConverterScreen.kt` | `lib/features/converter/tabs/bahire_hasab_tab.dart` | P2 | DONE |
| Monthly saints display | `ui/converter/ConverterScreen.kt` | `lib/features/converter/tabs/monthly_saints_tab.dart` | P2 | DONE |
| Greeting card studio (AI) | `ui/converter/GreetingCardStudio.kt` | `lib/features/converter/tabs/greeting_card_tab.dart` | P3 | DONE |

---

## 7. Holidays Screen

| Feature | Kotlin Location | Flutter Target | Priority | Status |
|---------|----------------|----------------|----------|--------|
| Annual holidays list | `ui/holidays/HolidaysScreen.kt` | `lib/features/holidays/screens/holidays_screen.dart` | P0 | DONE |
| `HolidayDetailDialog` | `ui/holidays/HolidayDetailDialog.kt` | `lib/features/holidays/widgets/holiday_detail_dialog.dart` | P1 | DONE |
| `HolidayCardShareDialog` | `ui/holidays/HolidayCardShareDialog.kt` | `lib/features/holidays/widgets/holiday_card_share_dialog.dart` | P2 | DONE |
| `SetHolidayReminderDialog` | `ui/holidays/SetHolidayReminderDialog.kt` | `lib/features/holidays/widgets/set_holiday_reminder_dialog.dart` | P2 | DONE |

---

## 8. Events Screen

| Feature | Kotlin Location | Flutter Target | Priority | Status |
|---------|----------------|----------------|----------|--------|
| Events list view | `ui/events/EventsScreen.kt` | `lib/features/events/screens/events_screen.dart` | P0 | DONE |
| Create event (`AddEditEventDialog`) | `ui/events/AddEditEventDialog.kt` | `lib/features/events/widgets/add_edit_event_dialog.dart` | P0 | DONE |
| Edit event | `ui/events/AddEditEventDialog.kt` | `lib/features/events/widgets/add_edit_event_dialog.dart` | P0 | DONE |
| Delete event | `ui/events/EventsScreen.kt` | `lib/features/events/screens/events_screen.dart` | P0 | DONE |
| Mark event complete/incomplete | `ui/events/EventsScreen.kt` | `lib/features/events/screens/events_screen.dart` | P1 | DONE |
| Search events | `ui/events/EventsScreen.kt` | `lib/features/events/screens/events_screen.dart` | P1 | DONE |
| Filter events by category | `ui/events/EventsScreen.kt` | `lib/features/events/screens/events_screen.dart` | P1 | DONE |
| Recurrence setup | `ui/events/AddEditEventDialog.kt` | `lib/features/events/widgets/recurrence_picker.dart` | P1 | DONE |
| Reminder/notification setup | `ui/events/AddEditEventDialog.kt` | `lib/features/events/widgets/reminder_picker.dart` | P1 | DONE |
| Color picker for events | `ui/events/AddEditEventDialog.kt` | `lib/features/events/widgets/color_picker.dart` | P2 | DONE |

---

## 9. Settings Screen

| Feature | Kotlin Location | Flutter Target | Priority | Status |
|---------|----------------|----------------|----------|--------|
| Language selection (English/Amharic) | `ui/settings/SettingsScreen.kt` | `lib/features/settings/screens/settings_screen.dart` | P0 | DONE |
| Numeral type (Arabic/Geez) | `ui/settings/SettingsScreen.kt` | `lib/features/settings/screens/settings_screen.dart` | P1 | DONE |
| Theme mode (Light/Dark/AMOLED) | `ui/settings/SettingsScreen.kt` | `lib/features/settings/screens/settings_screen.dart` | P1 | DONE |
| Accent palette selection (4 palettes) | `ui/settings/SettingsScreen.kt` | `lib/features/settings/screens/settings_screen.dart` | P1 | DONE |
| First day of week | `ui/settings/SettingsScreen.kt` | `lib/features/settings/screens/settings_screen.dart` | P1 | DONE |
| Show fasting toggle | `ui/settings/SettingsScreen.kt` | `lib/features/settings/screens/settings_screen.dart` | P2 | DONE |
| Show monthly saints toggle | `ui/settings/SettingsScreen.kt` | `lib/features/settings/screens/settings_screen.dart` | P2 | DONE |
| Notifications toggle | `ui/settings/SettingsScreen.kt` | `lib/features/settings/screens/settings_screen.dart` | P1 | DONE |
| Calendar format preference | `ui/settings/SettingsScreen.kt` | `lib/features/settings/screens/settings_screen.dart` | P1 | DONE |

---

## 10. Notifications & Background

| Feature | Kotlin Location | Flutter Target | Priority | Status |
|---------|----------------|----------------|----------|--------|
| Event reminder notifications (exact alarm) | `notifications/NotificationScheduler.kt` | `lib/core/notifications/notification_scheduler.dart` | P1 | DONE |
| Boot-completed reschedule | `notifications/BootReceiver.kt` | `lib/core/notifications/boot_reschedule.dart` | P2 | DONE |
| `POST_NOTIFICATIONS` permission | `AndroidManifest.xml` | `AndroidManifest.xml` + runtime request | P1 | DONE |
| `SCHEDULE_EXACT_ALARM` permission | `AndroidManifest.xml` | `AndroidManifest.xml` + runtime request | P1 | DONE |
| `WAKE_LOCK` / `VIBRATE` permissions | `AndroidManifest.xml` | `AndroidManifest.xml` | P2 | DONE |

---

## 11. Home Screen Widgets & ICS

| Feature | Kotlin Location | Flutter Target | Priority | Status |
|---------|----------------|----------------|----------|--------|
| Full home screen widget (Android) | `widget/FullWidget.kt` | `lib/platform/widgets/full_widget/` + native | P2 | PENDING |
| Compact home screen widget (Android) | `widget/CompactWidget.kt` | `lib/platform/widgets/compact_widget/` + native | P2 | PENDING |
| ICS calendar export | `util/IcsExport.kt` | `lib/core/export/ics_exporter.dart` | P2 | DONE |
| `READ_CALENDAR` / `WRITE_CALENDAR` permissions | `AndroidManifest.xml` | `AndroidManifest.xml` + runtime request | P2 | DONE |

---

## 12. Firebase AI & Networking

| Feature | Kotlin Location | Flutter Target | Priority | Status |
|---------|----------------|----------------|----------|--------|
| Firebase initialization | `app/MyApplication.kt` | `lib/main.dart` | P1 | DONE |
| Firebase AI (Gemini) integration | `data/remote/FirebaseAiClient.kt` | `lib/data/remote/firebase_ai_client.dart` | P2 | PENDING |
| Greeting card AI generation | `ui/converter/GreetingCardStudio.kt` | `lib/features/converter/tabs/greeting_card_tab.dart` | P3 | PENDING |
| Retrofit → Dio HTTP client | `data/remote/ApiService.kt` | `lib/data/remote/api_service.dart` | P2 | DONE |
| Moshi → `freezed`+`json_serializable` DTOs | `data/model/*.kt` | `lib/data/models/*.dart` | P1 | DONE |

---

## 13. UI / Design System

| Feature | Kotlin Location | Flutter Target | Priority | Status |
|---------|----------------|----------------|----------|--------|
| Material3 theme wrapper | `ui/theme/AppTheme.kt` | `lib/core/theme/app_theme.dart` | P0 | DONE |
| GOLD_EMERALD accent palette (#E6A817) | `ui/theme/AppTheme.kt` | `lib/core/theme/palettes/gold_emerald.dart` | P0 | DONE |
| ROYAL_INDIGO accent palette | `ui/theme/AppTheme.kt` | `lib/core/theme/palettes/royal_indigo.dart` | P1 | DONE |
| CRIMSON accent palette | `ui/theme/AppTheme.kt` | `lib/core/theme/palettes/crimson.dart` | P1 | DONE |
| TERRACOTTA accent palette | `ui/theme/AppTheme.kt` | `lib/core/theme/palettes/terracotta.dart` | P1 | DONE |
| Light / Dark / AMOLED theme modes | `ui/theme/AppTheme.kt` | `lib/core/theme/app_theme.dart` | P1 | DONE |
| `EthiopianClockDialog` | `ui/components/EthiopianClockDialog.kt` | `lib/shared/widgets/ethiopian_clock_dialog.dart` | P2 | DONE |
| `CustomDualDatePicker` | `ui/components/CustomDualDatePicker.kt` | `lib/shared/widgets/dual_date_picker.dart` | P1 | DONE |
| `WidgetManagementDialog` | `ui/components/WidgetManagementDialog.kt` | `lib/shared/widgets/widget_management_dialog.dart` | P2 | DONE |
| Noto Serif Ethiopic font bundle | `assets/fonts/` | `assets/fonts/NotoSerifEthiopic.ttf` | P0 | DONE |

---

## 14. Onboarding

| Feature | Kotlin Location | Flutter Target | Priority | Status |
|---------|----------------|----------------|----------|--------|
| Multi-step onboarding flow | `ui/onboarding/OnboardingScreen.kt` | `lib/features/onboarding/screens/onboarding_screen.dart` | P1 | DONE |
| "Show only on first run" logic | `ui/onboarding/OnboardingScreen.kt` | `lib/features/onboarding/screens/onboarding_screen.dart` | P1 | DONE |


