# Ethiopian Calendar GitHub Audit — Batch 1

**Repos:** [Nabute/Abushakir](https://github.com/Nabute/Abushakir) · [MelakuDemeke/kenat](https://github.com/MelakuDemeke/kenat) · [yinebebt/ethiocal](https://github.com/yinebebt/ethiocal)

**Audit date:** 2026-11-15  
**Method:** `api.github.com` + `raw.githubusercontent.com` (no authenticated `gh`; `gh auth login` not available in this environment).  
**Default branches inspected:** Abushakir `master`, kenat `main`, ethiocal `main`.

**Note on user assumption:** `yinebebt/ethiocal` is **Go** (Fyne GUI + CLI + importable packages), not Java/Android. Android builds ship as a **pre-built APK** (Go/Fyne), per README.

**JDN / `1723856`:** None of these three repos define **Julian Day Number `1723856`** (Ethiopic JDN epoch used in some liturgical APIs). Abushakir uses **R.D. / “fixed”** constants; kenat and ethiocal use **procedural** conversion without named JDN for EC↔GC.

---

## Cross-repo snapshot (Flutter offline embedding)

| Repo | Language | Package name | SPDX | Latest GitHub release (API) | Flutter embed? |
|------|----------|--------------|------|-----------------------------|----------------|
| Abushakir | Dart | `abushakir` (`pubspec.yaml` **1.0.0**) | MIT | **v0.1.4** (tag; **differs** from `pubspec` 1.0.0 — **unverified** which pub.dev publishes) | **Yes (MIT Dart)** — only native candidate; blocked by `sdk: '>=2.12.0 <3.0.0'` on `master` without fork |
| kenat | TypeScript | `kenat` (`package.json` **4.0.0** on `main`) | MIT | **v3.2.0** (release **behind** `main` **4.0.0**) | **No** — reference / test oracle; reimplement in Dart |
| ethiocal | Go | `github.com/yinebebt/ethiocal` | MIT | **v1.3.1** | **No** — Go runtime; port `dateconverter` + `bahirehasab` logic if needed |

---

# 1. Nabute/Abushakir

## Overview

- **Purpose (README):** Dart package for Ethiopian calendar / datetime and Bahire Hasab (movable fasts and holidays). Claims implementation via **Unix epoch milliseconds** (Gregorian bridge), not “conversion from another calendar” in the API sense—though internally it uses **fixed day numbers** tied to Unix ms.
- **Homepage:** https://pub.dev/packages/abushakir  
- **Stars / forks (API, 2026-11-15):** 33 / 12  
- **Topics:** `unix-epoch`, `pagumen`, `hasabe-bahir`, etc.

## License

- **SPDX:** `MIT` (GitHub API `license.spdx_id`; `LICENSE` file).
- **Copyright (LICENSE):** Nabute, Nahom (2020).

## Structure

```
lib/
  abushakir.dart              # library entry, Calendrical Calculations doc
  src/
    etDateTime.dart           # EtDatetime
    calendar/
      calendar.dart           # ETC
      bahireHasab.dart        # BahireHasab
      abushakir.dart          # EDT, Calendar mixins
    utils/
      constants.dart
      convertor.dart          # Geez numerals only
      calendar_exceptions.dart
test/abushakir_test.dart
example/example.dart
```

**Exports (README / `lib/abushakir.dart`):** `EtDatetime`, `ETC`, `BahireHasab`, `ConvertToEthiopic`.

## Algorithms

| Concern | Implementation | Key symbols |
|---------|----------------|-------------|
| Eth↔Greg (date) | R.D.-style **fixed** count ↔ Unix ms | `EtDatetime._fixedFromEthiopic`, `_fixedFromUnix`, `_dateToEpoch`, getters `year`/`month`/`day` |
| Leap year | `year % 4 == 3` | `EtDatetime.isLeap` |
| Pagume | Month 13; 5/6 days in `ETC` month iterators | `ETC._monthRange`, `_monthDays` |
| Weekday | Amete Alem + rabit formula; month weekday from `yearFirstDay` | `EtDatetime._yearFirstDay`, `weekday` getter |
| Bahire Hasab | Classic medeb/wenber/abekte/metkih → Nineveh → Tewsak offsets | `BahireHasab` class |
| Movable feasts / fasting | Offsets from Nineveh (`_yebealTewsak`) | `getSingleBealOrTsom`, `allAtswamat` |
| Geez numerals | Divide-and-map to `geezNumbers` | `ConvertToEthiopic` |
| Ethiopian time | **Partial / unverified** — docs mention **6-hour** offset for realtime clock; **no** 12h day/night API like kenat | `EtDatetime.clock()` stream |

**Gregorian interop (README):** `EtDatetime.fromMillisecondsSinceEpoch(gregorian.millisecondsSinceEpoch)` and reverse via `DateTime.fromMillisecondsSinceEpoch(ethiopian.moment)` — same instant, Ethiopian fields from `fixed`.

## Data files

- **None** (all logic in Dart; constants in `constants.dart`).

## Tests

- **File:** `test/abushakir_test.dart` only.
- **Covers:** `EtDatetime` constructors/parse/epoch fixture `1585731446021`; thin comparison tests; **`BahireHasab` year 2011** (abekte, metkih, nenewe, all named movable feasts); `ConvertToEthiopic` table.
- **Does not cover:** EC↔GC matrix, Pagume edge round-trips, leap tables vs external oracle, Bahire Hasab across multiple years.
- **CI:** `.github/workflows/dart.yml`.

## Limitations

| Item | Source |
|------|--------|
| Dart 3 / modern Flutter | `pubspec.yaml` `sdk: '>=2.12.0 <3.0.0'` |
| No timezone / UTC model | `EtDatetime` class docs |
| `ETC._monthRange` guard `month <= 1 && month >= 13` is never true (likely should be `\|\|`) | `calendar.dart` |
| `ETC.nextMonth` no year rollover after month 13 | `calendar.dart` |
| Open issue **#11** typo fixes (not algorithmic) | GitHub issues API |
| Historical weekday bugs referenced in community (e.g. closed #7) — **not re-verified here** | unverified |

## Flutter suitability

- **License:** MIT — commercial offline app OK with notice.
- **Language:** Pure Dart + `equatable`; **best direct dependency** for Flutter if SDK constraint is widened or package is vendored/forked.
- **Offline:** Yes — no network in core library.

## Key constants / formulas

**From `lib/src/utils/constants.dart` (verified raw):**

```dart
const int _ameteFida = 5500;
const int _tinteAbekte = 11;
const int _tinteMetkih = 19;
const int _ethiopicEpoch = 2796;   // R.D. epoch (CC Ethiopic year 1)
const int _unixEpoch = 719163;     // R.D. of 1970-01-01
```

**From `lib/src/etDateTime.dart` (verified raw):**

```dart
// fixed Ethiopian civil date → R.D.-style count
static int _fixedFromEthiopic(int year, int month, int day) {
  return (_ethiopicEpoch - 1 + 365 * (year - 1) + (year ~/ 4) + 30 * (month - 1) + day);
}

static int _fixedFromUnix(int ms) => (_unixEpoch + (ms ~/ 86400000));

static int _dateToEpoch(...) =>
  ((_fixedFromEthiopic(...) - _unixEpoch) * dayMilliSec) + time parts;

int get year => ((4 * (fixed - _ethiopicEpoch) + 1463) ~/ 1461);

bool get isLeap => year % 4 == 3;
```

**Bahire Hasab Tewsak offsets (`_yebealTewsak`):** ነነዌ 0, ዓቢይ ጾም 14, ደብረ ዘይት 41, ሆሣዕና 62, ስቅለት 67, ትንሳኤ 69, ርክበ ካህናት 93, ዕርገት 108, ጰራቅሊጦስ 118, ጾመ ሐዋርያት 119, ጾመ ድህነት 121.

**JDN `1723856`:** **not present** in this repo.

---

# 2. MelakuDemeke/kenat

## Overview

- **Purpose (README):** Comprehensive **JavaScript/TypeScript** Ethiopian calendar: EC↔GC, arithmetic, formatting, Bahire Hasab, holidays, fasting, Geez numerals, Ethiopian time, month grids; **zero runtime dependencies**.
- **npm:** https://www.npmjs.com/package/kenat  
- **Docs:** https://kenat-doc.vercel.app/ , https://www.kenat.systems/  
- **Stars / forks (API):** 59 / 11  
- **Version on `main`:** `4.0.0` (`package.json`); latest **GitHub release tag** via API: **v3.2.0** (also tag **v4.0.0** exists on repo — release metadata may lag).

## License

- **SPDX:** `MIT` (GitHub API; `LICENSE` — Copyright Melaku Demeke 2025).

## Structure

```
src/
  Kenat.ts              # main facade
  conversions.ts        # toEC, toGC, Hijri helpers
  utils.ts              # leap, new year, weekday, validation
  bahireHasab.ts        # getBahireHasab, getMovableHoliday
  constants.ts          # months, holidays, tewsak, nigs.json data
  holidays.ts, fasting.ts, geezConverter.ts, Time.ts, MonthGrid.ts, ...
  nigs.json             # holiday / liturgical data (~36 KB)
tests/*.test.ts       # Jest (12 test files on main)
```

**Named exports (README):** `Kenat`, `toEC`, `toGC`, `getBahireHasab`, `getHolidaysForYear`, `toGeez`, `Time`, etc.

## Algorithms

| Concern | Implementation | Key symbols |
|---------|----------------|-------------|
| Eth → Greg | Ethiopian New Year in Sep + day offset via Gregorian DOY | `toGC`, `getGregorianDateOfEthiopianNewYear` |
| Greg → Eth | Ms since `Date.UTC(1971, 8, 12)` decomposed in 1461-day cycles + 30-day months | `toEC` |
| Leap year | `year % 4 === 3` | `isEthiopianLeapYear` |
| Pagume | `getEthiopianDaysInMonth` → 5 or 6; validated in `toGC` | `conversions.ts`, `utils.ts` |
| Weekday | Convert to GC then `Date.getDay()` (0=Sun) | `getWeekday` |
| Bahire Hasab | Same medeb/wenber pipeline as Abushakir; Nineveh anchor | `_calculateBahireHasabBase`, `getBahireHasab` |
| Movable feasts | Tewsak days after Nineveh | `getMovableHoliday`, `movableHolidayTewsak` in `constants.ts` |
| Fasting / holidays | `fasting.ts`, `holidays.ts`, `nigs.json` | `getFastingPeriod`, `getHolidaysForYear`, … |
| Geez numerals | `geezConverter.ts` | `toGeez`, `toArabic` |
| Ethiopian time | 12h + day/night; sunrise anchor **6 AM** | `Time.fromGregorian`, `Time.toGregorian` |
| Hijri (Muslim holidays) | `Intl.DateTimeFormat('en-TN-u-ca-islamic')` + search | `getHijriYear`, `hijriToGregorian` — **not** tabular JDN |

### `toGC` core (verified `src/conversions.ts` + `src/utils.ts`)

```ts
// New Year of Ethiopian year ethYear:
gregorianYear = ethiopianYear + 7;
newYearDay = isGregorianLeapYear(gregorianYear + 1) ? 12 : 11; // September
daysSinceNewYear = (ethMonth - 1) * 30 + ethDay - 1;
// ... add to Gregorian day-of-year ...
```

### `toEC` core (verified)

```ts
const baseDate = new Date(Date.UTC(1971, 8, 12)); // 1964-01-01 EC
const fourYears = 1461 * 86400000;
// decompose diff → ethYear = 1964 + 4*cycles + remainingYears; month/day from 30-day chunks
```

**Range:** `toEC` rejects Gregorian dates outside **1900-01-01 … 2100-12-31**. `toGC` does **not** mirror that bound.

## Data files

- `src/nigs.json` — baked holiday / liturgical metadata (verified in tree).
- `assets/img/` — branding only.

## Tests

**Jest** (`tests/`, CI `.github/workflows/test.yml`), includes:

| File | Focus (from filenames + sampled `conversions.test.ts`) |
|------|--------------------------------------------------------|
| `conversions.test.ts` | `toGC`/`toEC` modern years, Pagume 5/6, bounds 1900–2100 |
| `bahireHasab.test.ts` | Bahire Hasab |
| `holidays.test.ts`, `fasting.test.ts` | Holidays / fasts |
| `Time.test.ts` | Ethiopian time |
| `geezConverter.test.ts`, `ethiopianNumberConverter.test.ts` | Numerals |
| `Kenat.test.ts`, `dayArtimetic.test.ts`, `monthgrid.test.ts`, `utils.test.ts`, `methodChaining.test.ts`, `print.test.ts` | API surface |

**Gap:** No exhaustive historical EC↔GC; open **#39** documents failures outside ~1892–2091 EC for `toGC`.

## Limitations

| Item | Source |
|------|--------|
| **`toGC` wrong outside ~1892–2091 EC** (e.g. Adwa 1888-06-23; 2092 Meskerem 1) | Open issue **#39** with repro on `kenat@4.0.0` |
| `toGC` / `toEC` **not perfect inverses** near 2100 boundary | Issue #39 |
| New Year rule uses **Gregorian leap of year+1** — wrong when Gregorian century rules diverge from Ethiopian 4-year cycle | Issue #39 analysis |
| Hijri via ICU `Intl` — environment-dependent | `conversions.ts` comments / README |
| **Cannot run inside Flutter** without port | architecture |

## Flutter suitability

- **License:** MIT — porting allowed.
- **Use in Flutter:** Treat as **algorithm + test oracle**; run Jest vectors when validating Dart core. Do not embed JS engine solely for kenat unless explicitly desired.

## Key constants / formulas

| Constant / anchor | Value | Notes |
|-------------------|-------|--------|
| `toEC` base | `1971-09-12` UTC = EC `1964-01-01` | Verified in `conversions.ts` |
| Ethiopian leap | `year % 4 === 3` | `isEthiopianLeapYear` |
| New Year (toGC helper) | Sep 11 or 12 | Tied to `isGregorianLeapYear(ethYear + 8)` |
| Bahire `ameteAlem` | `5500 + ethiopianYear` | `bahireHasab.ts` |
| Ethiopian time | `hour - 6` normalized; day/night periods | `Time.ts` |

**JDN / `1723856`:** **not used** for EC↔GC in kenat.

**Sample verified movable-offset block (`bahirehasab.go` in ethiocal matches kenat semantics):** Nineveh + 14 → Great Lent, etc. (see ethiocal section for numeric offsets).

---

# 3. yinebebt/ethiocal

## Overview

- **Purpose (README):** Ethiopian calendar tool (ባሕረ-ሐሳብ): **date conversion**, **fasting & festival dates** (EOTC-oriented), plus **Fyne GUI**, **CLI** (`ethiocal-cli`), and **Go library** imports.
- **Platforms:** Desktop (macOS/Linux/Windows), Android APK, CLI binaries — **Release v1.3.1**.
- **Stars / forks (API):** 24 / 1  
- **Module:** `github.com/yinebebt/ethiocal` (`go.mod` Go **1.26**).

## License

- **SPDX:** `MIT` (GitHub API; `LICENSE`).

## Structure

```
dateconverter/     # Ethiopian(), Gregorian(), startDayOfEthiopian()
bahirehasab/       # NewFestival(), models, fasting table
cmd/ethiocal-cli/  # bahir, convert subcommands
gui/               # Fyne UI
main.go            # GUI entry
```

**Library imports (README):**

```go
"github.com/yinebebt/ethiocal/bahirehasab"
"github.com/yinebebt/ethiocal/dateconverter"
```

## Algorithms

| Concern | Implementation | Key symbols |
|---------|----------------|-------------|
| Eth ↔ Greg | **Month-walking** from Ethiopian New Year in Gregorian calendar; handles **1582 reform gap** and pre-1582 Julian alignment | `Ethiopian`, `Gregorian`, `startDayOfEthiopian` |
| Leap year | `(year-1)%4==3` for Pagume; `(year%4==3)` in validation | `ethiopian.go`, `helper.go` |
| Pagume | Month slot 10 in internal arrays → 5 or 6 | `ethiopianMonths[10]` |
| Weekday | Computed in Bahire Hasab via tinte qemer | `getYear`, `Weekday` types in `bahirehasab` |
| Bahire Hasab | Medeb/wenber/metiq → Nineveh (`Nenewie`) + fixed offsets | `NewFestival`, `getBasic`, `getFasting` |
| Movable feasts | Offsets from Nineveh (same numbers as Abushakir/kenat) | `offsetAbiy=14`, … `offsetDihnet=121` |
| Fixed fasts | e.g. Nebiyat Hidar 15, Filseta Nehase 1, Gehad before Timket Tir 11 | `getFasting` |
| Geez numerals | **Not in library** (GUI may display Ethiopic font) | unverified in core pkgs |
| Ethiopian time | **Not implemented** in `dateconverter` / `bahirehasab` | — |

### `startDayOfEthiopian` (verified `helper.go`)

```go
newYearDay := (year / 100) - (year / 400) - 4
if (year-1)%4 == 3 { newYearDay++ }  // Sep 12 vs 11 pattern in modern era
```

### Leap / Pagume (verified `ethiopian.go` / `helper.go`)

```go
// Pagume length
if ethiopianYear%4 == 3 { ethiopianMonths[10] = 6 } else { ethiopianMonths[10] = 5 }
```

### Bahire Hasab offsets (verified `bahirehasab.go`)

```
Abiy 14, DebreZeit 41, Hosanna 62, Siklet 67, Tinsaye 69,
RkbeKahnat 93, Erget 108, Peraklitos 118, Hawariyat 119, Dihnet 121
```

Source comment links EOTC MK material.

## Data files

- **None** for conversion (pure Go arithmetic).
- `gui/NotoSansEthiopic.ttf` — UI font asset.

## Tests

| Package | File | Coverage (verified) |
|---------|------|---------------------|
| `dateconverter` | `ethiopian_test.go` | Round-trip pairs incl. **1582-10-04/15** reform; Pagume leap 2015-13-6; invalid pagume / reform gap |
| `bahirehasab` | `bahirehasab_test.go` | **2016** full festival/fasting tables; **2006** metiq=30 edge; `Date.AddDays` |
| CLI | `cmd/ethiocal-cli/convert_test.go` | thin CLI convert (**unverified detail** — not fully read) |

**CI:** `.github/workflows/ci.yml`.

## Limitations

| Item | Source |
|------|--------|
| No open issues (API **0**) at audit time | GitHub issues API |
| Conversion algorithm complexity — harder to prove equivalence to RD/JDN engines without cross-lib golden tests | audit note |
| **No** Ethiopian time, Geez numerals, or broad public-holiday catalog in core libs (unlike kenat) | tree inspection |
| Go / Fyne — not linkable from Flutter | architecture |
| Historical accuracy beyond tested fixtures — **unverified** vs Abushakir RD or kenat suite | unverified |

## Flutter suitability

- **License:** MIT — porting formulas allowed.
- **Embed:** **No** direct embed; useful as **second oracle** for conversion + Bahire (especially **1582** handling, which kenat `toEC` does not special-case).

## Key constants / formulas

- **No JDN / `1723856`** in source reviewed.
- **Gregorian reform:** rejects `1582-10-05` … `1582-10-14` in `Ethiopian()`.
- **Ethiopian year mapping:** `ethiopianYear := gregorianYear - 8` (with edge logic near new year).

**Representative conversion test (verified `ethiopian_test.go`):**

- GC `2025-02-02` ↔ ET `2017-05-25`
- GC `1582-10-04` ↔ ET `1575-02-07`; GC `1582-10-15` ↔ ET `1575-02-08`

---

## Appendix: Feature matrix

| Feature | Abushakir | kenat | ethiocal |
|---------|-----------|-------|----------|
| Eth↔Greg | Fixed/R.D. + Unix | New Year + DOY / ms cycles | Month-walking + reform |
| Named JDN `1723856` | No | No | No |
| Pagume | Yes | Yes | Yes |
| Bahire Hasab | Yes | Yes | Yes |
| Fixed + movable feasts | Movable focus | Full holiday system | Fasting/festival struct |
| Geez numerals | Yes | Yes | No (core) |
| Ethiopian time | Minimal docs | `Time` class | No |
| Unit tests | Single file, narrow | Broad Jest suite | Go tests, focused |
| Best for Flutter | **Dependency (Dart)** | **Port + tests** | **Port + 1582 checks** |

---

## Sources consulted

- https://api.github.com/repos/Nabute/Abushakir (and `/git/trees/master?recursive=1`, `/releases/latest`, issues)
- https://api.github.com/repos/MelakuDemeke/kenat (and tree, issue #39)
- https://api.github.com/repos/yinebebt/ethiocal (and tree, releases)
- Raw files under `raw.githubusercontent.com` paths cited above

**Researcher skill file** at requested path: **not found** in this environment (read failed); audit used primary GitHub sources only.