# Calendar Accuracy Test Report

**Date:** 2026-11-15  
**Engine:** EthioCal Pro `EthiopianDateConverter` + `BahireHasab` + `GeezNumeral` + `HolidayEngine`  
**QC run:** `flutter test` on calendar suites — **All tests passed** (54 assertions in batched run)

## 1. Independent conversion cross-check (EOTCDevAPI)

| Suite | Result |
|-------|--------|
| `spec/conformance.json` → `cases.conversion` | **4936 / 4936 match** EthioCal JDN both ways |
| Sampled asset vectors (`calendar_test_vectors.json`) | Round-trip EC↔JDN↔GC in `test/calendar_dataset_test.dart` |
| Epoch | `ethiopianEpochJdn = 1724221` confirmed vs ethiopic-primitives + EOTC |

## 2. In-repo engine verification (`test/engine_verification_test.dart`)

| Section | Result |
|---------|--------|
| Historical anchors (Adwa, Liberation, Derg, Millennium, Genna/Timket, Pagume 6) | **Pass** |
| Day-by-day odometer Gregorian 1900–2100 vs Dart `DateTime` | **Pass** |
| Pagume / leap / New Year boundaries | **Pass** |
| Bahire Hasab Fasika vs Meeus Julian computus (+13d) | **Pass** |
| Genna/Timket fasting exceptions | **Pass** |

## 3. Dataset / core / Bahire / engines suites

| File | Result |
|------|--------|
| `test/calendar_dataset_test.dart` | Pass — JSON parse, Geez examples, fixed holiday ids |
| `test/calendar_core_test.dart` | Pass — months, leap cycle, 100-year round-trips |
| `test/bahire_hasab_test.dart` | Pass — medeb/wenber, feast weekdays across centuries |
| `test/engines_test.dart` | Pass — holidays 2017, Genna leap rule, fasting, heritage |

## 4. Geez numerals

| Suite | Result |
|-------|--------|
| EOTC `cases.geez` (3007) | **3006 match / 1 mismatch** |
| Mismatch | `n=353319553` multi-፼ stacking — outside calendar year domain |
| Dataset examples 1…10000 | Pass |

## 5. Holidays / fasting QC

| Check | Result |
|-------|--------|
| Duplicate holiday ids for year 2017 | None |
| Fixed holiday dataset ↔ `HolidayEngine` | All ids present (Nations Day, Martyrs, Labour, …) |
| Movable feasts | Computed via Bahire Hasab — **not hardcoded yearly dates** |
| Islamic events | Tagged `approximate_calculated` (lunar sighting) |
| Regional Irreecha/Ashenda | Tagged approximate |

## 6. Cross-implementation mismatches investigated

| Topic | Finding | Decision |
|-------|---------|----------|
| Genna day | kenat always Tahsas 29; EthioCal `year % 4 == 0 → 28` | **EthioCal** (always Gregorian 7 Jan 1901–2099) |
| kenat #39 historical toGC | Drift outside ~1892–2091 EC | Prefer EthioCal JDN |
| EC 2000-01-01 | Some docs say 11 Sep 2007; vector/oracle **12 Sep 2007** | EthioCal + EOTC + Millennium anchor |
| Majority vote | Not used as authority | Meeus + EOTC + public anchors preferred |

## 7. Unsupported / caution ranges

| Topic | Guidance |
|-------|----------|
| kenat historical toGC (#39) | Do not use kenat outside modern window as authority |
| Pre-Gregorian-reform civil dates | EthioCal uses proleptic Gregorian JDN — document for ancient civil display |
| Islamic civic holidays | Prefer officially announced dates when available |
| dakidarts RapidAPI | Excluded from offline core |

## 8. Commands run (this QC pass)

```text
flutter test test/engine_verification_test.dart \
  test/calendar_dataset_test.dart \
  test/calendar_core_test.dart \
  test/bahire_hasab_test.dart \
  test/engines_test.dart
→ All tests passed!
```
