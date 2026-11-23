# GitHub Calendar Resource Audit

**Project:** EthioCal Pro  
**Audit date:** 2026-11-15  
**Method:** Public GitHub API + raw source inspection (not README-only).  
**Detailed notes:**

- `research_notes/Ethiopian calendar GitHub audit/batch1_abushakir_kenat_ethiocal.md`
- `research_notes/Ethiopian calendar GitHub audit/batch2_calendar_api_primitives.md`
- `research_notes/Ethiopian calendar GitHub audit/batch3_bahire_eotc_kenatpy.md`
- Synthesis report: `reports/Ethiopian calendar GitHub audit.md`

**QC:** Calendar flutter tests passed after integration (see `CALENDAR_ACCURACY_TEST_REPORT.md`).

## Decision summary

| Choice | Rationale |
|--------|-----------|
| **Keep EthioCal Dart JDN engine** (`ethiopianEpochJdn = 1724221`) | Matches Yaredt/ethiopic-primitives + **4936/4936** EOTCDevAPI conformance conversions |
| **Do not depend on Abushakir pub package as-is** | MIT and useful, but `sdk: <3.0.0` blocks modern Flutter |
| **Do not ship kenat/kenat_py inside Flutter** | MIT algorithm/test oracles only — reimplemented already in Dart |
| **Do not use dakidarts API for offline core** | RapidAPI product; repo has no offline engine |
| **Vendor data ideas from EOTCDevAPI / kenat with attribution** | Feast/fast rules + conformance; respect per-folder licenses for Sinksar text |

---

## 1. Nabute/Abushakir

| Field | Finding |
|-------|---------|
| URL | https://github.com/Nabute/Abushakir |
| Stars / lang / license | 33 / Dart / **MIT** |
| Core | RD-style fixed day (`_ethiopicEpoch=2796`); `EtDatetime`; `bahireHasab.dart` |
| Tests | `test/abushakir_test.dart` |
| Flutter | Pure Dart package; **SDK upper bound `<3.0.0` blocks Dart 3** |
| Reuse | Fork/vendor + raise SDK, or keep EthioCal engine (preferred) |

## 2. MelakuDemeke/kenat

| Field | Finding |
|-------|---------|
| URL | https://github.com/MelakuDemeke/kenat |
| Stars / lang / license | 59 / TypeScript / **MIT** |
| Core | New-Year tabular EC↔GC; `bahireHasab.ts`, `fasting.ts`, `holidays.ts`, `geezConverter.ts` |
| Tests | Rich suite (`conversions`, `bahireHasab`, `fasting`, `holidays`, grids, time) |
| Limitations | Open **#39** historical `toGC` drift outside ~1892–2091 EC; Genna hardcoded Tahsas 29 |
| Reuse | **Reference only** — reimplement in Dart (already done in EthioCal) |

## 3. MelakuDemeke/kenat_py

| Field | Finding |
|-------|---------|
| URL | https://github.com/MelakuDemeke/kenat_py |
| Stars / lang / license | 1 / Python / **MIT** |
| Core | Port of kenat (`bahire_hasab.py`, `fasting.py`, `holidays.py`) |
| Tests | Parallel pytest coverage |
| Reuse | Cross-language oracle only |

## 4. yinebebt/ethiocal

| Field | Finding |
|-------|---------|
| URL | https://github.com/yinebebt/ethiocal |
| Stars / lang / license | 24 / Go / **MIT** |
| Core | Tabular conversion; full Bahire Hasab (`NewFestival`, offset table) |
| Tests | `dateconverter/*_test.go`, `bahirehasab/bahirehasab_test.go` |
| Reuse | Offset table cross-check vs EthioCal `BahireHasab` |

## 5. mukerem/ethiocalendar

| Field | Finding |
|-------|---------|
| URL | https://github.com/mukerem/ethiocalendar |
| Stars / lang / license | 10 / Python / **MIT** |
| Core | ICU / Beyene–Kudlek ordinal (`ETHIOORIGINALDAYDELAY=2795`) |
| Tests | Conversion-focused |
| Reuse | Conversion reference; no BH/holidays |

## 6. dakidarts/ethiopian-calendar-api

| Field | Finding |
|-------|---------|
| URL | https://github.com/dakidarts/ethiopian-calendar-api |
| Stars / license | 0 / MIT LICENSE file |
| Tree | LICENSE + README only — product on RapidAPI |
| Reuse | **Excluded from offline core** (violates “API not sole source”) |

## 7. Yaredt/ethiopic-primitives

| Field | Finding |
|-------|---------|
| URL | https://github.com/Yaredt/ethiopic-primitives |
| Stars / lang / license | 0 / Python+JS / **MIT** |
| Core | Spec confirms **JDN epoch 1724221**; fiscal + Geez primitives |
| Reuse | Epoch confirmation; no Bahire Hasab |

## 8. TadesseAngaw/bahire-hasab

| Field | Finding |
|-------|---------|
| URL | https://github.com/TadesseAngaw/bahire-hasab |
| Stars / lang / license | 2 / Java Swing / **no SPDX**; “redistribute without modification” |
| Core | Desktop BH, fasting, saints UI |
| Reuse | **Algorithm reading only** — do not copy |

## 9. natinael96/EOTCDevAPI

| Field | Finding |
|-------|---------|
| URL | https://github.com/natinael96/EOTCDevAPI |
| Stars / lang / license | 2 / TS+Python+data / **MIT code**; data folders have separate licenses |
| Core | Offline `ts/src/core/*`, `py/eotc/*`; `spec/conformance.json` (~4936 conversions) |
| Data | `data/sinq-gitsawe` (MIT lineage), `data/sinksar` (Apache-2.0), gitsawe monthly JSON |
| Reuse | **Highest-value independent oracle**; Sinksar full text needs license care |

---

## Architecture chosen for EthioCal Pro

1. **Calculations:** existing Dart modules under `lib/core/calendar/` (JDN + Bahire Hasab + Geez + time).  
2. **Datasets:** `assets/data/ethiopian_calendar/*.json` with provenance in `sources.json`.  
3. **Loader:** `CalendarDataCatalog` (offline).  
4. **Holidays/fasts:** `HolidayEngine` remains source of runtime events (now includes additional national days aligned with kenat gazette list).  
5. **External APIs:** optional enrichment only — never required for conversion or fasting.
