# EOTCDev API

An open, free REST API for the **Ethiopian Orthodox Tewahedo Church calendar** —
Ethiopian↔Gregorian date conversion, fasting-day status, fasting periods, feast dates,
and a date-level bridge between the Gitsawe, Sinksar, and Bible.

Coptic developers have [`coptic.io`](https://coptic.io) and `katameros-api` to build on.
EOTC has content mega-apps but no open backend. This is that backend: **infrastructure, not another app.**

No auth. No API key. No database. The public deployment uses a generous anonymous
rate limit to prevent abuse.

```bash
curl https://eotcdev-api.natinael-96.workers.dev/v1/today
```

```json
{
  "gregorian": { "date": "2026-04-12" },
  "ethiopic":  { "date": "2018-08-04", "monthName": { "amharic": "ሚያዝያ" } },
  "weekday":   { "amharic": "እሑድ", "english": "Sunday" },
  "fasting":   { "isFasting": false, "reason": "Not a fasting day." },
  "feasts":    [ { "amharic": "ትንሣኤ", "english": "Easter (Resurrection)" } ]
}
```

## Two implementations, one behaviour

| | Stack | Runs on |
|---|---|---|
| **`ts/`** | TypeScript + Hono | Cloudflare Workers (free tier), Node, Deno, Bun |
| **`py/`** | Python + FastAPI | Any host; auto Swagger UI at `/docs` |

They are not "a port and a copy" — they are held identical by tests:

- **`spec/conformance.json`** — 9,154 golden vectors. Both suites assert against it.
- **`spec/responses.json`** — every route's exact HTTP response. The Python suite replays every fixture route and asserts byte-identical JSON, **including error bodies and status codes**.

Change one implementation without the other and a build fails.

## Endpoints

| Endpoint | Description |
|---|---|
| `GET /v1/today` | Today, fully described. `?tz=Africa/Addis_Ababa` |
| `GET /v1/date/{date}` | Describe any date. `?calendar=gregorian\|ethiopian` |
| `GET /v1/convert/{date}` | Convert between calendars |
| `GET /v1/fasting/{date}` | Is it a fasting day, and **why** |
| `GET /v1/fasts/{year}` | All fasting periods of an Ethiopian year |
| `GET /v1/feasts/{year}` | All feasts. `?type=all\|movable\|fixed` |
| `GET /v1/feasts/{year}/{key}` | One feast resolved for a year, by key, name, or alias |
| `GET /v1/feasts/search` | Find a feast by any of its names, homophone-aware (ትንሳኤ finds ትንሣኤ). `?q=&year=` |
| `GET /v1/upcoming` | Upcoming feasts and fasts, limited to the next 30 days. `?days=30&type=all\|feasts\|fasts` |
| `GET /v1/calendar/range` | Describe any date range, up to 366 days. `?start=&end=` |
| `GET /v1/bahire-hasab
