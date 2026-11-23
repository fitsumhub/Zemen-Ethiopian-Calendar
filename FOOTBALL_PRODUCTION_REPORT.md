# Football Module — Production Upgrade Delivery Report

**Date:** 2026-11-15  
**Project:** EthioCal Pro (Flutter)

## Summary

The Football module was audited and upgraded for production use with free data sources only, honest match details (no fabricated events/stats/H2H), persistent caching, intelligent refresh, and expanded competition coverage verified against live ESPN/OpenLigaDB endpoints.

## Files inspected

- `lib/features/football/football_api_service.dart`
- `lib/features/football/football_data.dart`
- `lib/features/football/football_providers.dart`
- `lib/features/football/football_screen.dart`
- `lib/features/football/league_detail_screen.dart`
- `lib/features/football/match_detail_screen.dart`
- `lib/features/football/models/football_models.dart`
- `test/football_test.dart`

## Files created

- `lib/features/football/football_cache.dart` — SharedPreferences disk cache (LIVE/CACHED labeling)
- `lib/features/football/football_refresh_manager.dart` — lifecycle-aware refresh, single-flight, backoff
- `lib/features/football/football_repository.dart` — unified free-provider → model → cache access
- `FOOTBALL_PRODUCTION_REPORT.md` — this report

## Files modified

- `football_api_service.dart` — tighter ESPN window, OpenLigaDB, honest details, 429/timeout handling
- `football_data.dart` — expanded catalog + `LeagueSource.openLigaLeague`
- `football_providers.dart` — repository wiring, season override, refresh listeners
- `football_models.dart` — HT scores, `stableKey`, honest `MatchStatistics` defaults
- `match_detail_screen.dart` — empty states for missing lineups/stats/H2H (no fake data)
- `league_detail_screen.dart` — season selector (where SportsDB seasons exist)
- `test/football_test.dart` — production resilience + UI smoke tests

## API providers integrated

| Provider | Status | Use |
|----------|--------|-----|
| **ESPN public** | Primary | Live scores, fixtures, standings, match summaries |
| **TheSportsDB** (free key `123`) | Secondary | Historical events, tables, seasons |
| **OpenLigaDB** | Supplemental | Bundesliga matches + table (`bl1`) |
| football-data.org | **Not integrated** | Requires API token; free tier has commercial restrictions |
| OpenFootball | **Not integrated** | Static GitHub dumps; not used as live API |
| CAF Confederation Cup ESPN slug | **Skipped** | Endpoint returned empty/minimal payload (~278 B) |

No paid subscriptions. No scraping.

## Supported competition coverage (verified ESPN HTTP 200)

| ID | Competition | Providers |
|----|-------------|-----------|
| `epl_eth` | Ethiopian Premier League | TheSportsDB + verified offline |
| `epl_eng` | English Premier League | ESPN + TheSportsDB |
| `ucl` | UEFA Champions League | ESPN + TheSportsDB |
| `europa` | UEFA Europa League | ESPN + TheSportsDB |
| `conference` | UEFA Conference League | ESPN |
| `bundesliga` | Bundesliga | ESPN + TheSportsDB + OpenLigaDB |
| `laliga` | La Liga | ESPN + TheSportsDB |
| `seriea` | Serie A | ESPN + TheSportsDB |
| `ligue1` | Ligue 1 | ESPN + TheSportsDB |
| `caf_cl` | CAF Champions League | ESPN + TheSportsDB |
| `world_cup` | FIFA World Cup | ESPN + TheSportsDB (sparse outside tournament) |

Competitions are listed only where at least one free provider mapping exists.

## Caching

- In-memory TTL (~3 minutes) in `FootballApiService`
- Persistent snapshots via `FootballDiskCache` (SharedPreferences JSON)
- Instant offline/disk peek before network sync
- Soft refresh never clears valid on-screen content on failure
- Source labels distinguish **Live**, **Cached**, and **Offline**

## Refresh

- `FootballRefreshManager`: 60s when live matches exist, ~4 min when idle
- Pauses polling when app is backgrounded; syncs on resume
- Single-flight + throttle + exponential backoff; respects HTTP 429 / Retry-After
- Manual refresh keeps previous data visible (spinner only)

## Offline behavior

- Ethiopian Premier League: full verified schedule/standings always available offline
- European leagues: last successful disk snapshot when present; otherwise empty/API-honest UI
- Match center: empty states when events/lineups/stats/H2H are unavailable (never invented)

## Tests executed

```
flutter pub get
flutter analyze lib/features/football   → No issues found
flutter test test/football_test.dart    → All tests passed (22)
```

Covered: catalog honesty, offline first launch, soft refresh retention, disk cache, 429 retry, malformed JSON, empty responses, request dedupe, refresh intervals, league/match UI smoke, empty match-detail tabs.

## Remaining limitations

- Free ESPN scoreboard windows are intentionally narrow (−3…+14 days + sparse monthly samples) to avoid rate limits; full-season calendars for Europe may be incomplete vs paid feeds.
- TheSportsDB free tier is throttled and often lacks rich timelines/lineups.
- World Cup / CAF data is sparse outside active competition windows.
- CAF Confederation Cup not listed (provider payload empty at verification time).
- `flutter build apk --debug` was attempted; Gradle failed in this environment (analyze + 22 unit/widget tests passed).

## Known provider restrictions

- ESPN public endpoints: undocumented, rate-limited, not a licensed commercial feed.
- TheSportsDB free key: limited quota; premium features unavailable.
- OpenLigaDB: Germany-focused; used for Bundesliga only.
- Do not assume commercial redistribution rights without reviewing each provider’s terms.
