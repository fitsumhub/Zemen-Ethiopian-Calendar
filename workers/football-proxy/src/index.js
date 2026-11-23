/**
 * Zemen football API + image CORS proxy.
 *
 * Routes:
 *   GET /sportsdb/*  → https://www.thesportsdb.com/*
 *   GET /espn/*      → https://site.api.espn.com/*
 *   GET /openliga/*  → https://api.openligadb.de/*
 *   GET /image?url=  → allowlisted image hosts (badges/crests)
 *   GET /privacy-policy.html → hosted privacy policy for Play Console
 *   GET /health      → { ok: true }
 *
 * Keeps browser clients free of direct TheSportsDB CORS failures while
 * preserving path/query compatibility with FootballApiService.
 */

const PRIVACY_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Zemen: Ethiopian Calendar — Privacy Policy</title>
  <style>
    :root { color-scheme: light dark; }
    body {
      font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
      line-height: 1.55;
      max-width: 780px;
      margin: 0 auto;
      padding: 28px 18px 64px;
      color: #1a1a1a;
      background: #f7f7f8;
    }
    @media (prefers-color-scheme: dark) {
      body { color: #eee; background: #121212; }
      a { color: #9ecbff; }
    }
    h1 { font-size: 1.75rem; margin-bottom: 0.15rem; }
    .tagline { opacity: 0.8; font-style: italic; margin-bottom: 0.75rem; }
    .meta { opacity: 0.75; margin-bottom: 1.5rem; }
    h2 { font-size: 1.15rem; margin-top: 1.75rem; }
    ul { padding-left: 1.2rem; }
  </style>
</head>
<body>
  <h1>Zemen: Ethiopian Calendar · ዘመን Privacy Policy</h1>
  <p class="tagline">Your Time. Your Tradition. Your Calendar.</p>
  <p class="meta">Effective date: November 15, 2026 · Package: com.zemen.calendar</p>
  <p>
    Zemen: Ethiopian Calendar (“the App”) is an Ethiopian &amp; Gregorian calendar application.
    This policy explains what data we process and why.
  </p>
  <h2>1. Summary</h2>
  <ul>
    <li>Calendar math, holidays, fasting, and your personal events stay on your device.</li>
    <li>Optional ads (Google AdMob) may use advertising identifiers after consent where required.</li>
    <li>Optional football scores use public third-party APIs when you open that tab.</li>
  </ul>
  <h2>2. Data we process</h2>
  <ul>
    <li><strong>On-device:</strong> preferences, events/reminders, widget payloads.</li>
    <li><strong>Ads (optional):</strong> device advertising ID, coarse location/IP as provided by the ad SDK, crash/diagnostic signals from Google Mobile Ads — subject to your consent choices (UMP).</li>
    <li><strong>Network:</strong> football fixture requests when you use Football; no account is required.</li>
  </ul>
  <h2>3. Permissions</h2>
  <ul>
    <li>Notifications — event and holiday reminders you enable.</li>
    <li>Internet — ads, consent forms, and optional live football data.</li>
  </ul>
  <h2>4. Children’s privacy</h2>
  <p>The App is not directed at children under 13. We do not knowingly collect personal information from children.</p>
  <h2>5. Contact</h2>
  <p>Questions about this policy: use the in-app Settings → Privacy section or your Play Store listing contact email (aplusethiopia1@gmail.com).</p>
  <h2>6. Changes</h2>
  <p>We may update this policy; the effective date above will change when we do.</p>
</body>
</html>`;

const IMAGE_HOST_ALLOWLIST = [
  'www.thesportsdb.com',
  'thesportsdb.com',
  'r2.thesportsdb.com',
  'a.espncdn.com',
  'a1.espncdn.com',
  'a2.espncdn.com',
  'a3.espncdn.com',
  'a4.espncdn.com',
  'secure.espncdn.com',
  'media.api-sports.io',
  'media-4.api-sports.io',
];

function corsHeaders(request, env) {
  const allowed = (env.ALLOWED_ORIGINS || '*').trim();
  const origin = request.headers.get('Origin') || '';
  let allowOrigin = '*';
  if (allowed !== '*') {
    const list = allowed.split(',').map((s) => s.trim()).filter(Boolean);
    if (origin && list.includes(origin)) allowOrigin = origin;
    else if (list.length > 0) allowOrigin = list[0];
  } else if (origin) {
    allowOrigin = origin;
  }
  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
    'Access-Control-Allow-Headers': 'Accept, Content-Type, User-Agent',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
}

async function proxyJson(targetUrl, request, cors) {
  const upstream = await fetch(targetUrl, {
    method: 'GET',
    headers: {
      Accept: 'application/json',
      'User-Agent': 'ZemenFootballProxy/1.0',
    },
    cf: {
      cacheTtl: 60,
      cacheEverything: false,
    },
  });

  const body = await upstream.arrayBuffer();
  const headers = new Headers(cors);
  headers.set(
    'Content-Type',
    upstream.headers.get('Content-Type') || 'application/json; charset=utf-8',
  );
  headers.set('Cache-Control', 'public, max-age=60');
  headers.set('X-Proxy-Status', String(upstream.status));
  return new Response(body, { status: upstream.status, headers });
}

async function proxyImage(targetUrl, cors) {
  const upstream = await fetch(targetUrl, {
    method: 'GET',
    headers: {
      Accept: 'image/*,*/*',
      'User-Agent': 'ZemenFootballProxy/1.0',
    },
    cf: {
      cacheTtl: 86400,
      cacheEverything: true,
    },
  });
  const body = await upstream.arrayBuffer();
  const headers = new Headers(cors);
  headers.set(
    'Content-Type',
    upstream.headers.get('Content-Type') || 'image/png',
  );
  headers.set('Cache-Control', 'public, max-age=86400');
  return new Response(body, { status: upstream.status, headers });
}

function isAllowedImageHost(hostname) {
  const host = hostname.toLowerCase();
  return IMAGE_HOST_ALLOWLIST.some(
    (allowed) => host === allowed || host.endsWith(`.${allowed}`),
  );
}

export default {
  async fetch(request, env) {
    const cors = corsHeaders(request, env);
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors });
    }
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response('Method not allowed', { status: 405, headers: cors });
    }

    const url = new URL(request.url);

    if (url.pathname === '/' || url.pathname === '/health') {
      return new Response(
        JSON.stringify({
          ok: true,
          service: 'zemen-football-proxy',
          routes: [
            '/sportsdb/*',
            '/espn/*',
            '/openliga/*',
            '/image?url=',
            '/privacy-policy.html',
          ],
        }),
        {
          status: 200,
          headers: { ...cors, 'Content-Type': 'application/json' },
        },
      );
    }

    if (
      url.pathname === '/privacy-policy.html' ||
      url.pathname === '/privacy' ||
      url.pathname === '/privacy-policy'
    ) {
      return new Response(PRIVACY_HTML, {
        status: 200,
        headers: {
          ...cors,
          'Content-Type': 'text/html; charset=utf-8',
          'Cache-Control': 'public, max-age=3600',
        },
      });
    }

    try {
      if (url.pathname.startsWith('/sportsdb/')) {
        const path = url.pathname.replace(/^\/sportsdb/, '');
        // Keep free key in path: /api/v1/json/123/...
        // If caller omitted key segment, inject env key.
        let rewritten = path;
        if (path.startsWith('/api/v1/json/') === false) {
          const key = env.SPORTSDB_API_KEY || '123';
          rewritten = `/api/v1/json/${key}${path.startsWith('/') ? path : `/${path}`}`;
        }
        const target = `https://www.thesportsdb.com${rewritten}${url.search}`;
        return await proxyJson(target, request, cors);
      }

      if (url.pathname.startsWith('/espn/')) {
        const path = url.pathname.replace(/^\/espn/, '');
        const target = `https://site.api.espn.com${path}${url.search}`;
        return await proxyJson(target, request, cors);
      }

      if (url.pathname.startsWith('/openliga/')) {
        const path = url.pathname.replace(/^\/openliga/, '');
        const target = `https://api.openligadb.de${path}${url.search}`;
        return await proxyJson(target, request, cors);
      }

      if (url.pathname === '/image') {
        const raw = url.searchParams.get('url');
        if (!raw) {
          return new Response('Missing url', { status: 400, headers: cors });
        }
        let target;
        try {
          target = new URL(raw);
        } catch (_) {
          return new Response('Invalid url', { status: 400, headers: cors });
        }
        if (target.protocol !== 'https:' && target.protocol !== 'http:') {
          return new Response('Unsupported protocol', { status: 400, headers: cors });
        }
        if (!isAllowedImageHost(target.hostname)) {
          return new Response('Host not allowed', { status: 403, headers: cors });
        }
        return await proxyImage(target.toString(), cors);
      }

      return new Response('Not found', { status: 404, headers: cors });
    } catch (err) {
      return new Response(
        JSON.stringify({ error: 'proxy_failed', message: String(err) }),
        {
          status: 502,
          headers: { ...cors, 'Content-Type': 'application/json' },
        },
      );
    }
  },
};
