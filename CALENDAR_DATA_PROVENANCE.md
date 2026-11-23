# Calendar Data Provenance

**Dataset root:** `assets/data/ethiopian_calendar/`  
**Version:** 1.0.0 (2026-11-15)  
**Policy:** Every event carries `source_ids` and a verification / date-kind tag. Approximate data is never silently treated as verified.

## Date-kind vocabulary

| Kind | Meaning |
|------|---------|
| `fixed_ethiopian` | Same EC month/day every year |
| `calculated_bahire_hasab` | Computed yearly; never hardcode a single year’s date |
| `calculated_from_fixed_rule` | Fixed rule with leap-sensitive day (e.g. Genna) |
| `calculated_hijri_to_ethiopian` | Algorithmic Hijri projection |
| `approximate_rule` | Cultural marker; civic date may differ |
| `approximate_calculated` | Useful estimate; sighting/gazette may shift |
| `officially_announced` | Reserved for future gazette imports |
| `fixed_historical_pair` | One-time historical EC↔GC pair |

## Files

| File | Contents | Verification |
|------|----------|--------------|
| `sources.json` | Master bibliography | — |
| `months.json` | 13 months, multilingual names | verified |
| `weekdays.json` | 7 weekdays | verified |
| `geez_numerals.json` | Glyphs + examples | verified (calendar range) |
| `calendar_test_vectors.json` | 204 sampled JDN triples from EOTC suite (full suite 4936 matched offline) | verified |
| `fixed_holidays.json` | National/orthodox fixed + Genna rule | verified |
| `movable_feasts.json` | Offset rules from Nenewe | verified |
| `fasting_periods.json` | Fast taxonomy | verified |
| `orthodox_saints.json` | Day-of-month commemorations | verified tradition table |
| `national_holidays.json` | Public holiday index | verified |
| `regional_festivals.json` | Irreecha, Ashenda | approximate / cross_checked |
| `islamic_events.json` | Mawlid, Ramadan, Eids | approximate_calculated |
| `historical_events.json` | Adwa, Liberation, Derg, Millennium | verified public record |

## Attribution

- Conversion oracle samples derived from **natinael96/EOTCDevAPI** `spec/conformance.json` (MIT).  
- Holiday taxonomy cross-checked with **MelakuDemeke/kenat** (MIT).  
- Epoch constant aligned with **Yaredt/ethiopic-primitives** (MIT).  
- Sinksar full narrative texts were **not** vendored (Apache-2.0 NOTICE + size); commemorations use EthioCal’s existing monthly table.  
- TadesseAngaw/bahire-hasab was **not** copied (redistribute-without-modification terms).

## Runtime binding

| Concern | Implementation |
|---------|----------------|
| Conversion / BH / Geez / time | Dart engines (not JSON) |
| Holiday list for UI | `HolidayEngine.getHolidaysForYear` (enriched from research) |
| Dataset access | `CalendarDataCatalog` |
| Provenance theme | `CalendarDataTheme` + Settings → Calendar Accuracy |
| User events DB | Unchanged SQLite / preferences — no migration required |

## Deep audit notes

Per-repo source inspection (README + code + tests + licenses):

- `research_notes/Ethiopian calendar GitHub audit/batch1_abushakir_kenat_ethiocal.md`
- `research_notes/Ethiopian calendar GitHub audit/batch2_calendar_api_primitives.md`
- `research_notes/Ethiopian calendar GitHub audit/batch3_bahire_eotc_kenatpy.md`
- Synthesis: `reports/Ethiopian calendar GitHub audit.md`
