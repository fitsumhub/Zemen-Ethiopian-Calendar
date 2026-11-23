# Zemen football proxy (Cloudflare Worker)

Flutter Web cannot call TheSportsDB (and some badge CDNs) directly because those
hosts omit CORS headers. This Worker forwards JSON + image requests and adds CORS.

## Routes

| Path | Upstream |
|------|----------|
| `/sportsdb/*` | `https://www.thesportsdb.com/*` |
| `/espn/*` | `https://site.api.espn.com/*` |
| `/openliga/*` | `https://api.openligadb.de/*` |
| `/image?url=` | allowlisted badge/crest hosts |
| `/health` | liveness JSON |

## Local development

```bash
cd workers/football-proxy
npm install
npm run dev
```

Then run Flutter Web (default proxy `http://127.0.0.1:8787`):

```bash
flutter run -d chrome
```

Custom origin:

```bash
flutter run -d chrome --dart-define=FOOTBALL_PROXY_BASE=https://your-worker.example
```

Mobile / desktop builds keep calling upstream APIs directly (no proxy).
