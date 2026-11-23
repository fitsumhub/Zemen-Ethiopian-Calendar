# EthioCal Pro — Bug Tracker & Edge Case Log (BUG_TRACKER.md)

**Document Version:** 1.0.0  
**Status:** Active  
**Lead Engineer:** Senior Flutter Architect & QA Specialist

---

## 1. Resolved Issues & Edge Cases

| Issue ID | Severity | Category | Description | Root Cause | Resolution | Verification Status |
|---|---|---|---|---|---|---|
| **BUG-001** | High | Calendar Engine | Pagumē 6 on Luke leap year calculation offset. | In standard non-leap years, Pagumē has 5 days. In Luke years (`year % 4 == 3`), Pagumē has 6 days. Certain conversion algorithms assumed Gregorian leap rules or miscalculated the epoch shift. | Implemented astronomical Julian Day Number (`JDN = 1724221`) converter in `EthiopianDateConverter`. Tested with 100-year continuous round-trip loop. | ✅ FIXED & VERIFIED |
| **BUG-002** | High | Computus / Bahire Hasab | Movable feast dates shifting outside canonical days of the week. | Nenewe must always be Monday; Fasika must always be Sunday; Siklet must always be Friday; Hosanna must always be Sunday. | Added canonical day-of-week assertions across all 11 movable feasts from 1900 to 2100 in `BahireHasabTest`. | ✅ FIXED & VERIFIED |
| **BUG-003** | Medium | UI / Static Analysis | Undefined method `_buildMonthGridCard` & unused import in `calendar_screen.dart`. | Method call was slightly mismatched during PageView refactor and unused local variable `rowCount` was flagged. | Refactored `_buildMonthGridCard` and aligned parameters. Verified `flutter analyze` passes with 0 issues. | ✅ FIXED & VERIFIED |
| **BUG-004** | Medium | Theming | AMOLED pure black theme displaying gray elevated surfaces. | Material 3 default surface tints in dark mode applied a subtle white overlay on Card and NavigationBar components. | Explicitly configured `surfaceTint: Colors.transparent` and `colorScheme.surface: Color(0xFF000000)` in `AppTheme.getTheme()` for AMOLED mode. | ✅ FIXED & VERIFIED |
| **BUG-005** | High | Android Native | Android 14+ / 15+ exact alarm permission restrictions. | `SCHEDULE_EXACT_ALARM` requires user granting or proper fallback on API 33+. | Configured `canScheduleExactNotifications()` check in `NotificationScheduler` and declared `SCHEDULE_EXACT_ALARM` in `AndroidManifest.xml`. | ✅ FIXED & VERIFIED |
| **BUG-006** | Low | Numeral System | Ge'ez numeral conversion for 10,000 (`፼`) and multi-digit compound numbers. | Traditional Ge'ez numbers use single and compound glyphs for tens and hundreds without a zero glyph. | Implemented recursive/chunked Ge'ez converter in `GeezNumeral` supporting 1 through 99,999. Tested extensively. | ✅ FIXED & VERIFIED |
| **BUG-007** | Medium | Back Navigation | Android system back button exiting app directly from deep tabs (e.g. Settings or Holidays). | Default Flutter back handler terminates the activity if current route cannot pop. | Wrapped `MainNavigationShell` in `PopScope` to redirect back button to Home tab (`_currentTabIndex = 0`) before exiting. | ✅ FIXED & VERIFIED |

---

## 2. Monitored Potential Edge Cases

1. **Midnight Rollover for Active Screens:**
   - *Scenario:* User leaves app open across midnight (23:59 to 00:00).
   - *Mitigation:* App listens to stream-based time ticker and auto-refreshes `todayEthiopianProvider`.
2. **First Day of the Week Configuration:**
   - *Scenario:* Ethiopian tradition often considers Sunday (*Ehud*) the first day, but some business users prefer Monday (*Segno*).
   - *Mitigation:* User configurable toggle in `SettingsScreen`, with the calendar grid dynamically adjusting cell offsets and column headers.
3. **Offline Font Rendering:**
   - *Scenario:* Devices without system Ethiopic fonts showing empty square boxes ("tofu") for Ge'ez text.
   - *Mitigation:* Bundling high-quality Ethiopic typography locally in the assets.
