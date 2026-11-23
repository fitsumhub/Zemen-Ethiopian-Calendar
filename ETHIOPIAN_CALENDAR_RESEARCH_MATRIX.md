# Ethiopian Calendar Research Matrix

**Date:** 2026-11-15  
**Companion:** `GITHUB_CALENDAR_RESOURCE_AUDIT.md`, `assets/data/ethiopian_calendar/sources.json`

Legend — **Verification:** `verified` (independent match) · `cross_checked` · `reviewed` · `excluded` · `not_copied`

| Capability | EthioCal Pro | Abushakir | kenat / kenat_py | yinebebt | mukerem | ethiopic-primitives | Tadesse BH | EOTCDevAPI | dakidarts |
|------------|--------------|-----------|------------------|----------|---------|---------------------|------------|------------|-----------|
| EC→GC / GC→EC | `EthiopianDateConverter` JDN | RD fixed | New-Year tabular | Tabular Sep offset | ICU ordinal | JDN 1724221 | Java (buggy) | JDN + conformance | API only |
| Leap year | `y % 4 == 3` | same | same | same | same | same | same | same | API |
| Pagume 5/6 | `EthiopianDate.daysInMonthFor` | yes | yes | tested | yes | yes | yes | `year_shape` | API |
| Weekday | JDN-based DOW | yes | yes | yes | yes | yes | yes | in vectors | API |
| Bahire Hasab | `BahireHasab` | `bahireHasab.dart` | `bahireHasab.ts/.py` | `NewFestival` | no | no | rich UI | `bahirehasab` + vectors | no |
| Movable feasts | offsets from Nenewe | yes | yes | yes | no | no | yes | `movable_feasts` | no |
| Fasting periods | `HolidayEngine.isFastingDay` | partial | `fasting.ts` | offsets | no | no | UI | `fasts` + status vectors | no |
| Fixed holidays | `HolidayEngine` + JSON | limited | `holidays.ts` | computed | no | no | UI | `fixed_feasts` | no |
| Saints days | `monthlySaints` + JSON | no | limited | no | no | no | saints screens | commemorations / Sinksar | no |
| Geez numerals | `GeezNumeral` | yes | `geezConverter` | no | no | yes | no | 3007 vectors | no |
| Ethiopian time | `EthiopianTimeConverter` | yes | Time module | no | datetime | no | no | no | timezone API |
| Calendar grids | Flutter UI | example | month grid tests | GUI | no | examples | MiniCalendar | no | no |
| Date arithmetic | engine diff helpers | EtDatetime | day arithmetic tests | `Date.AddDays` | yes | yes | yes | JDN | API |
| Offline | **yes** | yes | yes | yes | yes | yes | yes | **yes (cores)** | **no** |
| License | project | MIT | MIT | MIT | MIT | MIT | no-mod | MIT+data | MIT file / SaaS |
| Flutter fit | **native** | SDK block | reimplement | reimplement | reimplement | reimplement | no | vendor TS→Dart ideas | no |

## Per-capability detail (EthioCal primary)

| Capability | Source file | Function / class | Tests | License | Limitations | Verification |
|------------|-------------|------------------|-------|---------|-------------|--------------|
| Conversion | `lib/core/calendar/ethiopian_date_converter.dart` | `ethiopianToJulianDay`, `gregorianToJulianDay`, round-trips | `test/engine_verification_test.dart`, `test/calendar_dataset_test.dart` | Project | Astronomical JDN; civil use 1900–2100 audited | **verified** vs EOTC 4936/4936 |
| Leap / Pagume | `leap_year_calculator.dart`, `ethiopian_date.dart` | `isEthiopianLeapYear`, `daysInMonthFor` | engine verification §§2–3 | Project | — | **verified** |
| Weekday | `ethiopian_date_converter.dart` | `getDayOfWeek` | anchors + odometer | Project | 1=Mon…7=Sun | **verified** |
| Bahire Hasab | `bahire_hasab.dart` | `BahireHasab.calculate` | Meeus Easter cross-check | Project | Traditional computus | **verified** (1900–2100 Fasika) |
| Movable feasts | `bahire_hasab.dart` + JSON rules | `movableFeasts` | engine + dataset | Project | Not hardcoded yearly | **verified** |
| Fasting | `holiday_engine.dart` | `isFastingDay`, canonical fasts | fasting portions of engine tests | Project | Weekly fast exceptions | **verified** / EOTC status vectors available |
| Fixed holidays | `holiday_engine.dart` + `fixed_holidays.json` | `getHolidaysForYear` | dataset test | Project | Genna day rule differs from kenat | **verified** (Jan 7 anchors) |
| Saints | `holiday_engine.monthlySaints` + JSON | day-of-month table | dataset present | Project | Commemorative, not full Sinksar text | **verified** tradition table |
| Geez | `geez_numeral.dart` | `toGeez` | dataset examples; EOTC 3006/3007 | Project | Multi-፼ edge at huge n | **verified** for calendar range |
| Ethiopian time | `ethiopian_time_converter.dart` | day/night 12h | existing unit coverage | Project | Traditional reckoning | **cross_checked** |
| Islamic | `holiday_engine._hijriToJdn` + JSON | Mawlid/Eid/Ramadan | — | Project | Lunar sighting → **approximate_calculated** | tagged approximate |
| Regional | Irreecha/Ashenda rules + JSON | first Sunday after Meskel | — | Project | Local variance | **approximate_rule** |

## Mismatch investigations

| Topic | Observation | Resolution |
|-------|-------------|------------|
| Genna day | kenat always Tahsas 29; EthioCal uses 28 when `year % 4 == 0` | EthioCal correct for Gregorian 7 Jan (tested) |
| Conversion outside modern window | kenat #39 | EthioCal JDN matched EOTC across 4936 cases including historical |
| Geez huge integers | 1 mismatch at n=353319553 | Irrelevant to calendar years; documented |
| Majority vote | Not used | Independent Meeus + EOTC + historical anchors preferred |
