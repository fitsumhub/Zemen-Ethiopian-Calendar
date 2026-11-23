# Ethiopian Calendar GitHub Audit — Batch 3 (bahire-hasab / EOTCDevAPI / kenat_py)

**Audience:** EthioCal Pro (Flutter, MIT/commercial)  
**Audit date:** 2026-11-15  
**Method:** Shallow `git clone` into `.research_cache/` + source read. GitHub API used where `gh` was unavailable (no auth).  
**Branches audited:** `bahire-hasab` `main`, `EOTCDevAPI` `master`, `kenat_py` `master`.

---

## Executive summary (Flutter reuse)

| # | Repo | SPDX (GitHub) | Offline core? | Best use for Flutter |
|---|------|---------------|---------------|----------------------|
| 7 | [TadesseAngaw/bahire-hasab](https://github.com/TadesseAngaw/bahire-hasab) | **None** (header: redistribute **without modification**) | Yes — desktop Java Swing | **Reference / lineage only** — license blocks typical MIT-app vendoring+porting unless author grants permission |
| 8 | [natinael96/EOTCDevAPI](https://github.com/natinael96/EOTCDevAPI) | **MIT** | Yes — `ts/src/core/*` and `py/eotc/*` are dependency-free | **Primary oracle** for calendar, Bahire Hasab, fasts/feasts; vendor core or reimplement in Dart; optional hosted API |
| 9 | [MelakuDemeke/kenat_py](https://github.com/MelakuDemeke/kenat_py) | **MIT** | Yes — pure Python package | **Algorithm + test parity** with [kenat JS](https://github.com/MelakuDemeke/kenat); saints via `nigs.json`; reimplement in Dart |

**Movable holidays:** All three compute paschal-cycle dates from **year → Bahire Hasab chain → offsets** (not yearly lookup tables). Test fixtures use **specific years as golden vectors** only (e.g. 2016 EC), not production hardcoding.

**Date-type legend in this document**

| Tag | Meaning |
|-----|---------|
| **fixed** | Same Ethiopian `(month, day)` every year |
| **calculated** | Derived from Bahire Hasab / computus for the requested Ethiopian year |
| **approximate** | Hijri-based Muslim holidays mapped into Ethiopian year (algorithmic, not civil-calendar hardcode) |

---

## 7. TadesseAngaw/bahire-hasab

### Identity

| Field | Value |
|-------|--------|
| URL | https://github.com/TadesseAngaw/bahire-hasab |
| Language | **Java** (GitHub primary language) |
| Type | NetBeans Swing **desktop app** (not a library) |
| Default branch | `main` |
| Last push (API) | 2022-12-23 |
| Stars / forks (API) | 2 / 1 |

### License

| Item | Detail |
|------|--------|
| GitHub `license.spdx_id` | **`null`** — no LICENSE file in repo |
| File headers (e.g. `EthiopianCalendar.java`) | “You can use and redistribute **without modification**” — disclaimer of warranty |
| **MIT/commercial embed** | **Poor fit.** No explicit modification/derivative permission. Treat as **all-rights-reserved with narrow redistribution** until author clarifies. Porting formulas to Dart likely needs **direct permission**, not just header text. |

### README claims

- Bahire Hasab desktop Ethiopian calendar (2016 side project; author paused changes ~2017).
- Features: month view; lord’s feasts + notifications; fasting + notifications; **33 Feasts of St Mary**; EC↔GC converter; Arabic→Geez numbers.
- Attributes Bahire Hasab tradition to Pope Demetrius I of Alexandria (3rd century).
- Known issue: **custom** EC→Gregorian conversion can fail around January (no anchor/JDN reference).
- Roadmap: extract `EthiopianCalendar` as separate Java/Kotlin library (not done in repo).

### Bahire Hasab formulas (source: `EthiopianCalendar.java`)

Core class documents reliance on Abushakir, Henok, Bahire Hasab books. **38+ methods**; most movable results are **day-of-year integers** resolved via `getMonthFormat(day, year)`.

#### Awde Amet / cycle constants

| Symbol (code) | Rule | Status |
|---------------|------|--------|
| `AMETE_ALEM` | `5500` (years before Christ baseline) | **fixed constant** |
| Amete Alem (runtime) | `AMETE_ALEM + year` | **calculated** |
| `getRabit(year)` | `(AMETE_ALEM + year) / 4` | **calculated** (መተነ ራብዕ) |
| `getWengelawi(year)` | `(AMETE_ALEM + year) % 4` | **calculated** (evangelist cycle; Luke ⇒ leap) |

#### Wenber / Abekte / Metqi

Java uses a **532-cycle reduction** then derives Wenber (differs stylistically from kenat/EOTC `medeb % 19` but targets same tradition):

```text
wenber_raw = (year + AMETE_ALEM) % 532
reduce modulo sequence [228, 76, 19] while wenber > qemer
wenber = (wenber != 0) ? wenber - 1 : 18

abekte = (wenber * 11) % 30
metke  = (wenber == 0) ? 30 : (wenber * 19) % 30
```

| Item | Status |
|------|--------|
| Abekte (አብክቴ) | **calculated** |
| Metqi/Metke (መትቅ) | **calculated**; explicit `wenber==0 → 30` |

#### Tewsak

- Class `Tewsak.java`: weekday values **Sat=8 … Fri=2** (Bahire convention).
- `tewsakMatch(dayIndex)` maps Monday..Sunday (0..6) to those values.
- `getMebajaHamer(month, year)` combines `getFirstDay(year)`, `getMetke(year)`, month offset, and `tewsakMatch` — used for **Nineveh** anchor logic.

#### Movable feast chain (all **calculated** from `year`)

Anchored on `getNenewe(year)` then additive offsets (day-of-year):

| Feast (code / UI) | Computation | Offset from Nineveh (equivalent) |
|-------------------|-------------|----------------------------------|
| ጾመ ነነዌ `getNenewe` | Mebaja Hamer + Metqi branch logic | 0 |
| ዐቢይ ጾም `getAbeyTsome` | `nenewe + 14` | +14 |
| ደብረ ዘይት `getDebreZeit` | `abey + 27` | +41 |
| ሆሳዕና `getHosaena` | `abey + 48` | +62 |
| ስቅለት `getSiqlet` | `abey + 53` | +67 |
| ትንሣኤ `getTinsae` | `abey + 55` | +69 |
| ርክበ ካህናት `getRekbeKahinat` | `tinsae + 24` | +93 |
| ዕርገት `getErget` | `tinsae + 39` | +108 |
| ጰራቅሊጦስ `getPeraklitos` | `erget + 10` | +118 |
| ጾመ ሐዋርያት `getTsomeHawariyat` | `peraklitos + 1` | +119 |
| ጾመ ድህነት start `getTsomeDihnet` | `hawariyat + 2` | +121 |

Offsets match **kenat_py** / **EOTCDevAPI** `MOVABLE_FEASTS` when counting from Nineveh.

#### Fixed lord’s feasts & fast anchors (Ethiopian calendar)

| Name | Rule in code | Type |
|------|----------------|------|
| መስቀል Meskel | day **17** Meskerem (`getMeskel`) | **fixed** |
| ጥምቀት Timket | day-of-year **131** (`getTimket`) ≡ Tir 11 | **fixed** |
| ገና Gena | day-of-year **118** (John year) or **119** else (`getGena`) | **fixed** with evangelist nuance |
| ጾመ ጽጌ Tsge | Meskerem **26** (`getTsege`) | **fixed** |
| ጾመ ነቢያት Nebiyat | day-of-year **75** (Hidar 15) | **fixed** |
| ጾመ ፍልሰታ Filseta | day-of-year **331** (Nehase 1) | **fixed** |
| ደብረ ታቦር | day-of-year **343** in `Holiday.java` | **fixed** |
| ፅንሰት Annunciation | day-of-year **209** in UI | **fixed** |
| Sibket / Birhan / Nolawi | relative to `getGena` / `getNolawi` | **calculated** from Gena |

#### Pre-paschal minor feasts

Computed from movable chain: `getSibket`, `getBirhan`, `getNolawi`, `getGad` (eve fast if Timket Wed/Fri).

### Fasting periods (UI: `Fasting.java`)

Eight named fasts: ጽጌ ጾም, ጾመ ነቢያት, ጾመ ጋድ, ጾመ ነነዌ, ዐቢይ ጾም, ጾመ ሐዋርያት, ጾመ ድህነት, ጾመ ፍልሰታ — all wired to `EthiopianCalendar` methods above (**calculated** or **fixed** per row in fixed-feast table).

### Saints / St Mary data

| Asset | Location | Notes |
|-------|----------|-------|
| Monthly saint strings (30 entries) | `EthiopianCalendar.SAINTS[]` | Amharic comma-separated names per day-of-month |
| 33 Marian feasts | `SaintMarry.java` + resources | README claim; UI module, not separate JSON |
| No `nigs.json` equivalent | — | In-code / UI only |

### Movable holiday computation vs hardcoding

- **No yearly date tables found** in `src/` (grep for hardcoded 201x/202x calendar dates: none).
- User enters **year**; all paschal dates recomputed.

### Tests / verification

| Tests | Status |
|-------|--------|
| Unit/integration tests | **None** in repository |
| Author README | Acknowledges conversion bugs; no golden-year list |

### Offline vs API

| Mode | Support |
|------|---------|
| Offline | **Full** — standalone desktop JAR workflow via NetBeans |
| Network API | **None** |

### Flutter / MIT embedding notes

- **Algorithm value:** High — complete Bahire chain in one class.
- **License value:** Low for commercial Flutter — **no modification** clause conflicts with normal app development.
- **Conversion risk:** Prefer JDN-based converters (kenat/EOTC) over this app’s `toGregorianDate` for production.

---

## 8. natinael96/EOTCDevAPI

### Identity

| Field | Value |
|-------|--------|
| URL | https://github.com/natinael96/EOTCDevAPI |
| Homepage | https://natinael96.github.io/EOTCDevAPI/ |
| Languages | **TypeScript** (Worker) + **Python** (FastAPI); GitHub language skew toward Pages HTML |
| Default branch | `master` |
| License | **MIT** (`LICENSE`, Copyright 2026 EOTCDev) |

### README claims (selected)

- Open REST API: conversion, fasting, feasts, Bahire Hasab, Gitsawe/Sinksar lectionary bridge.
- **No auth, no DB** on public deployment; rate-limited Worker.
- Dual implementation **byte-identical** behaviour via shared `spec/conformance.json` (9,154 vectors) and `spec/responses.json`.
- **Fasika verified two ways** (Bahire Hasab vs Alexandrian computus) for **1800–2200 EC**.
- Core modules (`ts/src/core/*`, `py/eotc/*`) have **zero dependencies** — intended for vendoring without HTTP.

### Bahire Hasab (`py/eotc/bahirehasab.py`, port of `ts/src/core/bahirehasab.ts`)

Documented chain:

```text
Amete Alem → Medeb → Wenber → Abekte & Metqi → Mebaja Hamer
→ (weekday + Tewsak) → Nineveh JDN → +offset movable feasts
```

| Step | Formula | Status |
|------|---------|--------|
| Amete Alem | `AMETE_FIDA + year` (5500 + year) | **calculated** |
| Medeb | `amete_alem % 19` | **calculated** |
| Wenber | `18 if medeb==0 else medeb-1` | **calculated** |
| Abekte | `(wenber * 11) % 30` | **calculated** |
| Metqi | `(wenber * 19) % 30`; **0 ⇒ day 30** before month pick | **calculated** |
| Mebaja Hamer | `month 1 if effective_metqi > 14 else 2`, `day = effective_metqi` | **calculated** |
| Nineveh | Same day-number **four months later** + `TEWSAK_NINEVEH[weekday]` (JDN) | **calculated** |

#### `MOVABLE_FEASTS` offsets from Nineveh (all **calculated** per year)

| Key | Amharic | English | Offset (days after Nineveh) |
|-----|---------|---------|----------------------------|
| `nineveh` | ጾመ ነነዌ | Fast of Nineveh | 0 |
| `abiy_tsome` | ዓቢይ ጾም | Great Lent begins | 14 |
| `debre_zeit` | ደብረ ዘይት | Mount of Olives (mid-Lent) | 41 |
| `hosanna` | ሆሳዕና | Palm Sunday | 62 |
| `siklet` | ስቅለት | Good Friday | 67 |
| `fasika` | ትንሣኤ | Easter | 69 |
| `rikbe_kahnat` | ርክበ ካህናት | Assembly of the Priests | 93 |
| `erget` | ዕርገት | Ascension | 108 |
| `peraklitos` | በዓለ ጰራቅሊጦስ | Pentecost | 118 |
| `tsome_hawaryat` | ጾመ ሐዋርያት | Apostles' Fast begins | 119 |
| `tsome_dihnet` | ጾመ ድህነት | Weekly fast season marker | 121 |

`alexandrian_easter_jdn(gregorian_year)` — independent Julian computus cross-check (**verification only**, not user-facing primary).

### Fasting (`py/eotc/fasts.py`)

| Key | Name | Rule | Type |
|-----|------|------|------|
| `tsome_nebiyat` | Prophets' Fast (Advent) | Hidar 15 → Tahsas 28 eve | **fixed** |
| `gahad_gena` | Christmas Eve fast | Tahsas 28 | **fixed** |
| `gahad_timket` | Epiphany Eve fast | Tir 10 | **fixed** |
| `tsome_nenewe` | Nineveh | `ninevehJDN` .. +2 | **calculated** |
| `abiy_tsome` | Great Lent | Nineveh+14 → Fasika-1 | **calculated** |
| `tsome_hawaryat` | Apostles' Fast | day after Pentecost → Hamle 5 | **calculated** + **fixed** end |
| `tsome_filseta` | Assumption fast | Nehase 1–16 | **fixed** |

**ጾመ ድህነት:** Wednesdays/Fridays unless `fast_free_season` (Fasika→Pentecost inclusive) or `feastOverride` (Gena, Timket on Wed/Fri).

### Fixed feasts & commemorations (`py/eotc/feasts.py`)

**`FIXED_FEASTS`** (Ethiopian month/day — **fixed**):

| Key | Month | Day | English |
|-----|-------|-----|---------|
| `enkutatash` | 1 | 1 | Ethiopian New Year |
| `meskel` | 1 | 17 | Finding of the True Cross |
| `gena` | 4 | 29 | Nativity |
| `timket` | 5 | 11 | Theophany |
| `kana_zegelila` | 5 | 12 | Wedding at Cana |
| `kidane_mihret` | 6 | 16 | Covenant of Mercy |
| `giyorgis` | 8 | 23 | St George |
| `lideta` | 9 | 1 | Nativity of the Virgin Mary |
| `petros_pawlos` | 11 | 5 | Sts Peter and Paul |
| `gabriel` | 11 | 19 | St Gabriel |
| `buhe` | 12 | 13 | Transfiguration |
| `filseta` | 12 | 16 | Assumption of the Virgin Mary |

**`MONTHLY_COMMEMORATIONS`:** recurring saints on days 1,5,7,12,14,16,19,21,23,24,27,29 each month (**fixed** day-of-month).

### Gitsawe / Sinksar / Bible data layers

From `web/docs/data-sources.html` + README:

| Layer | License / status | Flutter note |
|-------|------------------|--------------|
| Calendar + Bahire + fasts/feasts rules | **MIT** code | Safe to embed |
| Gitsawe fixed cycle transcription | Project MIT bundle; scan provenance | Large JSON; movable sections **not** fully transcribed (`fixed_candidate_only`) |
| Sinksar summaries | Apache-2.0 dataset; narrative text **withheld** | IDs/lists OK; full hagiography text not redistributed |
| Bible verse text | **CC BY-NC-ND** — **not** bundled in API | References only — **incompatible** with typical commercial MIT app redistribution of full text |
| Seasonal gitsawe import snapshot | MIT `gitsawe` dataset (frozen) | Candidate data; not yet wired to date resolution |

### Movable holidays vs hardcoding

- All movables from `bahire_hasab(year)` + offset table — **no per-year CSV**.
- `spec/conformance.json` stores expected outputs for regression (**not** runtime lookup).

### Tests / verification

| Suite | Coverage |
|-------|----------|
| `py/tests/test_conformance.py` + `ts/test/conformance.test.ts` | Shared 9,154 vectors: conversion, Bahire, fasts, feasts, Geez, seasons |
| Fasika cross-check | Bahire JDN vs `alexandrian_easter_jdn(year+8)` **1800–2200 EC** |
| README | 73,415-day EC↔JDN round-trip; weekday checks; Nineveh Monday; Hosanna Sunday; Siklet Friday |
| `make test` | Regenerates fixtures + dual parity |

### Offline vs API

| Mode | Support |
|------|---------|
| **Offline** | **Yes** — import `py/eotc` or TS core without Worker |
| **API** | Optional — `https://eotcdev-api.natinael-96.workers.dev/v1/...` (documented in README) |

### Flutter / MIT embedding

| Component | Compatibility |
|-----------|---------------|
| Calendar math, Bahire, fast/feast catalog in code | **MIT — compatible** with attribution |
| Hosted API as backend | Compatible; adds network + rate-limit dependency |
| Bundled Bible full text from project | **Not compatible** (NC-ND) for typical commercial app |
| Sinksar narrative | Not in repo for redistribution |

**Practical path:** Port or transpile `ts/src/core` logic to Dart; use conformance JSON as golden tests; treat API as optional sync layer.

---

## 9. MelakuDemeke/kenat_py

### Identity

| Field | Value |
|-------|--------|
| URL | https://github.com/MelakuDemeke/kenat_py |
| Homepage | https://www.kenat.systems/ |
| Language | **Python 3** |
| Package | PyPI `kenat` (README) |
| License | **MIT** (`LICENSE`) |
| Lineage | Port of [MelakuDemeke/kenat](https://github.com/MelakuDemeke/kenat) (JS/TS) |

### README claims

- Full EC↔GC, Bahire Hasab, holidays (Christian/Muslim/public), fasting, saints (**Nigs**), Geez, time, grids — **no external dependencies** for core calendar.
- Examples cite **computed** Fasika for 2017 EC (illustration only — not a lookup table).

### Bahire Hasab (`kenat/bahire_hasab.py`)

Same computational model as kenat JS (and **aligned** with EOTC offsets):

| Field | Formula |
|-------|---------|
| `amete_alem` | `5500 + ethiopian_year` |
| `metene_rabiet` | `amete_alem // 4` |
| `medeb` | `amete_alem % 19` |
| `wenber` | `18 if medeb==0 else medeb-1` |
| `abektie` | `(wenber * 11) % 30` |
| `metqi` | `30 if raw_metqi==0 else raw_metqi` |
| Beale Metqi month | `1 if metqi>14 else 2` |
| Nineveh | `mebaja_hamer` + month rollover + `addDays` from anchor |
| Movable feasts | `addDays(nineveh_date, MOVABLE_HOLIDAY_TEWSAK[key])` |

#### `MOVABLE_HOLIDAY_TEWSAK` (`kenat/constants.py`) — **calculated**

| Internal key | Tewsak offset from Nineveh |
|--------------|----------------------------|
| `NINEVEH` | 0 |
| `ABIY_TSOME` | 14 |
| `DEBRE_ZEIT` | 41 |
| `HOSANNA` | 62 |
| `SIKLET` | 67 |
| `TINSAYE` (Fasika) | 69 |
| `RIKBE_KAHNAT` | 93 |
| `ERGET` | 108 |
| `PARACLETE` | 118 |
| `TSOME_HAWARYAT` | 119 |
| `TSOME_DIHENET` | 121 |

Public API keys in `movableFeasts`: camelCase (`fasika`, `abiyTsome`, …).

#### Tewsak weekday map (`TEWSAK_MAP`)

Sunday 7 → Saturday 8 (matches Java `Tewsak` ordering).

### Fixed holidays (`FIXED_HOLIDAYS` in `constants.py`) — all **fixed**

| Key | Month | Day | Notes |
|-----|-------|-----|-------|
| `enkutatash` | 1 | 1 | |
| `meskel` | 1 | 17 | |
| `beherbehereseb` | 3 | 29 | State holiday |
| `gena` | 4 | 29 | |
| `timket` | 5 | 11 | |
| `martyrsDay` | 6 | 12 | |
| `adwa` | 6 | 23 | |
| `labour` | 8 | 23 | |
| `patriots` | 8 | 27 | |

Muslim: `eidFitr`, `eidAdha`, `moulid` via Hijri search in `holidays.py` — **approximate** mapping into Ethiopian year (not EC fixed dates).

### Fasting (`kenat/fasting.py`)

Uses `getBahireHasab` movable feast dates for Nineveh, Abiy Tsome (ends Siklet), Hawaryat, etc.

| Fast key | Rule | Type |
|----------|------|------|
| `ABIY_TSOME` | `abiyTsome` → `siklet` | **calculated** |
| `NINEVEH` | start + 2 days | **calculated** |
| `TSOME_HAWARYAT` | start movable → Hamle 4 | **calculated** + **fixed** end |
| `TSOME_NEBIYAT` | month 3 day 15 → month 4 day 28 | **fixed** |
| `FILSETA` | Nehase 1–14 | **fixed** |
| `RAMADAN` | Hijri month 9 range | **approximate** |
| `TSOME_DIHENET` | Wed/Fri excluding 50 days post-Fasika | **calculated** rule |

### Saints data

| File | Role |
|------|------|
| `kenat/nigs.json` | Orthodox monthly commemorations by day 1–30; entries include `name`, `description`, `major`, `negs` (months where major) |
| `kenat/saints.py` | Lazy loader via `importlib.resources` |

### Movable holidays vs hardcoding

- `getMovableHoliday(key, year)` always runs Bahire base for that **year**.
- Tests assert **2016** and **2006** as golden years — implementation is still formula-driven.

### Tests / verification

| Path | What it checks |
|------|----------------|
| `tests/test_bahire_hasab.py` | 2016 medeb/wenber/metqi/nineveh; movable Fasika/Abiy; **2006 metqi=0→30** regression |
| `tests/test_fasting.py` | 2016 fast periods; Tsome Dihnet vs Easter/Pentecost window |
| `tests/test_holidays.py` | Fixed + movable keys; `getMovableHoliday` |
| `tests/test_conversions.py`, `test_calendar_generation.py`, etc. | EC/GC, grids |

**No** 1800–2200 computus sweep in this repo (present in EOTCDevAPI).

### Offline vs API

| Mode | Support |
|------|---------|
| Offline | **Full** — `pip install kenat` / vendor source |
| API | **None** built-in |

### Flutter / MIT embedding

| Item | Verdict |
|------|---------|
| License | **MIT — compatible** with commercial Flutter + modification |
| Approach | Reimplement `bahire_hasab.py` + `constants.py` rules in Dart; optionally mirror tests |
| vs EOTCDevAPI | kenat_py is **lighter** and matches Melaku’s kenat ecosystem; EOTC has **stronger** conformance scale + feast catalog + lectionary |

---

## Cross-repo comparison

### Bahire Hasab equivalence

| Aspect | bahire-hasab (Java) | EOTCDevAPI | kenat_py |
|--------|---------------------|------------|----------|
| Amete Alem | 5500 + year | 5500 + year | 5500 + year |
| Wenber derivation | 532-qemer reduction | medeb % 19 | medeb % 19 |
| Metqi zero | `wenber==0 → 30` | `metqi==0 → day 30` | `raw==0 → 30` |
| Nineveh anchor | Mebaja Hamer arithmetic | JDN + `TEWSAK_NINEVEH` | `nineveh_date` + day arithmetic |
| Paschal offsets | Same +14…+121 chain | Same offset table | Same `MOVABLE_HOLIDAY_TEWSAK` |
| Independent Easter check | None | Alexandrian 1800–2200 EC | None |

### Hardcoded yearly movable dates?

| Repo | Verdict |
|------|---------|
| bahire-hasab | **No** — year-parameter methods only |
| EOTCDevAPI | **No** — conformance JSON is test artifact |
| kenat_py | **No** |

### License summary for Flutter MIT commercial app

| Repo | Embed algorithms | Embed saints/lectionary text | Modify/port to Dart |
|------|------------------|------------------------------|---------------------|
| bahire-hasab | **Risk** — no SPDX; no-modification header | In-code strings only | **Seek permission** |
| EOTCDevAPI | **Yes** (MIT core) | MIT metadata; Bible full text **no**; Sinksar narrative **no** | **Yes** |
| kenat_py | **Yes** (MIT) | `nigs.json` MIT | **Yes** |

---

## Suggested Flutter integration order

1. **Primary logic source:** EOTCDevAPI `ts/src/core` or kenat_py `kenat/` (MIT, tested).
2. **Golden tests:** EOTC `spec/conformance.json` + kenat_py pytest cases (2016, 2006 metqi edge).
3. **Supplementary UI strings / 33 Marian feasts:** bahire-hasab only after **license clarification** — do not assume MIT.
4. **Optional online:** EOTCDevAPI `/v1/*` for Gitsawe/Sinksar bridges without bundling NC-ND Bible text.

---

## Audit limitations

- Did not run `make test` / `pytest` locally in this pass (sources read from clone).
- Did not diff Java Wenber 532-reduction against EOTC Wenber for all years (tradition-aligned; EOTC suite is stronger evidence for medeb path).
- Muslim holiday dates depend on Hijri conversion quality in kenat_py — treat as **approximate** relative to official proclamations.