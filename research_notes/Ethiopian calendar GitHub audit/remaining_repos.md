# Ethiopian Calendar GitHub Audit — Remaining Repos

**Audience:** EthioCal Pro (Flutter)  
**Audit date:** 2026-11-15  
**Method:** `api.github.com` (repo metadata, license, recursive trees) + `raw.githubusercontent.com` (source, data, manifests). No `gh` auth.  
**Repos audited:** yinebebt/ethiocal, mukerem/ethiocalendar, dakidarts/ethiopian-calendar-api, Yaredt/ethiopic-primitives, TadesseAngaw/bahire-hasab, natinael96/EOTCDevAPI.

Companion note: `abushakir_kenat.md` (Abushakir / kenat / kenat_py).

---

## Executive summary (Flutter reuse)

| Repo | SPDX / terms | Depend as package? | Flutter note |
|------|----------------|--------------------|--------------|
| **yinebebt/ethiocal** | MIT | Go module / CLI / Fyne GUI only | **Reimplement** Bahire Hasab + conversion from Go; good algorithm reference + tests |
| **mukerem/ethiocalendar** | MIT | PyPI/`pip` only | ICU/Beyene–Kudlek ordinal conversion; **reimplement in Dart**; no BH/holidays |
| **dakidarts/ethiopian-calendar-api** | MIT on LICENSE file | **RapidAPI only** — no app source in repo | **API-only**; not offline; cannot vendor algorithms |
| **Yaredt/ethiopic-primitives** | MIT | Not on npm/PyPI yet (pre-1.0) | JS `EthiopianDate`/`toJdn` is best JS oracle; Python wraps another lib; **no Bahire Hasab** |
| **TadesseAngaw/bahire-hasab** | **No SPDX**; file header: redistribute **without modification** | Java Swing desktop only | Strong BH + saints **logic** reference; license blocks modified reuse; conversion has known bugs |
| **natinael96/EOTCDevAPI** | MIT (code); **data subfolders have separate licenses** | HTTP API **or** vendor `ts/src/core/*` / `py/eotc/*` + JSON | **Highest value for EthioCal Pro** — offline-capable cores + feast/fast/lectionary data |

**Recommended EthioCal Pro path for this set:** treat **EOTCDevAPI** `ts/src/core` (or `py/eotc`) + selected `data/` JSON as the primary offline feast/fast/lectionary source (respecting per-folder licenses); use **yinebebt** / **EOTCDevAPI** Bahire Hasab as cross-check oracles; use **mukerem** or **Yaredt JS** for conversion vectors; do **not** depend on dakidarts at runtime for offline; treat Tadesse as algorithm reading only unless license clarified.

---

## 1. yinebebt/ethiocal

### Identity

| Field | Value |
|-------|--------|
| URL | https://github.com/yinebebt/ethiocal |
| Homepage | https://pkg.go.dev/github.com/yinebebt/ethiocal |
| Language | Go (Fyne GUI + cobra CLI) |
| Default branch | `main` |
| Stars / forks (API) | 24 / 1 |
| License | `LICENSE` — MIT (API `spdx_id`: MIT) |
| Topics | bahire-hasab, calendar, dateconverter, eotc, fyne, go |

### License

- **SPDX:** MIT. Commercial Flutter use of *ideas* / reimplementation allowed; keep notice if copying substantial code.
- No separate data licenses (no holiday JSON files).

### Language / structure

```text
dateconverter/     Ethiopian(), Gregorian(), helpers, format
bahirehasab/       NewFestival(), getBasic(), getFasting(), model types
cmd/ethiocal-cli/  bahir, convert subcommands
gui/               Fyne tabs (home, converter, bahire-hasab)
```

### Core conversion method

**Not JDN.** Month-length tables + Ethiopian New Year day-of-September via `startDayOfEthiopian(year)` in `dateconverter/helper.go`:

```text
startDayOfEthiopian(year) =
  (year / 100) - (year / 400) - 4
  + 1 if (year-1)%4 == 3
```

| Function | File | Role |
|----------|------|------|
| `Ethiopian(year, month, date)` | `dateconverter/ethiopian.go` | Gregorian → Ethiopian (`time.Time`) |
| `Gregorian(year, month, date)` | `dateconverter/gregorian.go` | Ethiopian → Gregorian |
| `startDayOfEthiopian(year)` | `dateconverter/helper.go` | New-year offset in September |
| `isValidEthiopian` / `isValidGregorian` | `dateconverter/helper.go` | Validation; leap when `year%4==3` |

Handles Gregorian reform gap (Oct 5–14 1582) and pre-1582 Julian alignment branches.

### Bahire Hasab

**Yes — full traditional chain**, package `bahirehasab`.

| Function / const | File | Notes |
|------------------|------|-------|
| `NewFestival(year)` | `bahirehasab/bahirehasab.go` | Preferred entry (replaces deprecated `BahireHasab`) |
| `getYear` | same | `ameteAlem = year+5500`, evangelist, `tinteQemer` |
| `getBasic` | same | Medeb, Wenber, Abektie (`TinteAbektie=11`), Metiq (`TinteMetiq=19`), BealeMetiq, MebajaHamer, Nenewie |
| `getFasting` | same | Offsets from Nenewie: Abiy+14, DebreZeit+41, Hosanna+62, Siklet+67, Tinsaye+69, RkbeKahnat+93, Erget+108, Peraklitos+118, Hawariyat+119, Dihnet+121 |
| Fixed | same | Nebiyat = Hidar 15; Filseta = Nehase 1; Gehad = day before Timket (Tir 11) |
| `weekdayTewsak`, `Date.AddDays` | `bahirehasab/model.go` | Tewsak Sat=8…Fri=2; 30-day month arithmetic |

### Holidays / fasts / saints data files

- **None as JSON/CSV.** Feasts/fasts are **computed** in `getFasting` / `Fasting` struct.
- No Sinksar / saints day-of-month tables beyond what Bahire Hasab returns.

### Tests

| File | Coverage |
|------|----------|
| `dateconverter/ethiopian_test.go` | `TestConvert`, `TestGregorian_pagume`, `TestEthiopian_leapDay`, `TestInvalid` |
| `dateconverter/format_test.go` | Format helpers |
| `bahirehasab/bahirehasab_test.go` | `TestNewFestival_2016`, `TestNewFestival_2006_metiq30`, `TestDate_AddDays`, `TestDate_String`, `TestNewFestival_invalid` |
| `cmd/ethiocal-cli/convert_test.go` | CLI convert |
| `.github/workflows/ci.yml` | CI |

### Flutter relevance

- **Cannot** link Go into Flutter without FFI/sidecar.
- **Useful as:** Bahire Hasab + conversion reference with clear named types (`Festival`, `Basic`, `Fasting`) and MIT license for porting.

### Limitations

- Conversion is custom tabular (not ICU JDN); must cross-check against ICU/kenat/EOTCDevAPI.
- No weekly Wed/Fri fast rules, no Sinksar, no lectionary.
- GUI depends on CGO/Fyne (irrelevant for Flutter).

### Offline reuse of data

- **Logic offline:** yes (pure Go libraries).
- **Shipable holiday datasets:** no separate files — port the computation.

---

## 2. mukerem/ethiocalendar

### Identity

| Field | Value |
|-------|--------|
| URL | https://github.com/mukerem/ethiocalendar |
| PyPI | https://pypi.org/project/ethiocalendar/ (v1.2.0) |
| Language | Python |
| Default branch | `main` |
| Stars / forks | 10 / 2 |
| License | `LICENSE.txt` — MIT |

### License

MIT. Safe to reimplement; attribution if copying.

### Language / structure

```text
ethiocalendar/ethiocalendar.py   ~86KB — stdlib-style date/datetime fork
ethiocalendar/__init__.py        from ethiocalendar.ethiocalendar import *
tests/test_ethiocalendar.py
setup.py / dist/*.whl
```

### Core conversion method

**Ethiopian ordinal + fixed delay vs Gregorian ordinal** (ICU / Beyene–Kudlek lineage), documented in-file:

| Constant | Value | Meaning |
|----------|-------|---------|
| `ETHIOPIAN_EPOCH_JDN` | `1723856` | JDN of 1 Meskerem year **0** (ICU) |
| `ETHIOORIGINALDAYDELAY` | `2795` | Days Ethiopian calendar lags proleptic Gregorian at 0001-01-01; Meskerem 1 year 1 → JDN **1724221** |

Key functions in `ethiocalendar/ethiocalendar.py`:

```text
_ymd2ord(y,m,d)  → Ethiopian ordinal (Meskerem 1, year 1 = day 1)
_ord2ymd(n)      → inverse via 1461-day cycles; leap Pagume when year%4==3
date.togregorian() → Gregorian date.fromordinal(eth_ord + ETHIOORIGINALDAYDELAY)
fromgretoethio(g)  → date.fromordinal(g.toordinal() - ETHIOORIGINALDAYDELAY)
to_gregorian / from_gregorian / today / is_leap_year  → tuple helpers (1.2.0)
is_puagume6(year)  → year % 4 == 3
```

### Bahire Hasab

**No.**

### Holidays / fasts / saints data files

**None.**

### Tests

`tests/test_ethiocalendar.py` — strong: anchors (incl. EC 1-1-1 → GC 8-8-27), Pagume round-trips, exhaustive early years, modern range 1890–2030, datetime clock preservation, epoch constant assert `ETHIOPIAN_EPOCH_JDN == 1723856`.

### Flutter relevance

- Python-only → **reimplement** ordinal/`ETHIOORIGINALDAYDELAY` in Dart (or use same JDN epoch as EOTCDevAPI/Yaredt).
- Excellent conversion **test oracle**.

### Limitations

- No religious calendar.
- Single large file mirroring CPython `datetime` — heavy to port wholesale; port only `_ymd2ord` / delay bridge.

### Offline reuse of data

- **Algorithm offline:** yes (pure Python, no network).
- **Datasets:** n/a.

---

## 3. dakidarts/ethiopian-calendar-api

### Identity

| Field | Value |
|-------|--------|
| URL | https://github.com/dakidarts/ethiopian-calendar-api |
| Homepage | https://dakidarts.com/api/ethiopian-calendar-api/ |
| Production base | `https://ethiopian-calendar-api.p.rapidapi.com` |
| Language (API) | `null` — **repo contains only `LICENSE` + `README.md`** |
| Default branch | `main` |
| Stars | 0 |
| License | MIT (`LICENSE`) |

### License

MIT applies to the two files present. **Implementation is not published** on GitHub; RapidAPI terms govern live use.

### Core conversion method

README (v0.0.2) claims a **dependency-free Julian-based** implementation after replacing buggy `ethiopian_date`. **No source, functions, or constants are in the repo** — cannot verify epoch or formulas from GitHub.

Documented product surface includes: `/convert`, `/holidays`, `/year`, `/batch`, Ethiopian sunrise clock, multilingual names via Google Translate, movable Orthodox via **Julian Easter**, fixed Ethiopian + national + approximate Islamic holidays.

### Bahire Hasab

README does **not** expose a Bahire Hasab endpoint or intermediate Medeb/Wenber values; movable feasts described as Julian Easter–derived (Siklet, Fasika, Rikbe Kahinat).

### Holidays / fasts / saints data files

**None in repo.** Holidays exist only behind RapidAPI.

### Tests

**None** in repository.

### Flutter relevance

- Possible as **online** enrichment only (RapidAPI key, network).
- **Unusable for EthioCal Pro offline core.**

### Limitations

- **API-only** by design (README: “Use exclusively on RapidAPI… GitHub repo is for issues”).
- No reproducible algorithm, no offline data, no conformance vectors.

### Offline reuse of data

**No.**

---

## 4. Yaredt/ethiopic-primitives

### Identity

| Field | Value |
|-------|--------|
| URL | https://github.com/Yaredt/ethiopic-primitives |
| Description | Deterministic primitives: calendar, fiscal, Ge'ez numerals, (planned) script equivalence |
| Languages | Python + TypeScript (bytes ~ equal); Shell tooling |
| Default branch | `main` |
| Stars | 0 |
| License | MIT |
| Status | **Pre-1.0** — not on npm/PyPI; Principle II blocks release until Tier-1 provenance |

### License

MIT for package code. Example PWA passages are part of the repo under the same tree (confirm attribution if vendoring large liturgy text).

### Core conversion method

**Two stacks:**

**JavaScript (native JDN)** — `javascript/src/calendar.ts`, `javascript/src/jdn.ts`:

| Symbol | Value / role |
|--------|----------------|
| `ETHIOPIC_EPOCH_JDN` | `1724221` = Meskerem 1, year 1 Amete Mihret |
| `EthiopianDate.toJdn()` | `EPOCH + 365*(y-1) + floor(y/4) + 30*(m-1) + (d-1)` |
| `EthiopianDate.fromJdn` | 1461-day cycles + `CYCLE_OFFSETS` |
| `gregorianToJdn` / `jdnToGregorian` | Fliegel & Van Flandern integer algorithm in `jdn.ts` |
| `Era.AmeteMihret` / `AmeteAlem` | ±5500 year offset |

**Python** — `python/src/ethiopic_primitives/calendar.py`:

- Thin wrapper over **`py-ethiopian-date-converter`** (`to_ethiopian`, `to_gregorian`, `create_ethiopian_date_from_parts`).
- Local types: `EthiopianDate`, `Era`; **no reimplementation** of conversion (constitution Principle III).

Also: `fiscal.py` / `numerals.py` / `equivalence.py` (folding engine noted as not fully built in README status section; package still exports equivalence API).

### Bahire Hasab

**No** (calendar/fiscal/numerals only).

### Holidays / fasts / saints data files

- No church feast/fast dataset in core.
- **Example lectionary-like data:** `examples/ethiopic-calendar/data/passages/01.json` … `13.json`, `su.json` (used by Zemen Calendar PWA demo). Not a full Sinksar; demo/readings oriented.

### Tests

| Area | Paths |
|------|-------|
| Conformance vectors | `tests/vectors/calendar.json` (181 gating + ICU-corroborated; fiscal/numerals vectors pending) |
| JS | `javascript/test/*.test.ts`, `run_vectors.ts`, `run_sweep.ts` |
| Python | `python/tests/test_calendar.py`, `run_vectors.py`, `run_sweep.py` |
| CI | `.github/workflows/conformance.yml` |
| Cross-lang | `tools/cross_runner.py`, `tools/full_sweep.py` |

### Flutter relevance

- **Port JS `EthiopianDate` / JDN** to Dart for conversion + Ge'ez numerals ideas.
- Python path is a dependency wrapper — less useful inside Flutter.
- Fiscal modules optional for business calendars, not EOTC liturgy.

### Limitations

- No Bahire Hasab / fasting status.
- Pre-release provenance blocker; still useful as open algorithm.
- Example passages ≠ audited EOTC lectionary (prefer EOTCDevAPI `data/gitsawe`).

### Offline reuse of data

- **Core libs:** fully offline.
- **`examples/.../data/passages`:** offline JSON in-repo; suitability for production liturgy is weaker than EOTCDevAPI.

---

## 5. TadesseAngaw/bahire-hasab

### Identity

| Field | Value |
|-------|--------|
| URL | https://github.com/TadesseAngaw/bahire-hasab |
| Language | Java (Swing / NetBeans) |
| Default branch | `main` |
| Stars / forks | 2 / 1 |
| License (GitHub API) | **`null`** (no LICENSE file) |
| Last push | 2022-12-23 (stale) |

### License (critical)

Source headers (`EthiopianCalendar.java`, `Tewsak.java`):

> “You can use and redistribute it **without modification**.”  
> No warranty. Contact: tadesseangaw@gmail.com

This is **not** MIT/Apache. EthioCal Pro should **not** copy/modify the Java sources into a Dart port under an assumption of permissive OSS; treat as **reference reading** or obtain explicit permission.

### Core conversion method

Custom day-of-year bridge in `src/com/tadesse/bahirehasab/tools/EthiopianCalendar.java` — **not JDN**:

| Method | Behavior |
|--------|----------|
| `toGregorianDate(date, month, year)` | `toNumberDay` → compare to `start` 112/113 from prior leap → set `Calendar.DAY_OF_YEAR` / year±7/8 |
| `toEthiopicDate(Calendar)` | Inverse using Gregorian day-of-year vs start 254/255 |
| `toNumberDay(day, month, year)` | `(month-1)*30 + day` |
| `isLeapYear` / `getWengelawi` | Leap when Wengelawi == Lukas (`(AMETE_ALEM+year)%4 == 3`) |

README **Known Issues:** Ethiopian↔Gregorian conversion wrong around January (no fixed epoch reference).

### Bahire Hasab

**Yes — extensive**, same class:

| Method | Role |
|--------|------|
| `getWenber`, `getAbekte`, `getMetke` | Wenber via 532/228/76/19 reduction; Abekte=`wenber*11%30`; Metke=`wenber*19%30` |
| `getMebajaHamer`, `tewsakMatch` | Uses `Tewsak` Sat=8…Fri=2 |
| `getNenewe` | Nineveh day-of-year |
| `getAbeyTsome` … `getTsomeDihnet` | Movable chain from Nenewe |
| Fixed | `getMeskel`=17, `getTimket`=131 (Tir 11), `getTsomeNebiyat`=75 (Hidar 15), `getFelseta`=331 (Nehase 1), `getGena` 118/119 by Wengelawi |

Constants: `AMETE_ALEM = 5500`; month/day/saint name arrays in Amharic.

### Holidays / fasts / saints data files

- **No external JSON.** Hard-coded in Java:
  - `SAINTS[]` — 30 monthly memorial name strings (day-of-month saints) in `EthiopianCalendar.java`
  - UI: `app/Holiday.java`, `app/Fasting.java`, `app/SaintMarry.java` (33 Feasts of St Mary — UI/logic in Swing forms)
- Resource wav for notifications under `tools/`.

### Tests

**None** found (no `*Test.java`).

### Flutter relevance

- **Algorithm encyclopedia** for BH feast offsets and saints name lists.
- License + Swing architecture make direct reuse poor.
- Conversion should **not** be trusted as oracle (author-documented bugs).

### Limitations

- Restrictive license; unmaintained; buggy conversion; NetBeans `.form` UI noise; no automated tests.

### Offline reuse of data

- Logic is offline by nature.
- **Legal reuse of modified code/data:** doubtful without permission.
- Saints strings could inspire a new table written from public liturgical knowledge, not copied verbatim if counsel advises caution.

---

## 6. natinael96/EOTCDevAPI (deep dive)

### Identity

| Field | Value |
|-------|--------|
| URL | https://github.com/natinael96/EOTCDevAPI |
| Live API | `https://eotcdev-api.natinael-96.workers.dev` (also GitHub Pages docs) |
| Languages | HTML, TypeScript, Python, JavaScript (Workers + FastAPI + static site) |
| Default branch | `master` |
| Stars / forks | 2 / 2 |
| Repo license | MIT (`LICENSE`, Copyright 2026 EOTCDev) |

### API-only vs offline-capable

| Mode | Verdict |
|------|---------|
| Public REST | Yes — no auth; rate-limited Workers deploy |
| **Offline / vendorable** | **Yes** — README: “The `core` modules have **zero dependencies**… Vendor them directly if you would rather not make a network call.” |
| Database | None — JSON + pure functions |

Dual implementations held in lockstep by `spec/conformance.json` (~9,154 vectors) and `spec/responses.json`.

### Core conversion method

`ts/src/core/ethiopic.ts` and `py/eotc/ethiopic.py` (same math):

| Symbol | Value |
|--------|-------|
| `JDN_EPOCH_AMETE_MIHRET` | `1723856` |
| `AMETE_FIDA` | `5500` |

```text
ethiopicToJDN(y,m,d) =
  JDN_EPOCH_AMETE_MIHRET + 365
  + 365*(y-1) + floor(y/4)
  + 30*m + d - 31
```

(Equivalent to Meskerem 1, year 1 → JDN **1724221**, matching mukerem/Yaredt year-1 epoch.)

Also: `jdnToEthiopic`, `gregorianToJDN`, `jdnToGregorian`, `ethiopicToGregorian`, `gregorianToEthiopic`, `isEthiopicLeapYear` (`y%4===3`), `daysInEthiopicMonth`.

### Bahire Hasab

`ts/src/core/bahirehasab.ts` / `py/eotc/bahirehasab.py`:

| Export | Role |
|--------|------|
| `bahireHasab(year)` | Amete Alem → Medeb → Wenber → Abekte/Metqi → Mebaja Hamer → `ninevehJDN` |
| `TEWSAK_NINEVEH` | `[7,6,5,4,3,2,8]` indexed by Sunday=0 weekday |
| `MOVABLE_FEASTS` | Offsets 0…121 from Nineveh (nineveh, abiy_tsome, debre_zeit, hosanna, siklet, fasika, rikbe_kahnat, erget, peraklitos, tsome_hawaryat, tsome_dihnet) |
| `movableFeastJDN` / `movableFeasts` | Resolve all movable dates |
| `alexandrianEasterJDN` | Independent Meeus Julian computus; tests assert Fasika agreement 1800–2200 EC |

Endpoint: `GET /v1/bahire-hasab/{year}`.

### Fasting / feasts (code tables, not only JSON)

| File | Contents |
|------|----------|
| `ts/src/core/fasts.ts` (`py/eotc/fasts.py`) | `fastPeriods(year)`, `fastingStatus(jdn, year)` — seven periods + Wed/Fri with Hamsa / feast overrides |
| `ts/src/core/feasts.ts` (`py/eotc/feasts.py`) | `FIXED_FEASTS` (Enkutatash, Meskel, Gena, Timket, …), `MONTHLY_COMMEMORATIONS` (1,5,7,12,14,16,19,21,23,24,27,29) |

These tables are **MIT-licensed code** and ideal for Dart ports.

### `data/` directory — files useful for holidays, fasting, saints, lectionary

#### `data/gitsawe/` — fixed-cycle lectionary transcription

| File | Use |
|------|-----|
| `01-meskerem.json` … `13-paguemen.json` | Per-month days: Ge'ez `day_number`, `commemoration`, services `ዘነግህ` / `ዘቅዳሴ` / `ዘሠርክ` with Psalm/Gospel/epistle citations |
| `manifest.json` | Provenance: book መጽሐፈ ግጻዌ…; fixed cycle transcribed; movable/Sunday/occasional/**bahireHasabTables** = `not_transcribed`; **`licenseStatus`: `unverified`** |
| `quality-report.json` | Extraction QA |

**License:** **unverified** (manifest). Treat as liturgical transcription with unclear redistribution rights until cleared — citations/structure safer than shipping full verse bodies commercially.

#### `data/sinksar/` — Synaxarium (saints / commemorations)

| File | Use |
|------|-----|
| `1.json` … `13.json` | `{ month, days: [{ day, entries: [{ title, text }] }] }` — Amharic Sinksar narratives |
| `manifest.json` | Month lengths incl. Pagume 6 |
| `LICENSE-Apache-2.0` | Apache-2.0 text (Sinq **source code** lineage) |
| `NOTICE` | **Critical:** bundled *content* is **not** Apache — Bible CC BY-NC-ND; Synaxarium called traditional liturgical content; fonts OFL |

**Saints data:** yes — primary offline saint/commemoration corpus. Review NOTICE before commercial bundling of full text.

#### `data/sinq-gitsawe/` — seasonal/monthly cycles, feast graph, mahlets

| File | Use for EthioCal Pro |
|------|----------------------|
| `daily-gitsawe.json` | 366 daily reading keys (npm + backfill) |
| `seasonal-gitsawe.json` | 43 movable-season reading records |
| `monthly-gitsawe.json` | Sunday-cycle candidates |
| `feasts.json` | 21 feast graph nodes (keys, Amharic names, month/day, movable flag) |
| `sub-feasts.json` | 40 sub-feasts |
| `mahlets.json` | 37 mahlet / chant service orders |
| `months.json`, `names-am.json`, `packages.json` | Naming / packaging metadata |
| `manifest.json` | Full lineage + sha256 per file |
| `upstream-npm.json`, `quality-report.json`, `reconciliation-report.json` | Provenance / QA |
| `LICENSE-MIT` | MIT for **gitsawe npm** origin (BereketeAb) |

**License:** MIT for npm-derived reading dataset; Sinq-authored feast/mahlet layers — mahlet chant text credits third-party digitizations **with no stated license** (manifest warning).

#### Related (not under `data/`, but content)

| Path | License | Offline? |
|------|---------|----------|
| `web/bible/am-1980/*.json`, `gez-1980/` | **CC BY-NC-ND 4.0** (`web/bible/NOTICE`) | Yes files, **not** OK for commercial EthioCal Pro verse bundling |
| `ts/src/core/*.ts`, `py/eotc/*.py` | MIT | Yes — preferred for conversion/BH/fasts/feasts |
| `spec/conformance.json` | Repo MIT | Offline test oracle |

### Tests

| Suite | Path |
|-------|------|
| TS | `ts/test/api.test.ts`, `conformance.test.ts`, `reference-integrity.test.ts`, `sinq-catalog.test.ts`, `rate-limit.test.ts` |
| Python | `py/tests/test_conformance.py`, `test_parity.py`, `test_daily_endpoints.py`, `test_sinq_catalog.py`, … |
| Spec | `spec/conformance.json`, `responses.json`, `routes.json`, `batch-cases.json` |
| CI | `.github/workflows/ci.yml` |

Also asserts: EC↔JDN round-trip over 73k+ days; Fasika BH vs Alexandrian agreement.

### Flutter relevance

**Highest of this batch for EthioCal Pro:**

1. Port `ethiopic.ts` + `bahirehasab.ts` + `fasts.ts` + `feasts.ts` to Dart (offline).
2. Bundle curated JSON from `data/sinq-gitsawe/feasts.json` (+ optionally daily/seasonal) under MIT where applicable.
3. Use Sinksar / gitsawe text selectively after license review (summaries vs full narrative).
4. Optionally call live Workers API when online; do not require it.
5. Kotlin/Swift examples in `examples/` show mobile client patterns; Flutter would mirror HTTP or local port.

### Limitations

- Gitsawe movable/Sunday/BH tables not fully transcribed (`resolution: "fixed_candidate_only"` on API).
- Bible verse text intentionally not MIT-bundled.
- Some mahlet/sinksar/gitsawe content licenses **unverified** or NC — commercial app must filter.
- Dual TS/Python maintenance — pick one as port source (TS closer to Dart).

### Offline reuse summary (EOTCDevAPI)

| Asset | Offline? | License posture for commercial Flutter |
|-------|----------|----------------------------------------|
| `ts/src/core/*` / `py/eotc/*` | Yes | MIT — **reuse** |
| `data/sinq-gitsawe/*` (esp. feasts, seasonal, daily structure) | Yes | MIT npm lineage + Sinq authorship — **generally reusable**; check mahlet chant text |
| `data/sinksar/*.json` | Yes | Liturgical text; NOTICE separates from Apache code — **legal review** |
| `data/gitsawe/*.json` | Yes | `licenseStatus: unverified` — **caution** |
| `web/bible/**` | Yes files | CC BY-NC-ND — **do not ship in commercial app** |
| Hosted REST only | N/A | Fine as optional online layer |

---

## Cross-repo comparison (quick)

| Capability | ethiocal (Go) | ethiocalendar (Py) | dakidarts API | ethiopic-primitives | bahire-hasab (Java) | EOTCDevAPI |
|------------|---------------|--------------------|---------------|---------------------|---------------------|------------|
| SPDX-friendly | MIT | MIT | MIT docs only | MIT | Restrictive / none | MIT code |
| Conversion | Tabular NY | Ordinal+2795 / ICU | Unpublished | JDN 1724221 (JS) | Day-of-year (buggy) | JDN 1723856+365 |
| Bahire Hasab | Yes | No | No (Julian Easter in product) | No | Yes | Yes + dual computus |
| Fasts/feasts data | Computed | No | API only | No | Hard-coded + UI | Code tables + JSON |
| Saints / Sinksar | No | No | No | Passages demo only | `SAINTS[]` + St Mary UI | `data/sinksar` |
| Lectionary | No | No | No | Example passages | No | `data/gitsawe` + `sinq-gitsawe` |
| Tests | Moderate | Strong conversion | None | Strong + sweep | None | Very strong |
| Offline for Flutter | Port Go | Port Python | No | Port JS | Reference only | **Vendor cores + JSON** |

---

## EthioCal Pro action list (from this audit)

1. **Dart core:** port EOTCDevAPI `ethiopic` + `bahirehasab` + `fasts` + `feasts` (cross-check yinebebt offsets and mukerem/Yaredt conversion vectors).
2. **Ship offline:** `FIXED_FEASTS` / `MONTHLY_COMMEMORATIONS` / `fastPeriods` logic; add `data/sinq-gitsawe/feasts.json` (and daily/seasonal if product needs readings).
3. **Avoid:** dakidarts as offline dependency; Tadesse source copy without license grant; `web/bible` in a paid store build.
4. **License gate:** counsel on `data/gitsawe` (unverified) and `data/sinksar` full narrative text before bundling.
5. **Do not** use Tadesse `toGregorianDate` / `toEthiopicDate` as a correctness oracle.
