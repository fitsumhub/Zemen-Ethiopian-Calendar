import 'football_api_service.dart';
import 'football_cache.dart';
import 'football_data.dart';
import 'football_refresh_manager.dart';

/// Unified football data access: free providers → normalized models → disk cache.
class FootballRepository {
  FootballRepository({
    FootballApiService? api,
    FootballDiskCache? cache,
    FootballRefreshManager? refresh,
  })  : _api = api ?? FootballApiService(),
        _cache = cache ?? FootballDiskCache.instance,
        _refresh = refresh ?? FootballRefreshManager.instance;

  final FootballApiService _api;
  final FootballDiskCache _cache;
  final FootballRefreshManager _refresh;

  FootballApiService get api => _api;
  FootballRefreshManager get refreshManager => _refresh;

  void dispose() => _api.dispose();

  /// Instant disk/offline peek — never hits the network.
  Future<FootballLeague?> peekCache(String leagueId) async {
    final disk = await _cache.loadLeagueSnapshot(leagueId);
    if (disk != null) return disk;
    final offline = FootballData.offlineById(leagueId);
    if (offline == null) return null;
    return offline.copyWith(
      sourceLabel: 'Offline · verified schedule',
      fetchedAt: offline.fetchedAt ?? DateTime.now(),
    );
  }

  /// Load league: prefer live APIs, fall back to disk then offline.
  /// Never clears valid content on failure.
  Future<FootballLeague> getLeague(
    String leagueId, {
    bool forceRefresh = false,
    String? season,
  }) async {
    final key = 'league:$leagueId${season != null ? ':$season' : ''}';

    if (!forceRefresh) {
      try {
        final live = await _api.fetchLeague(leagueId, season: season);
        await _cache.saveLeagueSnapshot(
          leagueId: leagueId,
          league: live,
          kind: FootballSourceKind.live,
        );
        _refresh.setHasLiveMatches(
          live.isLive || live.matches.any((m) => m.isLive),
        );
        return live;
      } catch (_) {
        final disk = await _cache.loadLeagueSnapshot(leagueId);
        if (disk != null) return disk;
        final offline = FootballData.offlineById(leagueId);
        if (offline != null) {
          return offline.copyWith(
            sourceLabel: 'Offline · verified schedule',
            fetchedAt: DateTime.now(),
          );
        }
        rethrow;
      }
    }

    try {
      final fresh = await _refresh.runSingleFlight(
        key,
        () => _api.fetchLeague(leagueId, forceRefresh: true, season: season),
        force: true,
      );
      await _cache.saveLeagueSnapshot(
        leagueId: leagueId,
        league: fresh,
        kind: FootballSourceKind.live,
      );
      _refresh.setHasLiveMatches(
        fresh.isLive || fresh.matches.any((m) => m.isLive),
      );
      return fresh;
    } on StateError catch (e) {
      if (e.message == 'deduped' || e.message == 'throttled') {
        final disk = await _cache.loadLeagueSnapshot(leagueId);
        if (disk != null) return disk;
        return _api.fetchLeague(leagueId, season: season);
      }
      rethrow;
    } catch (_) {
      final disk = await _cache.loadLeagueSnapshot(leagueId);
      if (disk != null) return disk;
      final offline = FootballData.offlineById(leagueId);
      if (offline != null) {
        return offline.copyWith(
          sourceLabel: 'Offline · verified schedule',
          fetchedAt: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  /// Soft refresh: keep previous [previous] on failure.
  /// Prefer in-memory previous over offline stubs so a failed refresh never
  /// replaces richer live content with a thinner fallback.
  Future<FootballLeague> refreshLeague(
    String leagueId, {
    FootballLeague? previous,
    String? season,
  }) async {
    final key = 'league:$leagueId${season != null ? ':$season' : ''}';
    try {
      final fresh = await _refresh.runSingleFlight(
        key,
        () => _api.fetchLeague(
          leagueId,
          forceRefresh: true,
          season: season,
          // Ethiopian Premier League must stay usable offline; other leagues
          // keep soft-refresh strict so a failed pull never replaces live data
          // with stubs (caller still keeps [previous] on throw).
          allowOfflineFallback: leagueId == 'epl_eth',
        ),
        force: true,
      );
      await _cache.saveLeagueSnapshot(
        leagueId: leagueId,
        league: fresh,
        kind: FootballSourceKind.live,
      );
      _refresh.setHasLiveMatches(
        fresh.isLive || fresh.matches.any((m) => m.isLive),
      );
      return fresh;
    } catch (_) {
      if (previous != null) {
        final label = previous.sourceLabel ?? '';
        final cachedLabel = label.contains('Cached') || label.contains('Offline')
            ? label
            : 'Cached · $label';
        return previous.copyWith(sourceLabel: cachedLabel);
      }
      final disk = await _cache.loadLeagueSnapshot(leagueId);
      if (disk != null) return disk;
      final offline = FootballData.offlineById(leagueId);
      if (offline != null) {
        return offline.copyWith(
          sourceLabel: 'Offline · verified schedule',
          fetchedAt: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  Future<FootballMatch> getMatchDetails(FootballMatch match) {
    return _api.fetchMatchDetails(match);
  }

  Future<List<FootballMatch>> getLiveMatches() => _api.fetchLiveMatches();

  Future<List<FootballMatch>> getTodayMatches() => _api.fetchTodayMatches();

  void clearMemoryCaches() => _api.clearAllCaches();
}
