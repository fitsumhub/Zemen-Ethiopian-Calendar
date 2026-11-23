import 'package:flutter/foundation.dart';

/// Resolves football API and crest URLs for mobile vs Flutter Web.
///
/// TheSportsDB (and some badge CDNs) do not send CORS headers, so browsers
/// block direct calls. On web we route through the local/deployed
/// `workers/football-proxy` Worker.
///
/// Override the proxy origin at build/run time:
/// `flutter run -d chrome --dart-define=FOOTBALL_PROXY_BASE=https://your-worker.example`
class FootballNetworkConfig {
  FootballNetworkConfig._();

  static const String _proxyFromEnv =
      String.fromEnvironment('FOOTBALL_PROXY_BASE');

  /// Deployed Cloudflare Worker (CORS + privacy hosting).
  static const String productionProxy =
      'https://zemen-football-proxy.aplusethiopia1.workers.dev';

  /// Local Wrangler address for offline proxy development.
  static const String defaultLocalProxy = 'http://127.0.0.1:8787';

  static bool get useProxy => kIsWeb;

  /// True when an explicit `FOOTBALL_PROXY_BASE` was passed at build time.
  static bool get hasConfiguredProxy => _proxyFromEnv.trim().isNotEmpty;

  /// Debug hint only when forcing local Wrangler without a running proxy.
  static bool get needsProxySetupHint =>
      kIsWeb &&
      kDebugMode &&
      _proxyFromEnv.trim() == defaultLocalProxy;

  static String get proxyBase {
    final raw = _proxyFromEnv.trim().isNotEmpty
        ? _proxyFromEnv.trim()
        : productionProxy;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static String get sportsDbBase {
    if (useProxy) return '$proxyBase/sportsdb/api/v1/json/123';
    return 'https://www.thesportsdb.com/api/v1/json/123';
  }

  static String get espnBase {
    if (useProxy) return '$proxyBase/espn/apis';
    return 'https://site.api.espn.com/apis';
  }

  static String get openLigaBase {
    if (useProxy) return '$proxyBase/openliga';
    return 'https://api.openligadb.de';
  }

  /// Rewrites remote crest/badge URLs through the image proxy on web.
  static String? imageUrl(String? url) {
    if (url == null || url.isEmpty) return url;
    if (!useProxy) return url;
    if (url.startsWith(proxyBase)) return url;
    // Prefer local assets when possible — callers still pass assetPath separately.
    return '$proxyBase/image?url=${Uri.encodeQueryComponent(url)}';
  }
}
