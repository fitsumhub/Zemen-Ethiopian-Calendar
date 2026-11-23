# Ethiopian Calendar GitHub Audit — Abushakir / Kenat / kenat_py

**Audience:** EthioCal Pro (Flutter)  
**Audit date:** 2026-11-15  
**Method:** `api.github.com` (repo metadata, license, trees, issues) + `raw.githubusercontent.com` (source files). No `gh` auth.  
**Branches audited:** Abushakir `master`, kenat `main`, kenat_py `master`.

---

## Executive summary (Flutter reuse)

| Repo | SPDX | Depend as package? | Flutter note |
|------|------|--------------------|--------------|
| **Nabute/Abushakir** | MIT | **Pub only after Dart 3 fix** — current `sdk: '>=2.12.0 <3.0.0'` rejects Dart 3 / modern Flutter | Only native Dart option; fork or vendor + raise SDK upper bound |
| **MelakuDemeke/kenat** | MIT | **npm only** — not usable inside Flutter runtime | Best algorithm/reference + tests; **reimplement in Dart** |
| **MelakuDemeke/kenat_py** | MIT | **PyPI/`pip` only** | Python port of kenat; **reimplement**, do not bridge into Flutter |

All three MIT licenses allow commercial use, modification, and distribution if copyright/permission notices are preserved. No copyleft.

**Recommended EthioCal Pro path:** treat kenat (+ kenat_py) as the **algorithm and test oracle**, implement a Dart core (optionally starting from Abushakir’s RD/`EtDatetime` model after a Dart 3 migration), and do **not** assume Abushakir on pub.dev is production-ready as-is.

---

## 1. Nabute/Abushakir

### Identity

| Field | Value |
|-------|--------|
| URL | https://github.com/Nabute/Abushakir |
| Homepage / package | https://pub.dev/packages/abushakir |
| Language | Dart |
| Package type | Pure Dart library (`package:abushakir`) — no Flutter UI widgets in package |
| Version (repo `pubspec.yaml`) | `1.0.0` |
| Default branch | `master` |
| Stars / forks (API) | 33 / 12 |
| License file | `LICENSE` — Copyright (c) 2020 Nabute, Nahom |

### License (SPDX) and commercial implications

- **SPDX:** `MIT` (GitHub API `license.spdx_id`, LICENSE body matches MIT).
- **Commercial Flutter app:** Allowed — use, modify, sell, sublicense.
- **Obligation:** Keep copyright + permission notice in distributed copies / substantial portions (e.g. NOTICE / licenses section / OSS attribution screen).
- **Warranty:** AS IS; no liability from authors.

### Language / Flutter compatibility

- Declared SDK: `environment.sdk: '>=2.12.0 <3.0.0'` in `pubspec.yaml`.
- **Verification status:** **Confirmed blocker** for current Flutter (Dart 3.x). `pub get` will refuse resolution unless the constraint is widened (fork/vendor).
- Dependency: `equatable: ^2.0.5` only.
- Design: `EtDatetime` mirrors Dart `DateTime` API; intended for Flutter apps (docs mention companion app). No Flutter SDK dependency in the package itself.

### Core conversion algorithm

**Not named JDN in code**, but uses **Rata Die–style “fixed” day numbers** as in Dershowitz & Reingold *Calendrical Calculations* (package docs cite this explicitly in `lib/abushakir.dart`).

**Epoch / constants** — `lib/src/utils/constants.dart`:

| Constant | Value | Role |
|----------|-------|------|
| `_ethiopicEpoch` | `2796` | Ethiopic calendar RD epoch (docs: year 1 EE starts Aug 29, 8 CE Julian = R.D. 2796) |
| `_unixEpoch` | `719163` | RD of 1970-01-01 Gregorian (Unix epoch date) |
| `_ameteFida` | `5500` | Years BC for Amete Alem (Bahire Hasab) |
| `_tinteAbekte` | `11` | Abekte multiplier |
| `_tinteMetkih` | `19` | Metkih multiplier |

**Verification status of conversion constants:**

| Constant | Status | Notes |
|----------|--------|-------|
| `_ethiopicEpoch = 2796` | **Matches literature** | Same RD epoch as Calendrical Calculations Ethiopic; documented in library header |
| `_unixEpoch = 719163` | **Matches standard** | Common RD for Unix epoch date |
| Conversion formula | **Consistent with CC-style fixed-from-ethiopic** | See below; **not independently cross-checked against full kenat suite in this audit** |

**Key functions** — `lib/src/etDateTime.dart`, class `EtDatetime`:

```text
_fixedFromEthiopic(year, month, day) =
  _ethiopicEpoch - 1
  + 365 * (year - 1)
  + (year ~/ 4)
  + 30 * (month - 1)
  + day

_fixedFromUnix(ms) = _unixEpoch + (ms ~/ 86400000)

_dateToEpoch(...) = (_fixedFromEthiopic(...) - _unixEpoch) * dayMilliSec + time parts

year getter: ((4 * (fixed - _ethiopicEpoch) + 1463) ~/ 1461)
```

`lib/src/utils/convertor.dart` is **Geez numeral conversion only** (`ConvertToEthiopic`), not Gregorian↔Ethiopian date math.

### Leap year rule

```dart
bool get isLeap => year % 4 == 3;
```

(`EtDatetime.isLeap` in `lib/src/etDateTime.dart`)

Luke evangelist year (`ameteAlem % 4 == 3`) aligns with leap years in Bahire Hasab docs.

### Pagume handling

- Month index **13** = `ጷጉሜን` (`_months` in `constants.dart`).
- Day count in `ETC._monthRange` / `_monthDays` (`lib/src/calendar/calendar.dart`): **6 if leap, else 5**.
- Navigation: `prevMonth` wraps month 1 → previous year month 13; `nextMonth` is `month + 1` with **no wrap** from 13→1 (limitation).

### Bahire Hasab / movable feasts

**Yes — full traditional engine.** Class `BahireHasab` in `lib/src/calendar/bahireHasab.dart`.

| Member / method | Purpose |
|-----------------|--------|
| `ameteAlem` | `5500 + year` |
| `wenber` | `(ameteAlem % 19) - 1` (0 if negative) |
| `abekte` | `(wenber * 11) % 30` |
| `metkih` | `30` if wenber==0 else `(wenber * 19) % 30` |
| `yebealeMetkihWer()` | Metkih month: Meskerem if metkih>14 else Tikimt |
| `nenewe` | Nineveh date map `{month, date}` |
| `allAtswamat` | All movable feasts from `_yebealTewsak` offsets |
| `getSingleBealOrTsom(name)` | Single movable feast |
| `getEvangelist` / `getMeskeremOne` | Evangelist & New Year weekday |

**Movable feast Tewsak offsets** (`_yebealTewsak` in `constants.dart`):  
ነነዌ 0, ዓቢይ ጾም 14, ደብረ ዘይት 41, ሆሣዕና 62, ስቅለት 67, ትንሳኤ 69, ርክበ ካህናት 93, ዕርገት 108, ጰራቅሊጦስ 118, ጾመ ሐዋርያት 119, ጾመ ድህነት 121.

Same numeric offsets as kenat’s `movableHolidayTewsak`.

### Key source paths / types

| Path | Symbols |
|------|---------|
| `lib/abushakir.dart` | library entry; parts |
| `lib/src/etDateTime.dart` | `EtDatetime` |
| `lib/src/calendar/calendar.dart` | `ETC` |
| `lib/src/calendar/bahireHasab.dart` | `BahireHasab` |
| `lib/src/calendar/abushakir.dart` | abstract/calendar mixins (`EDT`, `Calendar`) |
| `lib/src/utils/constants.dart` | epochs, months, Tewsak maps |
| `lib/src/utils/convertor.dart` | `ConvertToEthiopic` |
| `lib/src/utils/calendar_exceptions.dart` | exceptions |

### Test coverage

**Single file:** `test/abushakir_test.dart`

| Area | Covered? |
|------|----------|
| `EtDatetime` constructors (params, year-only, parse, now, fromMillisecondsSinceEpoch) | Yes |
| Epoch fixture `1585731446021` → `2012-07-23 08:57:26.021` | Yes |
| `isAfter` / `isBefore` / `isAtSameMomentAs` | Thin |
| `BahireHasab` for **2011**: abekte, metkih, nenewe, all named movable feasts | Yes |
| Geez `ConvertToEthiopic` table | Yes |
| Bidirectional Gregorian↔Ethiopian matrix / Pagume edges / leap tables | **No** |
| Round-trip fuzz | **No** |

CI: `.github/workflows/dart.yml`.

### Known limitations / issues

- **Dart 3 incompatible** SDK constraint (critical for EthioCal Pro).
- No timezone/UTC model (documented).
- `ETC._monthRange` guard uses `month <= 1 && month >= 13` — **never true** (should be `||`); invalid months not rejected.
- `ETC.nextMonth` does not roll year after Pagume.
- Open PR-style issue #11 typo fix; historical closed #7 weekday bug.
- Conversion constants match CC literature, but **test suite does not prove** wide-range EC↔GC correctness against independent oracles.

### Depend vs reimplement

- **Can depend** via `abushakir` on pub.dev **only if** SDK constraint is fixed (upstream PR or local fork).
- MIT allows vendoring/reimplementation.
- For EthioCal Pro: treat as **Dart starting point**, not drop-in without maintenance.

---

## 2. MelakuDemeke/kenat

### Identity

| Field | Value |
|-------|--------|
| URL | https://github.com/MelakuDemeke/kenat |
| npm | https://www.npmjs.com/package/kenat (`kenat@4.0.0` in `package.json`) |
| Docs | https://kenat-doc.vercel.app/ , https://www.kenat.systems/ |
| Language | TypeScript (compiled via `tsup`) |
| Package type | Node/browser JS library (`engines.node: >=18`) |
| Default branch | `main` |
| Stars / forks (API) | 59 / 11 |
| License | MIT — Copyright (c) 2025 Melaku Demeke |

### License (SPDX) and commercial implications

- **SPDX:** `MIT`.
- Commercial reuse of algorithms / ported Dart code: **allowed** with notice retention.
- Keywords in `package.json` explicitly reference `"Abushakir"` (conceptual lineage, not a code dependency).

### Language / Flutter compatibility

- **Not Flutter-compatible as a dependency.** No Dart/Flutter binding.
- Use as **reference implementation + test vectors** for a Dart reimplementation.
- Rich surface: holidays, fasting, Geez numerals, Ethiopian time, month grid, Hijri helpers via ICU.

### Core conversion algorithm

**Not JDN for EC↔GC.** Two different strategies:

#### `toGC` — Ethiopian → Gregorian (`src/conversions.ts`)

1. `getGregorianDateOfEthiopianNewYear(ethYear)` (`src/utils.ts`):
   - `gregorianYear = ethiopianYear + 7`
   - New Year day = **12** if `isGregorianLeapYear(gregorianYear + 1)`, else **11**
   - Month always September
2. Add `(ethMonth - 1) * 30 + (ethDay - 1)` days via Gregorian day-of-year arithmetic.

#### `toEC` — Gregorian → Ethiopian (`src/conversions.ts`)

1. Validate calendar date; clamp range **1900-01-01 … 2100-12-31**.
2. Millisecond delta from base `Date.UTC(1971, 8, 12)` (= **1971-09-12** = Meskerem 1, 1964 EC).
3. Decompose with `fourYears = 1461 * dayMs`, `oneYear = 365 * dayMs`, then 30-day months.
4. `ethYear = 1964 + 4*cycles + remainingYears`.

**Constants / epochs used:**

| Concept | Value | Location | Verification |
|---------|-------|----------|--------------|
| New Year offset | `ethYear + 7` | `getGregorianDateOfEthiopianNewYear` | **Range-limited approximation** — works for modern years; **fails historically** (see issue #39) |
| New Year Sep 11/12 rule | leap of `gYear+1` | same | Standard modern rule; tested for 2015–2019 era |
| `toEC` base | 1971-09-12 / EC 1964-01-01 | `toEC` | **Confirmed by tests** |
| JDN | **Not used** for EC/GC | — | Hijri path uses `Intl` islamic calendar, not JDN |

**Verification status:** Modern fixtures in `tests/conversions.test.ts` are internally consistent (e.g. 2017-09-14 EC ↔ 2025-05-22 GC; Pagume leap/non-leap cases). Historical accuracy **outside ~1892–2091 EC** is **unverified / known broken** (open issue #39).

### Leap year rule

```ts
export function isEthiopianLeapYear(year: number): boolean {
  return year % 4 === 3;
}
```

(`src/utils.ts`)

### Pagume handling

- Month **13** named `Pagume` / `ጳጉሜ` (`src/constants.ts` `monthNames`).
- `getEthiopianDaysInMonth`: 13 → 6 if leap else 5.
- `toGC` validates `maxDay` for month 13 before convert.
- Tests cover Pagume 5/6 and year boundaries.

### Bahire Hasab / movable feasts

**Yes.** `src/bahireHasab.ts`:

| Export | Role |
|--------|------|
| `_calculateBahireHasabBase` | Core: ameteAlem, medeb, wenber, abektie, metqi, Nineveh |
| `getBahireHasab(year, {lang})` | Full result + `movableFeasts` |
| `getMovableHoliday(key, year)` | Offset from Nineveh via `movableHolidayTewsak` |

Also: `src/holidays.ts`, `src/fasting.ts`, fixed + Muslim holidays; `src/nigs.json` saint/nigs calendar data.

**Metqi 0→30 fix** shipped (issue #36 / PR #37); regression tests for 2006 E.C.

### Key source paths / symbols

| Path | Symbols |
|------|---------|
| `src/Kenat.ts` | class `Kenat` |
| `src/conversions.ts` | `toGC`, `toEC`, `toGCDate`, `fromDateToEC`, Hijri helpers |
| `src/utils.ts` | leap, DOY, new year helpers, `getWeekday` |
| `src/bahireHasab.ts` | `getBahireHasab`, `getMovableHoliday` |
| `src/constants.ts` | months, Tewsak, holidays, fasting metadata |
| `src/dayArithmetic.ts` | `addDays`, `diffBreakdown`, … |
| `src/holidays.ts` / `src/fasting.ts` | holiday/fasting APIs |
| `src/Time.ts` / `src/MonthGrid.ts` | Ethiopian time & month grid |
| `src/geezConverter.ts` | `toGeez`, `toArabic` |
| `src/index.ts` | public exports |

### Test coverage

Under `tests/` (Jest):

| File | Focus |
|------|--------|
| `conversions.test.ts` | EC↔GC including Pagume, leaps, range errors, base date |
| `bahireHasab.test.ts` | 2016 values, 2006 Metqi edge, Fasika, i18n |
| `Kenat.test.ts` | class API |
| `dayArtimetic.test.ts` | day arithmetic |
| `holidays.test.ts` / `fasting.test.ts` | holidays & fasting |
| `Time.test.ts` / `monthgrid.test.ts` / `geezConverter.test.ts` / `utils.test.ts` / `methodChaining.test.ts` / `print.test.ts` | supporting features |

CI: `.github/workflows/test.yml`, `release.yml`.

### Known limitations / issues

- **Open #39:** `toGC` off by ≥1 day outside Ethiopian years ~**1892–2091** (example: Yekatit 23, 1888 / Adwa → wrong Gregorian). Root cause: simplistic `ethYear+7` New Year mapping vs true historical leap alignment.
- `toEC` hard range **1900–2100**.
- `toEC` and `toGC` use **different algorithms**; must stay carefully synchronized (tests help).
- Closed bugs of note: Metqi 30 (#36), Nations day (#32/#33), `endOf('year')` leap (#35).
- Muslim dates depend on runtime ICU islamic calendar — can diverge from tabular Hijri (documented better in kenat_py).

### Depend vs reimplement

- **Depend as npm** for Node/web only.
- For Flutter EthioCal Pro: **must reimplement in Dart** (MIT permits). Prefer porting kenat’s tested vectors + either (a) RD/JDN engine for unlimited range, or (b) kenat New Year method with **documented safe range**.

---

## 3. MelakuDemeke/kenat_py

### Identity

| Field | Value |
|-------|--------|
| URL | https://github.com/MelakuDemeke/kenat_py |
| PyPI name | `kenat` (`pyproject.toml` version `2.0.0`) |
| Language | Python ≥3.8 |
| Package type | Pure Python library (`kenat/`) |
| Default branch | `master` |
| Stars / forks (API) | 1 / 0 |
| Issues | none open/closed via API |
| License | MIT — Copyright (c) 2025 Melaku Demeke |
| Homepage | https://www.kenat.systems/ |

### License (SPDX) and commercial implications

- **SPDX:** `MIT` (same commercial terms as kenat JS).
- Suitable as algorithm source for a Dart port; retain notices if copying substantial code/comments.

### Language / Flutter compatibility

- **Not usable inside Flutter.** No FFI/bridge shipped.
- Closest structural twin of kenat TS — good for validating a Dart port with `pytest`.

### Core conversion algorithm

#### `toGC` (`kenat/conversions.py`)

Same New Year rule as TS:

```text
gregorian_year = eth_year + 7
new_year_day = 12 if leap(gregorian_year + 1) else 11
result = date(gregorian_year, 9, new_year_day) + timedelta(days=(m-1)*30 + (d-1))
```

#### `toEC` — **cleaner than TS**

1. Start `eth_year = greg_year - 8`.
2. If `greg_date >= toGC(eth_year+1, 1, 1)` then `eth_year += 1`.
3. `days_diff` from that year’s New Year → month/day via `// 30` and `% 30`.
4. Same 1900–2100 guard.

**JDN helpers exist but are for Hijri**, not EC/GC:

- `_gregorian_to_jd`, `_jd_to_gregorian`, `_hijri_to_jd`, `_jd_to_hijri`
- Comment in `conversions.py` documents intentional **ICU vs tabular Hijri** divergence vs TS.

**Verification status:** Same New Year epoch rule as kenat → **same historical range limitation**. Round-trip fuzz in `tests/test_conversions.py` covers EC years 1900–2090 step 7. Constants of New Year rule: **operationally verified in-range**, **not historically absolute**.

### Leap year rule

```python
def is_ethiopian_leap_year(year):
    return year % 4 == 3
```

(`kenat/utils.py`)

### Pagume handling

- `get_ethiopian_days_in_month`: month 13 → 6/5.
- `toGC` rejects invalid Pagume days.
- Tests for Pagume 5/6.

### Bahire Hasab / movable feasts

**Yes** — `kenat/bahire_hasab.py`:

- `_calculate_bahire_hasab_base`
- `getBahireHasab`
- `getMovableHoliday`

Includes Metqi `0 → 30` correction (comment cites TS). Also `kenat/holidays.py`, `kenat/fasting.py`, `kenat/nigs.json`, `kenat/saints.py`.

### Key source paths / symbols

| Path | Symbols |
|------|---------|
| `kenat/kenat.py` | class `Kenat` |
| `kenat/conversions.py` | `toGC`, `toEC`, Hijri/JDN helpers |
| `kenat/utils.py` | leap, validation, new year |
| `kenat/bahire_hasab.py` | Bahire Hasab API |
| `kenat/day_arithmetic.py` | `addDays`, … |
| `kenat/constants.py` | months, Tewsak, holiday metadata |
| `kenat/__init__.py` | public exports |
| `pyproject.toml` | package metadata |

### Test coverage

Under `tests/`:

| File | Focus |
|------|--------|
| `test_conversions.py` | toGC/toEC + **round-trip fuzz** |
| `test_bahire_hasab.py` | Bahire Hasab |
| `test_kenat.py` | main class |
| `test_day_arithmetic.py` | arithmetic |
| `test_holidays.py` / `test_fasting.py` | holidays/fasting |
| `test_month_grid.py` / `test_time.py` / `test_geez_converter.py` / `test_utils.py` / `test_calendar_generation.py` | supporting |

No GitHub Actions workflows in tree (local pytest via optional deps).

### Known limitations / issues

- Same **New Year +7 / Sep 11–12** historical fragility as kenat (#39 applies conceptually).
- Hijri: tabular JDN ≠ JS ICU (documented accepted limitation).
- Bug tracker URL in `pyproject.toml` points at **kenat JS** issues, not kenat_py.
- Smaller community; keep TS as primary reference when they diverge.

### Depend vs reimplement

- Depend via **`pip install kenat`** for Python tooling/backends only.
- Flutter: **reimplement**; use tests as oracle alongside kenat TS.

---

## Cross-repo comparison

### Leap year (all three)

**`year % 4 == 3`** — consistent.

### Pagume (all three)

Month **13**, **5 days** normal / **6** leap — consistent.

### Bahire Hasab movable Tewsak offsets

Identical numeric set across Abushakir `_yebealTewsak` and kenat / kenat_py `movableHolidayTewsak` (0, 14, 41, 62, 67, 69, 93, 108, 118, 119, 121).

### Conversion models

| Aspect | Abushakir | kenat (TS) | kenat_py |
|--------|-----------|------------|----------|
| Intermediary | Fixed RD days | New Year DOY (`toGC`); 1461-day cycles (`toEC`) | New Year + timedelta (`toGC`); New Year diff (`toEC`) |
| Named JDN? | No (RD/fixed) | No for EC/GC | JDN only for Hijri |
| Ethiopic epoch constant | `_ethiopicEpoch = 2796` | Implicit via Sep New Year | Same as TS |
| Documented range | Very wide (fixed-day theory) | GC 1900–2100 for `toEC`; `toGC` historically weak | Same as TS |
| Flutter native | Yes (Dart) | No | No |

### Constant verification summary

| Constant / rule | Verdict |
|-----------------|---------|
| Abushakir `_ethiopicEpoch = 2796` | **Literature-aligned** (Calendrical Calculations / package docs) |
| Abushakir `_unixEpoch = 719163` | **Standard** Unix epoch RD |
| kenat/kenat_py `ethYear + 7` New Year | **Valid in modern window**; **not** historically universal (issue #39) |
| Sep 11 vs 12 (next Gregorian leap) | **Standard modern rule**; well tested for recent years |
| kenat `toEC` base 1971-09-12 = 1964-01-01 EC | **Test-confirmed** |
| Ethiopian leap `y % 4 == 3` | **Agreed by all three** |
| Movable Tewsak table | **Agreed by all three** |

---

## Implications for EthioCal Pro (Flutter)

1. **Do not** add current pub `abushakir` without fixing `sdk: <3.0.0`.
2. **Do not** expect to call kenat/kenat_py from Flutter; port algorithms.
3. Prefer a **single Dart conversion core** (RD/JDN-style like Abushakir, or kenat New Year with explicit supported year range + golden tests from kenat).
4. Port Bahire Hasab from kenat (cleaner API + Metqi edge tests) or Abushakir (already Dart); keep Tewsak table as shared constants.
5. MIT: attribute Nabute/Nahom and/or Melaku Demeke when shipping substantial derived code.
6. Add EthioCal Pro tests for: Meskerem 1 Sep 11/12 cases, Pagume 5/6, leap EC years, Bahire Hasab 2006 & 2011/2016 vectors, and at least one pre-1900 historical date if product needs it (kenat currently fails Adwa-era).

---

## Source fetch checklist (this audit)

Fetched and used:

- API: repo metadata, license blobs, recursive git trees, issues lists  
- Abushakir: `pubspec.yaml`, `lib/abushakir.dart`, `etDateTime.dart`, `calendar.dart`, `bahireHasab.dart`, `constants.dart`, `convertor.dart`, `test/abushakir_test.dart`  
- kenat: `package.json`, `conversions.ts`, `utils.ts`, `bahireHasab.ts`, `constants.ts`, `index.ts`, `tests/conversions.test.ts`, `tests/bahireHasab.test.ts`  
- kenat_py: `pyproject.toml`, `conversions.py`, `utils.py`, `bahire_hasab.py`, `__init__.py`, `tests/test_conversions.py`

Not exhaustively line-audited (large files): `Kenat.ts` / `kenat.py` class bodies, full `holidays`/`fasting` modules, `nigs.json` content — existence and roles confirmed via tree + imports.
