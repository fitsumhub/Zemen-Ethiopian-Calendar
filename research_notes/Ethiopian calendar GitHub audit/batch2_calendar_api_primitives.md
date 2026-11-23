# Batch 2 — Calendar API & Primitives GitHub Audit

**Audit date:** 2026-11-15  
**Repos:** [mukerem/ethiocalendar](https://github.com/mukerem/ethiocalendar) · [dakidarts/ethiopian-calendar-api](https://github.com/dakidarts/ethiopian-calendar-api) · [Yaredt/ethiopic-primitives](https://github.com/Yaredt/ethiopic-primitives)  
**Inspection:** GitHub REST API (`api.github.com`) and raw `raw.githubusercontent.com` content. `gh api` was **not used** (CLI unauthenticated on this machine). No live RapidAPI calls were made.

---

## Cross-repo summary

| Repo | Kind | License (GitHub) | Primary language(s) | GitHub releases/tags | Conversion in repo? |
|------|------|------------------|---------------------|----------------------|---------------------|
| ethiocalendar | Offline PyPI library | **MIT** | Python | Releases: v1.0, v1.0.2, v1.1, v1.1.2 (no v1.2.0 tag found in `git/refs/tags`) | Yes — full source |
| ethiopian-calendar-api | Hosted REST API (+ docs repo) | **MIT** (`LICENSE` file); README footer also says “All rights reserved” | **None detected** (repo = README + LICENSE only) | **0** GitHub releases | **No** — algorithm not published on GitHub |
| ethiopic-primitives | Offline JS/TS + Python wrappers, conformance suite | **MIT** | Python, TypeScript (+ demo HTML) | **0** releases (pre-1.0 per README) | Yes — JS implementation + `tools/reference_ethiopic.py` |

**Epoch constants (verified from source/docs only):**

| Project | Constant(s) documented in repo | Leap rule (stated) |
|---------|--------------------------------|--------------------|
| ethiocalendar | `ETHIOPIAN_EPOCH_JDN = 1723856` (ICU “year 0” Meskerem 1); Meskerem 1 **year 1** ↔ JDN **1724221** via ordinal test; bridge `ETHIOORIGINALDAYDELAY = 2795` | `year % 4 == 3` → Pagume 6 |
| ethiopian-calendar-api | README: “Julian-based”; `/calendar-info` text mentions epoch qualitatively — **no numeric JDN in repo** | `year % 4 == 3` (README examples) |
| ethiopic-primitives | `ETHIOPIC_EPOCH_JDN = 1724221` in JS + `tests/vectors/calendar.json`; spec also discusses ICU value **1723856** with formula caveat | `ethiopian_year % 4 == 3` |

**Holiday / saint / fasting data:**

| Repo | In repository? |
|------|----------------|
| ethiocalendar | **No** (date/time only) |
| ethiopian-calendar-api | **Documented API surface only** (`/holidays`, movable Orthodox via Julian Easter, approximate Islamic) — **unverified** without server source |
| ethiopic-primitives | **No** calendar-layer holidays; fiscal + numerals + (planned) folding only |

**Flutter / Dart portability:**

| Repo | Notes |
|------|--------|
| ethiocalendar | Python-only; Dart port would reimplement ordinal/JDN logic or call a FFI bridge — **not provided** |
| ethiopian-calendar-api | Flutter can use `http` against RapidAPI — **online**, rate-limited, no offline parity from this repo |
| ethiopic-primitives | **TypeScript** core is portable to Dart with manual port; `examples/ethiopic-calendar` is **PWA/HTML/JS**, not Flutter. No Dart package. |

---

## 4. mukerem/ethiocalendar

**URL:** https://github.com/mukerem/ethiocalendar  
**Description (GitHub):** Ethiopian Calendar based date and time module in python  
**Stars / updated:** 10 stars; last push 2026-09-01 (per API)  
**Default branch:** `main`

### README, license, language, releases

- **README:** Documents PyPI **1.2.0**, Python 3.6+, MIT badge; cites Unicode ICU epoch `JD_EPOCH_OFFSET_AMETE_MIHRET = 1723856` and Beyene–Kudlek.
- **License:** MIT (`LICENSE.txt`, GitHub `license.spdx_id`: MIT).
- **Language:** Python only (~93 KB in `ethiocalendar.py` per API languages).
- **Releases (GitHub):** v1.0, v1.0.2, v1.1, v1.1.2 — **no GitHub Release for 1.2.0** at audit time.
- **`setup.py` on `main`:** declares `version='1.2.0'` and `download_url` for tag `v1.2.0` — **tag presence unverified** (not listed in `git/refs/tags` response).

### Conversion algorithms and epoch constants

Two layers (both in `ethiocalendar/ethiocalendar.py`):

1. **Ethiopian proleptic ordinal** — `_ymd2ord` / `_ord2ymd` on 1461-day (4-year) cycles; Pagume 6 is the leap day in years with `year % 4 == 3`.
2. **Gregorian bridge** — `togregorian()` / `fromgretoethio()` add/subtract **`ETHIOORIGINALDAYDELAY = 2795`** between Ethiopian ordinal and Gregorian `date.toordinal()` (proleptic Gregorian day 1 = 0001-01-01).

Exported constants (tests assert):

- `ETHIOPIAN_EPOCH_JDN == 1723856` (comment: ICU epoch for Meskerem 1, **year 0**).
- Meskerem 1, year 1 → Gregorian **8-08-27** proleptic; test: `g.toordinal() + 1721425 == 1724221`.

README v1.2.0 notes: ICU-accurate conversion; Pagume 5 on non-leap years fixed for `from_gregorian`; convenience APIs `to_gregorian`, `from_gregorian`, `is_leap_year`.

**Leap:** `is_leap_year` / `is_puagume6` → `year % 4 == 3`.

### Holiday / saint / fasting

**None** in repository.

### Tests

- **File:** `tests/test_ethiocalendar.py` (pytest).
- **Coverage (from file):** anchor pairs; Pagume 5/6; round-trip EC years 1–40 ordinals; **1890–2030** exhaustive round-trip; datetime/pickle/strftime; leap helpers; epoch constant; regression `2024-09-10` → `(2016, 13, 5)` (“previously crashed”).

Run: `pytest -q` (README).

### API vs offline library

- **Offline** install: `pip install ethiocalendar`.
- Mirrors stdlib `date` / `datetime` / `timedelta` with Ethiopian calendar semantics.
- **Pros:** No network; full source; pytest suite on `main`.
- **Cons:** Python-only; dual epoch documentation (1723856 vs operational 1724221) requires care when comparing to JDN-first libraries.

### Flutter/Dart

**No Dart/Flutter support.** Port ordinal + delay logic or wrap Python.

---

## 5. dakidarts/ethiopian-calendar-api

**URL:** https://github.com/dakidarts/ethiopian-calendar-api  
**Homepage:** https://dakidarts.com/api/ethiopian-calendar-api/  
**Description:** REST API for EC↔GC, leap years, holidays, Ethiopian time; **“Use exclusively on RapidAPI”** — GitHub for issues/docs.  
**Default branch:** `main`  
**Repo contents (verified):** only `README.md` and `LICENSE` — **no server implementation on GitHub.**

### README, license, language, releases

- **Documented API version:** **0.0.2** (badge in README, Aug 26, 2026 changelog).
- **License file:** MIT (Copyright 2025 Dakidarts Web Services).
- **README license section:** “Copyright © 2026 Dakidarts… All rights reserved” — **wording conflicts with MIT file**; treat **MIT as filed in `LICENSE`**; API **service terms unverified** here.
- **GitHub `language`:** `null` (no code files).
- **GitHub releases:** **empty array**.

### Conversion algorithms and epoch constants (README claims only)

- v0.0.2: replaced buggy `ethiopian_date` with **“dependency-free Julian-based implementation”**.
- **Numeric epoch / JDN not published** in the public repo.
- `/calendar-info` example JSON includes narrative `epoch` text (7/8 year offset) — not a formula.
- Leap: Ethiopian leap when year ends in 3; Pagume 5 or 6 days.

**Status:** Conversion correctness on GitHub is **unverified** (no source). README examples are **documentation**, not executed tests in-repo.

### Holiday / saint / fasting (API docs)

README `/holidays` and `/next-holiday`:

| Category | Named in README |
|----------|-----------------|
| Fixed Ethiopian | Enkutatash, Meskel, Genna, Timkat, Adwa |
| Movable Orthodox | Siklet, Fasika, Rikbe Kahinat (Julian Easter) |
| Fixed Gregorian (national) | Labor Day, Patriots' Victory, Derg Downfall |
| Islamic (approx.) | Eid al-Fitr, Eid al-Adha, Mawlid |

**Fasting / saints:** **Not listed** in README holiday table — **unverified** whether API exposes them elsewhere.

### Tests

**None in GitHub repository.**

### API vs offline library

| Aspect | Assessment |
|--------|------------|
| Deployment | `https://ethiopian-calendar-api.p.rapidapi.com` + RapidAPI key headers |
| Offline | **Not possible** from this repo |
| Scope | 20 endpoints: conversion, year/month views, batch (≤100), holidays, Ethiopian 12-hour “sunrise” clock, Google Translate `lang`, timezones |
| Tradeoff | Rich integrated product (holidays, i18n, TZ) vs latency, cost, availability, and **black-box** conversion |

### Flutter/Dart

Use HTTP client + RapidAPI headers. Suitable for **online** features only; **cannot** audit or ship offline algorithm from GitHub.

---

## 6. Yaredt/ethiopic-primitives

**URL:** https://github.com/Yaredt/ethiopic-primitives  
**Description:** Deterministic, model-free primitives for Ethiopian calendar, fiscal periods, Ge'ez numerals  
**Status (README):** **Pre-1.0** — not on npm/PyPI yet; blocked on Tier-1 provenance (Principle II).

### README, license, language, releases

- **License:** MIT.
- **Languages (GitHub):** Python, TypeScript, Shell, JavaScript (large `tools/` and `javascript/` trees).
- **Releases:** none.
- **CI:** conformance workflow badge in README.

### Conversion algorithms and epoch constants

**Reference** (`tools/reference_ethiopic.py`):

```text
EPOCH = 1724221
eth_to_jdn(y,m,d) = EPOCH + 365*(y-1) + y//4 + 30*(m-1) + (d-1)
```

Gregorian ↔ JDN: standard proleptic formulas; `from_jdn` uses 1461-day cycle with `CUM = [0,365,730,1096]`.

**Production JS** (`javascript/src/calendar.ts`): port of reference; exports `ETHIOPIC_EPOCH_JDN = 1724221`, class `EthiopianDate` with `toJdn()`, `fromJdn()`, `toGregorian()`, `fromGregorian()`, `addDays`, `addMonths`, `weekday()`, eras `AmeteMihret` / `AmeteAlem` (+5500).

**Python calendar:** README states **thin wrapper** over `py-ethiopian-date-converter==0.1.1` — not a second implementation.

**Spec** (`ethiopic-primitives-spec.md`): documents JDN path with `ETHIOPIC_EPOCH_JDN = 1723856` and warns epoch off-by-one is a common bug; implementation uses **1724221** for year-numbering used in code (Meskerem 1, year 1).

**Sweep (README claim):** 1990–2035 day-by-day both directions, zero mismatches (JS, Python wrapper, cross-runner) — **not re-run in this audit**.

### Holiday / saint / fasting

**No** in calendar module. Demo calendar UI may show month view only (HTML example) — **no liturgical engine** in audited paths.

**Fiscal** (feature 002): Hamle 1 – Sene 30; `tests/vectors/fiscal.json` **pending**.

### Tests

| Asset | Role |
|-------|------|
| `tests/vectors/calendar.json` | **182** vectors; **181** `gating: true` (ICU-corroborated); **1** non-gating epoch vector |
| `ethiopic-conformance-vectors.json` (repo root) | Large conformance export (65 KB) — same lineage as vectors file **unverified byte-identical** in this audit |
| `tools/full_sweep.py` | Oracle sweep gate |
| `tools/cross_runner.py` | JS vs Python agreement |
| `javascript/` npm scripts | `vectors`, `sweep`, `test` |
| `examples/ethiopic-calendar/test/` | Demo tests present — **not inspected line-by-line** |

Provenance policy in `calendar.json`: gating vectors need external authority; **no Tier-1 Ethiopian government source yet**.

### API vs offline library

- **Designed offline-first** (Layer 0 — no model/network).
- JS package name in README: `@ethiopic-primitives/calendar` — **publish status unverified** (pre-1.0).
- **Highest leverage for correctness:** shared JSON vectors + reference algorithm for ports (including Dart).

### Flutter/Dart

- **No Dart SDK.**
- **Practical path:** port `calendar.ts` / `jdn.ts` logic (integer JDN) or transcribe `reference_ethiopic.py`; reuse `tests/vectors/calendar.json` as golden tests.
- `examples/ethiopic-calendar`: installable **web** calendar (PWA: `manifest.webmanifest`, `sw.js`) — not Flutter.

---

## Verified conversion test vectors

Only pairs **explicitly present in repo tests, examples, or vector files** are listed. Provenance: **pytest** / **README examples** / **ICU-gated JSON**.

### mukerem/ethiocalendar — `tests/test_ethiocalendar.py` + README

| Ethiopian (Y-M-D) | Gregorian (Y-M-D) | Source |
|-------------------|-------------------|--------|
| 2011-01-01 | 2018-09-11 | pytest anchor |
| 2012-01-01 | 2019-09-12 | pytest + README |
| 2011-13-06 | 2019-09-11 | pytest anchor |
| 2015-13-05 | 2023-09-10 | pytest anchor |
| 2018-03-03 | 2025-11-12 | pytest + README |
| 2025-11-12 | 2018-03-03 | pytest (GC→EC) |
| 2019-09-12 | 2012-01-01 | pytest (GC→EC) |
| 2019-09-11 | 2011-13-06 | pytest (GC→EC) |
| 2023-09-10 | 2015-13-05 | pytest (GC→EC) |
| 2024-09-10 | 2016-13-05 | pytest regression |
| 0001-01-01 | 0008-08-27 | pytest (GC→EC) / epoch |
| 2012-01-01 | 2019-09-12 | README round-trip example |

**Reference anchors in** `tools/reference_ethiopic.py` (same repo family as ethiopic-primitives, listed for cross-check):

| Ethiopian | Gregorian |
|-----------|-----------|
| 2000-01-01 | 2007-09-12 |
| 2018-01-01 | 2025-09-11 |
| 2003-13-06 | 2011-09-11 |
| 2004-13-05 | 2012-09-10 |
| 2016-01-01 | 2023-09-12 |
| 2017-01-01 | 2024-09-11 |

### dakidarts/ethiopian-calendar-api — README JSON examples only (not executed)

| Input | Output | Endpoint context |
|-------|--------|------------------|
| EC 2016-01-01 | GC 2023-09-12 | `/to-gregorian` |
| GC 2024-09-11 | EC 2017-01-01 | `/to-ethiopian` |
| EC 2016-01-01 | GC 2023-09-12 | `/batch` index 0 |
| EC 2015-13-06 | GC 2023-09-10 | `/batch` index 1 |

**Treat as API documentation vectors until independently called or source is published.**

### Yaredt/ethiopic-primitives — `tests/vectors/calendar.json` (ICU gating)

File metadata: `epoch_jdn: 1724221`, `count: 182`, `leap_rule: ethiopic_year % 4 == 3`.

**Spec anchors** (`ethiopic-primitives-spec.md` §2.5) — also reflected in vectors:

| Ethiopian | Gregorian | Note |
|-----------|-----------|------|
| 2000-01-01 | 2007-09-11 | Spec says 11 Sep 2007 (**verify:** ICU vectors use per-year “new year” rows; EC 2000-01-01 appears as **2007-09-12** in JSON at ethiopic `[2000,1,1]` — **spec prose may be off by one day vs JSON**) |
| 2003-13-06 | 2011-09-11 | Pagume leap |
| 2004-13-05 | 2012-09-10 | Pagume non-leap |
| 2012-01-01 | 2019-09-12 | JSON `new year` row |
| 2003-13-06 | 2011-09-11 | JSON `pagume last (leap)` |
| 0001-01-01 | 0008-08-27 | `gating: false`, source `derived`, ICU blocked |

**javascript/README.md examples:**

| Ethiopian | Gregorian |
|-----------|-----------|
| (from GC) 2007-09-12 → EC 2000-01-01 | `fromGregorian` |
| 2003-13-06 → 2011-09-11 | `toGregorian` |

**Correction on spec vs JSON for 2000-01-01:** Verified JSON entry:

```json
"ethiopic": [2000, 1, 1],
"gregorian": [2007, 9, 12]
```

(Spec bullet “11 September 2007” disagrees with committed vector — **trust JSON + pytest anchors over spec bullet** until reconciled upstream.)

---

## Recommendations for EthioCal / Flutter integration

1. **Offline conversion:** Prefer **ethiopic-primitives** JDN approach (`1724221` + leap `% 4 == 3`) or **ethiocalendar** ordinal suite — cross-check with `calendar.json` gating vectors.
2. **Do not depend on dakidarts GitHub** for algorithm audit; optional **online** enrichment (holidays, translations) only.
3. **Golden tests:** Import or mirror `tests/vectors/calendar.json` (181 gating pairs) plus mukerem pytest anchors; add Pagume 5 non-leap cases from mukerem tests.
4. **Epoch confusion:** When comparing libraries, normalize whether epoch constant is **Meskerem 1 year 0 (1723856)** vs **year 1 (1724221)** — ethiocalendar exposes both concepts.

---

## Unverified / not inspected

- PyPI tarball for ethiocalendar **1.2.0** vs GitHub `main` byte parity.
- dakidarts live API responses vs README examples.
- ethiopic-primitives npm publish status and CI run logs on 2026-11-15.
- Whether `ethiopic-conformance-vectors.json` duplicates `tests/vectors/calendar.json`.
- Tier-1 government holiday dates for ethiopic-primitives release gate.

---

*End of batch 2 audit.*