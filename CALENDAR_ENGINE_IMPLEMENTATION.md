# Calendar Engine Implementation

**Date:** 2026-11-15  
**Status:** Research complete · Data catalog shipped · Engine retained & verified · Holiday list enriched

## Architecture

```text
┌─────────────────────────────────────────────────────────┐
│ Flutter UI (Calendar / Converter / Holidays / Agenda)   │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│ HolidayEngine  │  Providers  │  CalendarDataCatalog      │
└───────┬───────────────────────────┬─────────────────────┘
        │                           │ JSON assets (offline)
┌───────▼───────────────────────────▼─────────────────────┐
│ EthiopianDateConverter (JDN)  │  BahireHasab             │
│ LeapYearCalculator            │  GeezNumeral             │
│ EthiopianTimeConverter        │  Month/Weekday enums     │
└─────────────────────────────────────────────────────────┘
```

### Why not replace with Kenat or Abushakir?

| Option | Verdict |
|--------|---------|
| **Abushakir pub** | MIT + Dart, but SDK `<3.0.0` incompatible with current Flutter without a maintained fork |
| **kenat npm / kenat_py** | Excellent tests; not Dart; known historical conversion issue |
| **EthioCal JDN** | Already offline, Dart 3, **4936/4936** independent match, large in-repo verification |

**Conclusion:** Keep EthioCal calculation modules; use open-source repos as oracles and data taxonomy sources.

## Files added / updated

| Path | Role |
|------|------|
| `assets/data/ethiopian_calendar/*` | Verified / tagged datasets |
| `lib/core/calendar/calendar_data_catalog.dart` | Offline JSON loader |
| `lib/core/holidays/holiday_engine.dart` | + Nations Day, Martyrs Day, Labour Day |
| `lib/main.dart` | Warm-up catalog at startup |
| `pubspec.yaml` | Register data assets |
| `test/calendar_dataset_test.dart` | Vector + schema + holiday QC |
| `GITHUB_CALENDAR_RESOURCE_AUDIT.md` | Repo audit |
| `ETHIOPIAN_CALENDAR_RESEARCH_MATRIX.md` | Capability matrix |
| `CALENDAR_DATA_PROVENANCE.md` | Provenance |
| `CALENDAR_ACCURACY_TEST_REPORT.md` | Accuracy results |
| `research_notes/Ethiopian calendar GitHub audit/*` | Deep audit notes |

## Integration map (UI)

| Feature | How it uses the engine/data |
|---------|-----------------------------|
| Main calendar | Existing JDN selection + holiday dots from `HolidayEngine` |
| Month / year views | Unchanged math; richer holiday set |
| Date converter | Same converter; catalog available for labels |
| Holiday calendar | `getHolidaysForYear` + saints |
| Fasting | `isFastingDay` / detailed fasting |
| Bahire Hasab | `BahireHasab.calculate` |
| Search / Agenda / reminders | Existing event DB untouched |
| Ethiopian time / Geez | Existing converters; Geez examples in JSON |

## Database safety

No schema changes. User events, preferences, and reminders are untouched.

## Provenance theme (added)

| Piece | Path |
|-------|------|
| Color tokens | `AppColors.verify*` + `CalendarDataTheme` in `lib/core/theme/app_colors.dart` |
| Badge widget | `lib/features/shared/components/calendar_provenance_badge.dart` |
| Settings panel | Calendar Accuracy section + Sources bottom sheet (`sources.json`) |

Verified vs approximate data stay visually distinct so UI never presents Hijri estimates as verified civil facts.

## Follow-ups (optional)

1. Import selected MIT `sinq-gitsawe` feast keys as an extended commemorations pack.  
2. Show provenance badges on individual Islamic holiday rows in Holidays tab.  
3. Optional gazette import pipeline for `officially_announced` Islamic dates.
