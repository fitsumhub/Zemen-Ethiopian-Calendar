import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/calendar/ethiopian_calendar_engine.dart';
import '../../core/calendar/gregorian_date.dart';
import 'football_data.dart';
import 'football_network_config.dart';

/// Production football service — free providers only (ESPN, TheSportsDB, OpenLigaDB).
/// Never fabricates match events, stats, or H2H. Offline backbone is Ethiopian-only
/// by default; European offline stubs are used only when live providers return nothing.
///
/// On Flutter Web, all upstream hosts are reached via [FootballNetworkConfig]
/// (Cloudflare Worker proxy) to avoid browser CORS failures.
class FootballApiService {
  FootballApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static String get _espnBase => FootballNetworkConfig.espnBase;
  static String get _sportsDbBase => FootballNetworkConfig.sportsDbBase;
  static String get _openLigaBase => FootballNetworkConfig.openLigaBase;
  static const _cacheTtl = Duration(minutes: 3);
  static const _requestTimeout = Duration(seconds: 15);

  final Map<String, _CacheEntry> _cache = {};
  final Map<String, FootballMatch> _matchCache = {};
  final Map<String, Future<FootballLeague>> _inflightLeagues = {};

  /// Serializes free-tier SportsDB calls to reduce 429 storms.
  static Future<void> _sportsDbGate = Future<void>.value();
  static const _sportsDbMinGap = Duration(milliseconds: 320);

  static bool get _isTesting =>
      const bool.fromEnvironment('FLUTTER_TEST') ||
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  static Future<void> _testAwareDelay(Duration duration) async {
    if (!_isTesting) {
      await Future<void>.delayed(duration);
    }
  }

  // Optional user-provided keys (unused for free defaults).
  String? sportApiKey;
  String? goalApiKey;
  String? apiFootballKey;

  void clearLeagueCache(String leagueId) {
    _cache.remove(leagueId);
    _matchCache.removeWhere((k, _) => k.startsWith('${leagueId}_'));
  }

  void clearAllCaches() {
    _cache.clear();
    _matchCache.clear();
  }

  /// Fetch a complete league: free APIs + optional offline backbone.
  /// [season] optionally narrows TheSportsDB queries (e.g. `2025-2026`).
  /// When [allowOfflineFallback] is false, failures with no live provider
  /// data throw instead of returning static stubs (used by soft refresh).
  Future<FootballLeague> fetchLeague(
    String leagueId, {
    bool forceRefresh = false,
    String? season,
    bool allowOfflineFallback = true,
  }) async {
    final meta = FootballData.catalogById(leagueId);
    if (meta == null) {
      throw StateError('Unknown league: $leagueId');
    }

    final cacheKey = season == null ? leagueId : '$leagueId|$season';
    if (forceRefresh) {
      clearLeagueCache(leagueId);
      _cache.remove(cacheKey);
      _inflightLeagues.remove(cacheKey);
    } else {
      final hit = _cache[cacheKey] ?? _cache[leagueId];
      if (hit != null && DateTime.now().difference(hit.at) < _cacheTtl) {
        return hit.league;
      }
      final inflight = _inflightLeagues[cacheKey];
      if (inflight != null) return inflight;
    }

    final future = _fetchLeagueUncached(
      meta,
      leagueId: leagueId,
      cacheKey: cacheKey,
      season: season,
      allowOfflineFallback: allowOfflineFallback,
    );
    _inflightLeagues[cacheKey] = future;
    try {
      return await future;
    } finally {
      _inflightLeagues.remove(cacheKey);
    }
  }

  Future<FootballLeague> _fetchLeagueUncached(
    FootballLeague meta, {
    required String leagueId,
    required String cacheKey,
    String? season,
    bool allowOfflineFallback = true,
  }) async {

    final source = FootballData.sourceFor(leagueId);
    final effectiveSource = season == null
        ? source
        : LeagueSource(
            espnSlug: source.espnSlug,
            sportsDbId: source.sportsDbId,
            sportsDbSeasons: [season],
            openLigaLeague: source.openLigaLeague,
          );
    final sources = <String>[];
    Object? lastError;
    FootballLeague? espn;
    FootballLeague? sportsDb;
    FootballLeague? openLiga;

    if (effectiveSource.espnSlug != null) {
      try {
        espn = await _fetchEspnLeague(meta, effectiveSource.espnSlug!);
        sources.add('ESPN');
      } catch (e) {
        lastError = e;
      }
    }

    if (effectiveSource.sportsDbId != null) {
      try {
        sportsDb = await _fetchSportsDbLeague(meta, effectiveSource);
        sources.add('TheSportsDB');
      } catch (e) {
        lastError ??= e;
      }
    }

    if (effectiveSource.openLigaLeague != null) {
      try {
        openLiga =
            await _fetchOpenLigaLeague(meta, effectiveSource.openLigaLeague!);
        sources.add('OpenLigaDB');
      } catch (e) {
        lastError ??= e;
      }
    }

    final offline = FootballData.offlineById(leagueId) ?? meta;
    final liveLayers = <List<FootballMatch>>[
      if (espn != null) espn.matches,
      if (sportsDb != null) sportsDb.matches,
      if (openLiga != null) openLiga.matches,
    ];
    final liveFixtureCount =
        liveLayers.fold<int>(0, (sum, layer) => sum + layer.length);
    final hasLiveFixtures = liveFixtureCount > 0;
    final hasLiveStandings = espn?.standings.isNotEmpty == true ||
        openLiga?.standings.isNotEmpty == true ||
        sportsDb?.standings.isNotEmpty == true;
    if (!allowOfflineFallback && !hasLiveFixtures && !hasLiveStandings) {
      final err = lastError ?? Exception('All free football providers unavailable');
      if (err is Exception) throw err;
      if (err is Error) throw err;
      throw Exception(err.toString());
    }
    // TheSportsDB's Ethiopian coverage is sparse (often <20 events and a
    // truncated table). Keep the verified offline backbone underneath and let
    // live rows win on merge so scores/fixtures stay accurate without wiping
    // the rest of the season.
    final ethSparseLive = leagueId == 'epl_eth' && liveFixtureCount > 0 && liveFixtureCount < 40;
    final useOffline =
        allowOfflineFallback && (!hasLiveFixtures || ethSparseLive);

    final mergedMatches = _mergeMatchLists([
      ...liveLayers,
      if (useOffline) offline.matches,
    ]);
    final rawStandings = (espn?.standings.isNotEmpty == true)
        ? espn!.standings
        : (openLiga?.standings.isNotEmpty == true)
            ? openLiga!.standings
            : (sportsDb?.standings.isNotEmpty == true)
                ? sportsDb!.standings
                : const <StandingRow>[];
    final standings = _coalesceStandings(
      live: rawStandings,
      offline: allowOfflineFallback ? offline.standings : const <StandingRow>[],
      leagueId: leagueId,
    );
    final teams = (standings.isNotEmpty)
        ? standings.map((s) => s.team).toList()
        : (espn?.teams.isNotEmpty == true)
            ? espn!.teams
            : (sportsDb?.teams.isNotEmpty == true)
                ? sportsDb!.teams
                : (allowOfflineFallback && offline.teams.isNotEmpty
                    ? offline.teams
                    : const <FootballTeam>[]);
    final scorers = (espn?.topScorers.isNotEmpty == true)
        ? espn!.topScorers
        : (allowOfflineFallback ? offline.topScorers : const <TopScorer>[]);

    if (mergedMatches.isEmpty && standings.isEmpty && lastError != null) {
      final err = lastError;
      if (err is Exception) throw err;
      if (err is Error) throw err;
      throw Exception(err.toString());
    }

    final label = sources.isEmpty
        ? 'Offline · verified schedule'
        : hasLiveFixtures
            ? '${sources.join(' + ')} · Live'
            : '${sources.join(' + ')} · Cached backbone';

    final league = meta.copyWith(
      matches: mergedMatches,
      standings: standings,
      teams: teams,
      topScorers: scorers,
      isLive: mergedMatches.any((m) => m.isLive),
      fetchedAt: DateTime.now(),
      sourceLabel: label,
      season: season ?? meta.season,
      country: meta.country,
    );
    _cache[cacheKey] = _CacheEntry(league, DateTime.now());
    return league;
  }

  List<FootballMatch> _mergeMatchLists(List<List<FootballMatch>> layers) {
    final byKey = <String, FootballMatch>{};
    // Later layers fill gaps; earlier (live) layers win on conflict.
    for (final layer in layers.reversed) {
      for (final m in layer) {
        final key = _matchMergeKey(m);
        byKey.putIfAbsent(key, () => m);
      }
    }
    for (final layer in layers) {
      for (final m in layer) {
        final key = _matchMergeKey(m);
        final existing = byKey[key];
        if (existing == null) {
          byKey[key] = m;
          continue;
        }
        // Prefer live/API scores & ids over offline stubs.
        final preferIncoming = m.isLive ||
            (m.hasScore && !existing.hasScore) ||
            (m.id.isNotEmpty &&
                int.tryParse(m.id) != null &&
                (existing.id.isEmpty || int.tryParse(existing.id) == null));
        if (preferIncoming) {
          byKey[key] = m.copyWith(
            round: m.round ?? existing.round,
            roundLabel: m.roundLabel ?? existing.roundLabel,
            competitionId: m.competitionId.isNotEmpty
                ? m.competitionId
                : existing.competitionId,
            competitionName: m.competitionName.isNotEmpty
                ? m.competitionName
                : existing.competitionName,
          );
        }
      }
    }
    final list = byKey.values.toList()
      ..sort((a, b) {
        final ka = a.kickoff ?? DateTime.fromMillisecondsSinceEpoch(0);
        final kb = b.kickoff ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ka.compareTo(kb);
      });
    return list;
  }

  String _matchMergeKey(FootballMatch m) {
    if (m.id.isNotEmpty && int.tryParse(m.id) != null) return 'id:${m.id}';
    final day = m.kickoff != null
        ? '${m.kickoff!.year}-${m.kickoff!.month}-${m.kickoff!.day}'
        : m.dateHeader;
    return '${_teamAliasKey(m.home.name)}|${_teamAliasKey(m.away.name)}|$day';
  }

  /// Canonical key so "Fasil Kenema" overlays "Fasil Ketema", "CBE SA" → Nigd, etc.
  String _teamAliasKey(String name) {
    final asset = _matchLocalAsset(name);
    if (asset != null) {
      final file = asset.split('/').last;
      return file.replaceAll('.png', '');
    }
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  FootballTeam _resolveKnownTeam(String name, {String? logoUrl}) {
    final key = _teamAliasKey(name);
    final local = FootballData.ethiopianTeams[key];
    if (local != null) {
      return FootballTeam(
        name: local.name,
        mark: local.mark,
        logoAsset: local.logoAsset,
        logoUrl: logoUrl ?? local.logoUrl,
        stadium: local.stadium,
        city: local.city,
        formedYear: local.formedYear,
      );
    }
    return FootballTeam(
      name: name,
      mark: _lettersMark(name),
      logoAsset: _matchLocalAsset(name),
      logoUrl: logoUrl ?? _matchOfficialLogoUrl(name),
    );
  }

  /// Prefer a complete table. Overlay sparse live rows onto the offline backbone.
  List<StandingRow> _coalesceStandings({
    required List<StandingRow> live,
    required List<StandingRow> offline,
    required String leagueId,
  }) {
    if (live.isEmpty) return offline;
    final incomplete = live.length < 12 ||
        (leagueId == 'epl_eth' && live.length < offline.length);
    if (!incomplete || offline.isEmpty) return live;

    final byKey = <String, StandingRow>{};
    for (final row in offline) {
      byKey[_teamAliasKey(row.team.name)] = row;
    }
    for (final row in live) {
      final key = _teamAliasKey(row.team.name);
      final existing = byKey[key];
      byKey[key] = StandingRow(
        rank: row.rank,
        team: existing?.team ?? _resolveKnownTeam(row.team.name, logoUrl: row.team.logoUrl),
        played: row.played,
        won: row.won,
        drawn: row.drawn,
        lost: row.lost,
        goalsFor: row.goalsFor,
        goalsAgainst: row.goalsAgainst,
        gd: row.gd,
        pts: row.pts,
        form: row.form ?? existing?.form,
      );
    }
    final merged = byKey.values.toList()
      ..sort((a, b) {
        final pts = b.pts.compareTo(a.pts);
        if (pts != 0) return pts;
        final gd = b.gd.compareTo(a.gd);
        if (gd != 0) return gd;
        return b.goalsFor.compareTo(a.goalsFor);
      });
    return [
      for (var i = 0; i < merged.length; i++)
        StandingRow(
          rank: i + 1,
          team: merged[i].team,
          played: merged[i].played,
          won: merged[i].won,
          drawn: merged[i].drawn,
          lost: merged[i].lost,
          goalsFor: merged[i].goalsFor,
          goalsAgainst: merged[i].goalsAgainst,
          gd: merged[i].gd,
          pts: merged[i].pts,
          form: merged[i].form,
        ),
    ];
  }

  /// Fetch deep match details from free providers only. Never fabricates events/stats/H2H.
  Future<FootballMatch> fetchMatchDetails(
    FootballMatch match, {
    String? leagueSlug,
  }) async {
    final cacheKey = '${match.competitionId}_${match.id}';
    final cached = _matchCache[cacheKey];
    if (cached != null &&
        (cached.events.isNotEmpty ||
            cached.statistics != null ||
            cached.homeLineup != null)) {
      return cached;
    }

    final slug = leagueSlug ?? _slugForCompetition(match.competitionId);
    if (slug != null && match.id.isNotEmpty && int.tryParse(match.id) != null) {
      try {
        final uri = Uri.parse(
          '$_espnBase/site/v2/sports/soccer/$slug/summary?event=${match.id}',
        );
        final res = await _get(uri);
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          final detailed = _parseEspnMatchSummary(match, json);
          _matchCache[cacheKey] = detailed;
          return detailed;
        }
      } catch (_) {
        // Keep base match; UI shows empty states for missing sections.
      }
    }

    // SportsDB event lookup when id looks non-ESPN numeric and SportsDB-like.
    if (match.id.isNotEmpty && match.id.length >= 6) {
      try {
        final uri = Uri.parse('$_sportsDbBase/lookupevent.php?id=${match.id}');
        final res = await _get(uri);
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          final events = json['events'] as List<dynamic>?;
          if (events != null && events.isNotEmpty) {
            final detailed = _parseSportsDbEventDetails(
              match,
              events.first as Map<String, dynamic>,
            );
            _matchCache[cacheKey] = detailed;
            return detailed;
          }
        }
      } catch (_) {}
    }

    _matchCache[cacheKey] = match;
    return match;
  }

  static const _liveSlugs = [
    'eng.1',
    'uefa.champions',
    'uefa.europa',
    'uefa.europa.conf',
    'esp.1',
    'ger.1',
    'ita.1',
    'fra.1',
    'caf.champions',
    'caf.confed',
    'caf.nations',
    'fifa.world',
  ];

  /// Fetch all live matches across supported ESPN competitions.
  Future<List<FootballMatch>> fetchLiveMatches() async {
    final liveMatches = <FootballMatch>[];

    for (final slug in _liveSlugs) {
      try {
        final uri =
            Uri.parse('$_espnBase/site/v2/sports/soccer/$slug/scoreboard');
        final res = await _get(uri, timeout: const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          final events = (json['events'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();
          for (final e in events) {
            final m =
                _mapEspnEvent(e, _compIdForSlug(slug), _compNameForSlug(slug));
            if (m != null && m.isLive) {
              liveMatches.add(m);
            }
          }
        }
      } catch (_) {
        // Continue to other leagues
      }
    }

    return liveMatches;
  }

  /// Fetch today's matches across supported ESPN competitions.
  Future<List<FootballMatch>> fetchTodayMatches() async {
    final todayMatches = <FootballMatch>[];
    final now = DateTime.now().toUtc();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    for (final slug in _liveSlugs) {
      try {
        final uri = Uri.parse(
          '$_espnBase/site/v2/sports/soccer/$slug/scoreboard?dates=$dateStr',
        );
        final res = await _get(uri, timeout: const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          final events = (json['events'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();
          for (final e in events) {
            final m = _mapEspnEvent(e, _compIdForSlug(slug), _compNameForSlug(slug));
            if (m != null) todayMatches.add(m);
          }
        }
      } catch (_) {
        // Continue
      }
    }

    final localToday = DateTime.now();
    for (final m in FootballData.ethiopianSchedule) {
      final k = m.kickoff;
      if (k != null &&
          k.year == localToday.year &&
          k.month == localToday.month &&
          k.day == localToday.day) {
        todayMatches.add(m);
      }
    }

    return todayMatches;
  }

  // --- PRIVATE IMPLEMENTATION ---

  Future<FootballLeague> _fetchEspnLeague(FootballLeague meta, String slug) async {
    final liveMatches = await _espnFixtures(slug, meta.id, meta.name);
    final standings = await _espnStandings(slug);
    final teams = standings.isNotEmpty ? standings.map((s) => s.team).toList() : meta.teams;
    final scorers = _espnTopScorers(slug, teams);
    final mergedSchedule = _mergeWithYearlySchedule(meta.matches, liveMatches);
    final live = mergedSchedule.any((m) => m.isLive);

    return meta.copyWith(
      matches: mergedSchedule,
      standings: standings.isNotEmpty ? standings : meta.standings,
      teams: teams,
      topScorers: scorers,
      isLive: live,
      fetchedAt: DateTime.now(),
      sourceLabel: 'ESPN · Live',
    );
  }

  List<FootballMatch> _mergeWithYearlySchedule(
    List<FootballMatch> yearlySchedule,
    List<FootballMatch> liveMatches,
  ) {
    if (yearlySchedule.isEmpty) return liveMatches;
    if (liveMatches.isEmpty) return yearlySchedule;

    final result = List<FootballMatch>.from(yearlySchedule);
    for (final live in liveMatches) {
      final idx = result.indexWhere((m) =>
          (m.home.name.toLowerCase() == live.home.name.toLowerCase() &&
              m.away.name.toLowerCase() == live.away.name.toLowerCase()) ||
          m.id == live.id);
      if (idx != -1) {
        result[idx] = live.copyWith(
          round: result[idx].round,
          roundLabel: result[idx].roundLabel,
        );
      } else {
        result.insert(0, live);
      }
    }
    return result;
  }

  Future<List<FootballMatch>> _espnFixtures(
    String slug,
    String competitionId,
    String competitionName,
  ) async {
    final events = <Map<String, dynamic>>[];

    // 1. Direct active scoreboard (contains current gameweek and live games)
    try {
      final baseUri = Uri.parse('$_espnBase/site/v2/sports/soccer/$slug/scoreboard');
      final res = await _get(baseUri, timeout: const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final list = json['events'] as List<dynamic>? ?? const [];
        events.addAll(list.cast<Map<String, dynamic>>());
      }
    } catch (_) {}

    // 2. Surrounding week coverage (recent 2 days + upcoming 7 days)
    final now = DateTime.now().toUtc();
    final dates = <String>{};
    for (var i = -2; i <= 7; i++) {
      final d = now.add(Duration(days: i));
      dates.add(_espnDate(d));
    }

    final dateList = dates.toList()..sort();
    for (var i = 0; i < dateList.length; i += 5) {
      final batch = dateList.sublist(i, (i + 5).clamp(0, dateList.length));
      try {
        final responses = await Future.wait(
          batch.map((date) async {
            try {
              final uri = Uri.parse(
                '$_espnBase/site/v2/sports/soccer/$slug/scoreboard?dates=$date',
              );
              final res = await _get(uri, timeout: const Duration(seconds: 10));
              if (res.statusCode != 200) return <Map<String, dynamic>>[];
              final json = jsonDecode(res.body) as Map<String, dynamic>;
              final list = json['events'] as List<dynamic>? ?? const [];
              return list.cast<Map<String, dynamic>>();
            } catch (_) {
              return <Map<String, dynamic>>[];
            }
          }),
        );
        for (final list in responses) {
          events.addAll(list);
        }
      } catch (_) {
        // Continue other batches if one wave fails.
      }
    }

    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final e in events) {
      final id = '${e['id']}';
      if (seen.add(id)) unique.add(e);
    }

    unique.sort((a, b) {
      final da = DateTime.tryParse('${a['date']}') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse('${b['date']}') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });

    return unique
        .map((e) => _mapEspnEvent(e, competitionId, competitionName))
        .whereType<FootballMatch>()
        .toList();
  }

  FootballMatch? _mapEspnEvent(
    Map<String, dynamic> event, [
    String competitionId = '',
    String competitionName = '',
  ]) {
    final competitions = event['competitions'] as List<dynamic>?;
    if (competitions == null || competitions.isEmpty) return null;
    final comp = competitions.first as Map<String, dynamic>;
    final competitors = (comp['competitors'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    Map<String, dynamic>? home;
    Map<String, dynamic>? away;
    for (final c in competitors) {
      if (c['homeAway'] == 'home') home = c;
      if (c['homeAway'] == 'away') away = c;
    }
    if (home == null || away == null) return null;

    final kickoff = DateTime.tryParse('${event['date']}')?.toLocal();
    final status = (comp['status'] as Map<String, dynamic>?) ??
        (event['status'] as Map<String, dynamic>?) ??
        const {};
    final type = (status['type'] as Map<String, dynamic>?) ?? const {};
    final state = '${type['state'] ?? ''}'.toLowerCase();
    final detail = '${type['detail'] ?? type['shortDetail'] ?? ''}'.toUpperCase();

    MatchPhase phase;
    String? statusLabel;
    String? time;
    String? period;
    int? homeScore;
    int? awayScore;
    int? homePenScore;
    int? awayPenScore;

    if (state == 'in') {
      phase = MatchPhase.live;
      statusLabel = 'LIVE';
      final clock = '${status['displayClock'] ?? ''}'.trim();
      time = clock.isEmpty ? 'LIVE' : clock;
      final periodNum = status['period'];
      if (detail.contains('HT') || detail.contains('HALF')) {
        period = 'HT';
      } else if (periodNum is num) {
        period = periodNum <= 1 ? '1H' : (periodNum == 2 ? '2H' : 'ET');
      } else if (clock.isNotEmpty) {
        period = clock;
      } else {
        period = 'LIVE';
      }
      homeScore = int.tryParse('${home['score']}');
      awayScore = int.tryParse('${away['score']}');
    } else if (state == 'post') {
      if (detail.contains('ABANDON')) {
        phase = MatchPhase.abandoned;
        statusLabel = 'ABD';
      } else if (detail.contains('CANCEL')) {
        phase = MatchPhase.cancelled;
        statusLabel = 'CANC';
      } else if (detail.contains('POSTPON') || detail == 'POST') {
        phase = MatchPhase.postponed;
        statusLabel = 'PPD';
      } else {
        phase = MatchPhase.finished;
        statusLabel = detail.contains('AET')
            ? 'AET'
            : (detail.contains('PEN') ? 'PEN' : 'FT');
        homeScore = int.tryParse('${home['score']}');
        awayScore = int.tryParse('${away['score']}');
      }
    } else if (detail.contains('ABANDON')) {
      phase = MatchPhase.abandoned;
      statusLabel = 'ABD';
    } else if (detail.contains('CANCEL')) {
      phase = MatchPhase.cancelled;
      statusLabel = 'CANC';
    } else if (detail.contains('POSTPON') || detail.contains('POSTP')) {
      phase = MatchPhase.postponed;
      statusLabel = 'PPD';
    } else {
      phase = MatchPhase.scheduled;
      if (kickoff != null) {
        final h = kickoff.hour;
        final m = kickoff.minute.toString().padLeft(2, '0');
        final hour12 = h % 12 == 0 ? 12 : h % 12;
        time = '$hour12:$m';
        period = h >= 12 ? 'PM' : 'AM';
        statusLabel = '$time $period';
      }
    }

    int? penFrom(Map<String, dynamic> competitor) {
      final shootout = competitor['shootoutScore'] ?? competitor['penaltyScore'];
      if (shootout != null) {
        return int.tryParse('$shootout');
      }
      final lines = competitor['linescores'] as List<dynamic>?;
      if (lines != null && lines.length >= 3 && detail.contains('PEN')) {
        final last = lines.last;
        if (last is Map<String, dynamic>) {
          return int.tryParse('${last['value'] ?? last['displayValue'] ?? ''}');
        }
      }
      return null;
    }

    if (detail.contains('PEN')) {
      homePenScore = penFrom(home);
      awayPenScore = penFrom(away);
    }

    final venueObj = comp['venue'] as Map<String, dynamic>?;
    final venueName = venueObj?['fullName'] as String?;
    final venueCity = (venueObj?['address'] as Map<String, dynamic>?)?['city'] as String?;
    final venue = venueName != null
        ? (venueCity != null ? '$venueName, $venueCity' : venueName)
        : null;

    int? htFrom(Map<String, dynamic> competitor) {
      final lines = competitor['linescores'] as List<dynamic>?;
      if (lines == null || lines.isEmpty) return null;
      final first = lines.first;
      if (first is Map<String, dynamic>) {
        return int.tryParse('${first['value'] ?? first['displayValue'] ?? ''}');
      }
      return null;
    }

    return FootballMatch(
      id: '${event['id'] ?? ''}',
      competitionId: competitionId,
      competitionName: competitionName,
      dateHeader: _ethiopianHeader(kickoff ?? DateTime.now()),
      home: _teamFromEspn(home),
      away: _teamFromEspn(away),
      time: time,
      period: period,
      homeScore: homeScore,
      awayScore: awayScore,
      homeHtScore: htFrom(home),
      awayHtScore: htFrom(away),
      homePenScore: homePenScore,
      awayPenScore: awayPenScore,
      phase: phase,
      statusLabel: statusLabel,
      kickoff: kickoff,
      venue: venue,
    );
  }

  FootballTeam _teamFromEspn(Map<String, dynamic> competitor) {
    final team = (competitor['team'] as Map<String, dynamic>?) ?? const {};
    final id = '${team['id'] ?? ''}';
    final name = '${team['shortDisplayName'] ?? team['displayName'] ?? 'Team'}';
    final logosList = team['logos'] as List<dynamic>?;
    final firstLogo = logosList?.isNotEmpty == true ? logosList!.first : null;
    final logoFromLogos = firstLogo is Map ? firstLogo['href'] as String? : null;
    final logo = team['logo'] as String? ?? logoFromLogos;
    final local = _matchLocalAsset(name);
    final venueObj = team['venue'] as Map<String, dynamic>?;

    return FootballTeam(
      id: id,
      name: name,
      mark: _lettersMark(name),
      logoAsset: local,
      logoUrl: logo ?? _matchOfficialLogoUrl(name),
      stadium: venueObj?['fullName'] as String?,
      city: (venueObj?['address'] as Map<String, dynamic>?)?['city'] as String?,
    );
  }

  Future<List<StandingRow>> _espnStandings(String slug) async {
    final uri = Uri.tryParse('$_espnBase/v2/sports/soccer/$slug/standings');
    if (uri == null) return const [];
    final res = await _get(uri);
    if (res.statusCode != 200) return const [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final children = json['children'] as List<dynamic>? ?? const [];
    if (children.isEmpty) return const [];
    final standings = (children.first as Map<String, dynamic>)['standings'] as Map<String, dynamic>?;
    final entries = standings?['entries'] as List<dynamic>? ?? const [];

    final rows = <StandingRow>[];
    for (final raw in entries) {
      final entry = raw as Map<String, dynamic>;
      final teamJson = (entry['team'] as Map<String, dynamic>?) ?? const {};
      final name = '${teamJson['displayName'] ?? teamJson['shortDisplayName'] ?? 'Team'}';
      final logos = teamJson['logos'] as List<dynamic>?;
      final logoUrl = logos != null && logos.isNotEmpty
          ? (logos.first as Map<String, dynamic>)['href'] as String?
          : null;
      final stats = (entry['stats'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

      double? stat(String name) {
        for (final s in stats) {
          if (s['name'] == name) {
            final v = s['value'];
            if (v is num) return v.toDouble();
            return double.tryParse('${s['displayValue']}'.replaceAll('+', ''));
          }
        }
        return null;
      }

      final rank = (stat('rank') ?? (rows.length + 1)).round();
      final played = (stat('gamesPlayed') ?? 0).round();
      final won = (stat('wins') ?? 0).round();
      final drawn = (stat('ties') ?? 0).round();
      final lost = (stat('losses') ?? 0).round();
      final goalsFor = (stat('pointsFor') ?? 0).round();
      final goalsAgainst = (stat('pointsAgainst') ?? 0).round();
      final gd = (stat('pointDifferential') ?? (goalsFor - goalsAgainst)).round();
      final pts = (stat('points') ?? 0).round();

      // Form string e.g. "WWDLD"
      String? formStr;
      for (final s in stats) {
        if (s['name'] == 'overall' || s['name'] == 'streak') {
          formStr = s['displayValue'] as String?;
        }
      }

      rows.add(
        StandingRow(
          rank: rank,
          team: FootballTeam(
            name: name,
            mark: _lettersMark(name),
            logoAsset: _matchLocalAsset(name),
            logoUrl: logoUrl ?? _matchOfficialLogoUrl(name),
          ),
          played: played,
          won: won,
          drawn: drawn,
          lost: lost,
          goalsFor: goalsFor,
          goalsAgainst: goalsAgainst,
          gd: gd,
          pts: pts,
          form: formStr,
        ),
      );
    }

    rows.sort((a, b) => a.rank.compareTo(b.rank));
    return rows;
  }

  /// Prefer real catalog scorers; never invent placeholder player names.
  List<TopScorer> _espnTopScorers(String slug, List<FootballTeam> teams) {
    if (slug == 'eng.1') return FootballData.eplTopScorers;
    return const [];
  }

  /// Build attack / defence board from live standings (always accurate when table exists).
  static List<StandingRow> attackLeaders(List<StandingRow> standings, {int limit = 5}) {
    final rows = List<StandingRow>.from(standings)
      ..sort((a, b) {
        final g = b.goalsFor.compareTo(a.goalsFor);
        if (g != 0) return g;
        return b.pts.compareTo(a.pts);
      });
    return rows.take(limit).toList();
  }

  static List<StandingRow> defenceLeaders(List<StandingRow> standings, {int limit = 5}) {
    final rows = List<StandingRow>.from(standings)
      ..sort((a, b) {
        final g = a.goalsAgainst.compareTo(b.goalsAgainst);
        if (g != 0) return g;
        return b.pts.compareTo(a.pts);
      });
    return rows.take(limit).toList();
  }

  FootballMatch _parseEspnMatchSummary(FootballMatch base, Map<String, dynamic> json) {
    // 1. Events
    final keyEvents = (json['keyEvents'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final parsedEvents = <MatchEvent>[];

    for (final e in keyEvents) {
      final typeObj = (e['type'] as Map<String, dynamic>?) ?? const {};
      final typeText = '${typeObj['text'] ?? ''}'.toLowerCase();
      final typeId = '${typeObj['type'] ?? ''}'.toLowerCase();

      MatchEventType eventType;
      if (typeText.contains('goal') || typeId.contains('goal')) {
        if (typeText.contains('penalty')) {
          eventType = MatchEventType.penaltyGoal;
        } else if (typeText.contains('own')) {
          eventType = MatchEventType.ownGoal;
        } else {
          eventType = MatchEventType.goal;
        }
      } else if (typeText.contains('yellow') || typeId.contains('yellow')) {
        eventType = MatchEventType.yellowCard;
      } else if (typeText.contains('red') || typeId.contains('red')) {
        eventType = MatchEventType.redCard;
      } else if (typeText.contains('substitution') || typeId.contains('sub')) {
        eventType = MatchEventType.substitution;
      } else if (typeText.contains('var')) {
        eventType = MatchEventType.varDecision;
      } else {
        continue; // skip kickoffs, halftime, etc.
      }

      final clock = (e['clock'] as Map<String, dynamic>?) ?? const {};
      final displayClock = '${clock['displayValue'] ?? ''}'.replaceAll("'", '');
      final minute = int.tryParse(displayClock) ?? ((e['period']?['number'] ?? 1) * 45);

      final team = (e['team'] as Map<String, dynamic>?) ?? const {};
      final teamName = '${team['displayName'] ?? ''}';
      final isHome = teamName.toLowerCase().contains(base.home.name.toLowerCase()) ||
          base.home.name.toLowerCase().contains(teamName.toLowerCase());

      final participants = (e['participants'] as List<dynamic>? ?? const []);
      String playerName = '';
      String? assistOrSub;

      if (participants.isNotEmpty) {
        final p0 = participants[0] as Map<String, dynamic>;
        playerName = '${p0['athlete']?['displayName'] ?? ''}';
        if (participants.length > 1) {
          final p1 = participants[1] as Map<String, dynamic>;
          assistOrSub = '${p1['athlete']?['displayName'] ?? ''}';
        }
      }

      if (playerName.isEmpty) {
        playerName = '${e['text'] ?? ''}';
      }

      parsedEvents.add(
        MatchEvent(
          minute: minute,
          type: eventType,
          teamName: teamName.isNotEmpty ? teamName : (isHome ? base.home.name : base.away.name),
          isHome: isHome,
          playerName: playerName,
          assistOrPlayerOut: assistOrSub,
          detail: '${e['text'] ?? ''}',
        ),
      );
    }

    parsedEvents.sort((a, b) => a.minute.compareTo(b.minute));

    // 2. Rosters / Lineups
    final rosters = (json['rosters'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    MatchLineup? homeLineup;
    MatchLineup? awayLineup;

    for (final r in rosters) {
      final team = (r['team'] as Map<String, dynamic>?) ?? const {};
      final teamName = '${team['displayName'] ?? ''}';
      final isHome = teamName.toLowerCase().contains(base.home.name.toLowerCase()) ||
          base.home.name.toLowerCase().contains(teamName.toLowerCase()) ||
          rosters.indexOf(r) == 0;

      final formation = '${r['formation'] ?? ''}'.trim().isEmpty
          ? '—'
          : '${r['formation']}';
      final coaches = (r['coaches'] as List<dynamic>? ?? const []);
      final coachName = coaches.isNotEmpty
          ? '${(coaches.first as Map<String, dynamic>)['displayName'] ?? ''}'
          : null;

      final rosterList = (r['roster'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      final startingXI = <LineupPlayer>[];
      final substitutes = <LineupPlayer>[];

      for (final p in rosterList) {
        final athlete = (p['athlete'] as Map<String, dynamic>?) ?? const {};
        final name = '${athlete['displayName'] ?? athlete['fullName'] ?? 'Player'}';
        final number = int.tryParse('${p['jersey'] ?? '0'}') ?? 0;
        final pos = (p['position'] as Map<String, dynamic>?) ?? const {};
        final posAbbr = '${pos['abbreviation'] ?? 'M'}';
        final isStarter = p['starter'] == true;

        final lp = LineupPlayer(
          id: '${athlete['id'] ?? ''}',
          name: name,
          number: number,
          position: posAbbr,
          isCaptain: athlete['captain'] == true,
        );

        if (isStarter) {
          startingXI.add(lp);
        } else {
          substitutes.add(lp);
        }
      }

      final lineup = MatchLineup(
        teamName: isHome ? base.home.name : base.away.name,
        formation: formation,
        coach: coachName,
        startingXI: startingXI,
        substitutes: substitutes,
      );

      if (isHome) {
        homeLineup = lineup;
      } else {
        awayLineup = lineup;
      }
    }

    // 3. Boxscore / Statistics
    final boxscore = json['boxscore'] as Map<String, dynamic>?;
    final boxTeams = (boxscore?['teams'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    MatchStatistics? statistics;
    if (boxTeams.length >= 2) {
      Map<String, dynamic> homeStatsMap = const {};
      Map<String, dynamic> awayStatsMap = const {};
      for (final bt in boxTeams) {
        final order =
            bt['homeAway'] ?? (boxTeams.indexOf(bt) == 0 ? 'home' : 'away');
        final statsList = (bt['statistics'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
        final map = <String, dynamic>{};
        for (final s in statsList) {
          map['${s['name']}'] = s['displayValue'];
        }
        if (order == 'home') {
          homeStatsMap = map;
        } else {
          awayStatsMap = map;
        }
      }

      int? parseOpt(dynamic v) {
        if (v == null) return null;
        if (v is num) return v.round();
        final s = v.toString().replaceAll('%', '').trim();
        final d = double.tryParse(s);
        return d?.round();
      }

      final homePoss = parseOpt(homeStatsMap['possessionPct']);
      final awayPoss = parseOpt(awayStatsMap['possessionPct']);
      final homeShots = parseOpt(homeStatsMap['totalShots']);
      final awayShots = parseOpt(awayStatsMap['totalShots']);
      final hasAny = homePoss != null ||
          awayPoss != null ||
          homeShots != null ||
          awayShots != null ||
          homeStatsMap.isNotEmpty;

      if (hasAny) {
        int passPct(dynamic v) {
          final raw = parseOpt(v);
          if (raw == null) return 0;
          if (raw <= 1) return (raw * 100).round();
          return raw;
        }

        statistics = MatchStatistics(
          homePossession: homePoss ?? 0,
          awayPossession: awayPoss ?? 0,
          homeShots: homeShots ?? 0,
          awayShots: awayShots ?? 0,
          homeShotsOnTarget: parseOpt(homeStatsMap['shotsOnTarget']) ?? 0,
          awayShotsOnTarget: parseOpt(awayStatsMap['shotsOnTarget']) ?? 0,
          homeCorners: parseOpt(homeStatsMap['wonCorners']) ?? 0,
          awayCorners: parseOpt(awayStatsMap['wonCorners']) ?? 0,
          homeFouls: parseOpt(homeStatsMap['foulsCommitted']) ?? 0,
          awayFouls: parseOpt(awayStatsMap['foulsCommitted']) ?? 0,
          homeYellowCards: parseOpt(homeStatsMap['yellowCards']) ?? 0,
          awayYellowCards: parseOpt(awayStatsMap['yellowCards']) ?? 0,
          homeRedCards: parseOpt(homeStatsMap['redCards']) ?? 0,
          awayRedCards: parseOpt(awayStatsMap['redCards']) ?? 0,
          homeOffsides: parseOpt(homeStatsMap['offsides']) ?? 0,
          awayOffsides: parseOpt(awayStatsMap['offsides']) ?? 0,
          homePassAccuracy: passPct(homeStatsMap['passPct']),
          awayPassAccuracy: passPct(awayStatsMap['passPct']),
        );
      }
    }

    // 4. Head to Head — only when ESPN provides real previous meetings.
    HeadToHead? h2h;
    final prevRaw = (json['previousMeetings'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    if (prevRaw.isNotEmpty) {
      final previous = <FootballMatch>[];
      var homeWins = 0;
      var awayWins = 0;
      var draws = 0;
      for (final item in prevRaw) {
        final mapped =
            _mapEspnEvent(item, base.competitionId, base.competitionName);
        if (mapped == null || !mapped.hasScore) continue;
        previous.add(mapped);
        if (mapped.homeScore == mapped.awayScore) {
          draws++;
        } else if (mapped.home.name.toLowerCase() ==
            base.home.name.toLowerCase()) {
          if (mapped.homeScore! > mapped.awayScore!) {
            homeWins++;
          } else {
            awayWins++;
          }
        } else if (mapped.homeScore! > mapped.awayScore!) {
          awayWins++;
        } else {
          homeWins++;
        }
      }
      if (previous.isNotEmpty) {
        h2h = HeadToHead(
          totalPlayed: previous.length,
          homeWins: homeWins,
          awayWins: awayWins,
          draws: draws,
          previousMatches: previous,
        );
      }
    }

    return base.copyWith(
      events: parsedEvents.isNotEmpty ? parsedEvents : base.events,
      homeLineup: homeLineup ?? base.homeLineup,
      awayLineup: awayLineup ?? base.awayLineup,
      statistics: statistics ?? base.statistics,
      headToHead: h2h ?? base.headToHead,
    );
  }

  Future<FootballLeague> _fetchSportsDbLeague(
    FootballLeague meta,
    LeagueSource source,
  ) async {
    final id = source.sportsDbId!;
    final seasons = source.sportsDbSeasons.isEmpty
        ? _defaultSeasons()
        : source.sportsDbSeasons;
    // Ethiopian coverage is thin and rate-limit sensitive — prefer the
    // newest 2 seasons unless the user picked an explicit season override.
    final seasonQuery = meta.id == 'epl_eth' && seasons.length > 2
        ? seasons.take(2).toList()
        : seasons;

    List<StandingRow> standings = const [];
    String? standingsSeason;
    for (final season in seasonQuery) {
      standings = await _sportsDbStandings(id, season);
      if (standings.isNotEmpty) {
        standingsSeason = season;
        break;
      }
      await _testAwareDelay(const Duration(milliseconds: 250));
    }

    final seasonMatches = <FootballMatch>[];
    // Pull full season fixtures for the standings season first, then at most
    // one prior season. Avoids hammering TheSportsDB (429) for Ethiopia.
    final fixtureSeasons = <String>[
      ?standingsSeason,
      ...seasonQuery.where((s) => s != standingsSeason).take(1),
    ];
    for (final season in fixtureSeasons) {
      try {
        final events = await _sportsDbEvents(
          'eventsseason.php?id=$id&s=$season',
          competitionId: meta.id,
          competitionName: meta.name,
        );
        seasonMatches.addAll(events);
      } catch (_) {}
      await _testAwareDelay(const Duration(milliseconds: 250));
    }

    final next = await _sportsDbEvents(
      'eventsnextleague.php?id=$id',
      competitionId: meta.id,
      competitionName: meta.name,
    );
    await _testAwareDelay(const Duration(milliseconds: 250));
    final past = await _sportsDbEvents(
      'eventspastleague.php?id=$id',
      competitionId: meta.id,
      competitionName: meta.name,
    );

    final matches = _mergeMatchLists([
      seasonMatches,
      past,
      next,
    ]);

    final teams = standings.isNotEmpty
        ? standings.map((s) => s.team).toList()
        : meta.teams;

    return meta.copyWith(
      matches: matches,
      standings: standings,
      teams: teams,
      season: standingsSeason ?? meta.season,
      isLive: matches.any((m) => m.isLive),
      fetchedAt: DateTime.now(),
      sourceLabel: 'TheSportsDB · Live',
    );
  }

  Future<List<StandingRow>> _sportsDbStandings(String leagueId, String season) async {
    final uri = Uri.tryParse('$_sportsDbBase/lookuptable.php?l=$leagueId&s=$season');
    if (uri == null) return const [];
    final res = await _get(uri, timeout: const Duration(seconds: 20));
    if (res.statusCode != 200) return const [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final table = json['table'] as List<dynamic>?;
    if (table == null) return const [];

    return table.map((raw) {
      final row = raw as Map<String, dynamic>;
      final name = '${row['strTeam'] ?? 'Team'}';
      final badge = row['strBadge'] as String?;
      return StandingRow(
        rank: int.tryParse('${row['intRank']}') ?? 0,
        team: _resolveKnownTeam(name, logoUrl: badge ?? _matchOfficialLogoUrl(name)),
        played: int.tryParse('${row['intPlayed']}') ?? 0,
        won: int.tryParse('${row['intWin']}') ?? 0,
        drawn: int.tryParse('${row['intDraw']}') ?? 0,
        lost: int.tryParse('${row['intLoss']}') ?? 0,
        goalsFor: int.tryParse('${row['intGoalsFor']}') ?? 0,
        goalsAgainst: int.tryParse('${row['intGoalsAgainst']}') ?? 0,
        gd: int.tryParse('${row['intGoalDifference']}') ?? 0,
        pts: int.tryParse('${row['intPoints']}') ?? 0,
        form: row['strForm'] as String?,
      );
    }).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
  }

  Future<List<FootballMatch>> _sportsDbEvents(
    String path, {
    String competitionId = '',
    String competitionName = '',
  }) async {
    final uri = Uri.tryParse('$_sportsDbBase/$path');
    if (uri == null) return const [];
    final res = await _get(uri, timeout: const Duration(seconds: 20));
    if (res.statusCode != 200) return const [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final events = json['events'] as List<dynamic>?;
    if (events == null) return const [];
    return events
        .map(
          (raw) => _mapSportsDbEvent(
            raw,
            competitionId: competitionId,
            competitionName: competitionName,
          ),
        )
        .whereType<FootballMatch>()
        .toList();
  }

  FootballMatch? _mapSportsDbEvent(
    dynamic raw, {
    String competitionId = '',
    String competitionName = '',
  }) {
    final e = raw as Map<String, dynamic>;
    final homeName = '${e['strHomeTeam'] ?? ''}';
    final awayName = '${e['strAwayTeam'] ?? ''}';
    if (homeName.isEmpty || awayName.isEmpty) return null;

    final dateStr = '${e['dateEvent'] ?? ''}';
    final timeStr = '${e['strTime'] ?? '00:00:00'}';
    DateTime? kickoff;
    try {
      kickoff = DateTime.parse('${dateStr}T$timeStr').toLocal();
    } catch (_) {
      kickoff = DateTime.tryParse(dateStr);
    }

    final homeScore = int.tryParse('${e['intHomeScore'] ?? ''}');
    final awayScore = int.tryParse('${e['intAwayScore'] ?? ''}');
    final status = '${e['strStatus'] ?? ''}'.toUpperCase();

    MatchPhase phase;
    String? statusLabel;
    String? time;
    String? period;

    final isFinished = homeScore != null &&
        awayScore != null &&
        (status == 'FT' || status == 'AET' || status == 'PEN' || status == 'MATCH FINISHED');
    final isLive = status.contains('LIVE') ||
        status == '1H' ||
        status == '2H' ||
        status == 'HT' ||
        RegExp(r'^\d').hasMatch(status);

    if (isLive) {
      phase = MatchPhase.live;
      statusLabel = 'LIVE';
      time = status;
    } else if (isFinished || (homeScore != null && awayScore != null && status != 'NS')) {
      phase = MatchPhase.finished;
      statusLabel = status.isEmpty ? 'FT' : status;
    } else if (status.contains('POST') || status == 'PST') {
      phase = MatchPhase.postponed;
      statusLabel = 'PPD';
    } else {
      phase = MatchPhase.scheduled;
      if (kickoff != null) {
        final h = kickoff.hour;
        final m = kickoff.minute.toString().padLeft(2, '0');
        final hour12 = h % 12 == 0 ? 12 : h % 12;
        time = '$hour12:$m';
        period = h >= 12 ? 'PM' : 'AM';
      } else {
        time = timeStr.length >= 5 ? timeStr.substring(0, 5) : timeStr;
      }
    }

    final round = int.tryParse('${e['intRound'] ?? ''}');
    final roundLabel = round != null
        ? 'Round $round'
        : (e['strEvent'] as String?);

    return FootballMatch(
      id: '${e['idEvent'] ?? ''}',
      competitionId: competitionId,
      competitionName: competitionName.isNotEmpty
          ? competitionName
          : '${e['strLeague'] ?? ''}',
      round: round,
      roundLabel: roundLabel,
      dateHeader: _ethiopianHeader(kickoff ?? DateTime.now()),
      home: _resolveKnownTeam(
        homeName,
        logoUrl: (e['strHomeTeamBadge'] as String?) ?? _matchOfficialLogoUrl(homeName),
      ),
      away: _resolveKnownTeam(
        awayName,
        logoUrl: (e['strAwayTeamBadge'] as String?) ?? _matchOfficialLogoUrl(awayName),
      ),
      time: time,
      period: period,
      homeScore: homeScore,
      awayScore: awayScore,
      phase: phase,
      statusLabel: statusLabel,
      kickoff: kickoff,
      venue: e['strVenue'] as String?,
    );
  }

  String _espnDate(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  List<String> _defaultSeasons() => FootballData.multiYearSeasons;

  String _ethiopianHeader(DateTime local) {
    final eth = EthiopianCalendarEngine.toEthiopian(
      GregorianDate(local.year, local.month, local.day),
    );
    final weekday = DateFormat('EEEE').format(local);
    return '$weekday, ${eth.monthEnum.englishName} ${eth.day}';
  }

  ColorMark _lettersMark(String name) {
    final parts = name
        .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    String letters;
    if (parts.length >= 2) {
      letters = (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts.isNotEmpty) {
      letters = parts[0].substring(0, parts[0].length.clamp(0, 3)).toUpperCase();
    } else {
      letters = 'FC';
    }
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    const palette = [
      0xFF1565C0,
      0xFFC62828,
      0xFF2E7D32,
      0xFF6A1B9A,
      0xFFEF6C00,
      0xFF00838F,
      0xFF4527A0,
      0xFF37474F,
    ];
    return ColorMark(letters, palette[hash % palette.length]);
  }

  String? _matchLocalAsset(String name) {
    final n = name.toLowerCase();
    const map = <String, String>{
      'arsenal': 'arsenal',
      'brighton': 'brighton',
      'manchester city': 'mancity',
      'man city': 'mancity',
      'liverpool': 'liverpool',
      'chelsea': 'chelsea',
      'everton': 'everton',
      'aston villa': 'villa',
      'leeds': 'leeds',
      'tottenham': 'tottenham',
      'spurs': 'tottenham',
      'fulham': 'fulham',
      'newcastle': 'newcastle',
      'hull': 'hull',
      'nottingham': 'forest',
      'forest': 'forest',
      'brentford': 'brentford',
      'crystal palace': 'palace',
      'ipswich': 'ipswich',
      'bournemouth': 'bournemouth',
      'coventry': 'coventry',
      'real madrid': 'realmadrid',
      'barcelona': 'barcelona',
      'atletico': 'atletico',
      'atlético': 'atletico',
      'sevilla': 'sevilla',
      'villarreal': 'villarreal',
      'real sociedad': 'realsociedad',
      'bayern': 'bayern',
      'dortmund': 'dortmund',
      'leipzig': 'leipzig',
      'leverkusen': 'leverkusen',
      'frankfurt': 'frankfurt',
      'wolfsburg': 'wolfsburg',
      'inter': 'inter',
      'milan': 'milan',
      'juventus': 'juventus',
      'napoli': 'napoli',
      'roma': 'roma',
      'lazio': 'lazio',
      'atalanta': 'atalanta',
      'psg': 'psg',
      'paris': 'psg',
      'fasil': 'fasil',
      'nigd': 'nigd',
      'cbe': 'nigd',
      'mebrat': 'mebrat',
      'ethio electric': 'mebrat',
      'electric': 'mebrat',
      'halaba': 'halaba',
      'negelle': 'negelle',
      'negele': 'negelle',
      'gamo': 'gamo',
      'arba minch': 'gamo',
      'welwalo': 'welwalo',
      'adigrat': 'welwalo',
      'mekelakeya': 'mekelakeya',
      'mechal': 'mekelakeya',
      'defence': 'mekelakeya',
      'sheger': 'sheger',
      'shaggar': 'sheger',
      'awassa': 'awassa',
      'hawassa': 'awassa',
      'giorgis': 'giorgis',
      'st. george': 'giorgis',
      'saint george': 'giorgis',
      'kidus': 'giorgis',
      'hadiya': 'hadiya',
      'hosaena': 'hadiya',
      'hossana': 'hadiya',
      'bahardar': 'bahardar',
      'bahir dar': 'bahardar',
      'medhin': 'medhin',
      'insurance': 'medhin',
      'adama': 'adama',
      'sidama': 'sidama',
      'welayta': 'welayta',
      'wolaitta': 'welayta',
      'dicha': 'welayta',
      'cbe sa': 'nigd',
      'commercial bank': 'nigd',
      'fasil kenema': 'fasil',
      'fasil ketema': 'fasil',
      'kedus giorgis': 'giorgis',
      'kidus giorgis': 'giorgis',
      'shaggar city': 'sheger',
      'sheger ketema': 'sheger',
    };
    for (final entry in map.entries) {
      if (n.contains(entry.key)) return 'assets/football/teams/${entry.value}.png';
    }
    return null;
  }

  /// Official 500x500 CDN logos from ESPN for clubs across major competitions.
  static String? _matchOfficialLogoUrl(String name) {
    final n = name.toLowerCase();
    const map = <String, String>{
      'arsenal': 'https://a.espncdn.com/i/teamlogos/soccer/500/359.png',
      'aston villa': 'https://a.espncdn.com/i/teamlogos/soccer/500/362.png',
      'villa': 'https://a.espncdn.com/i/teamlogos/soccer/500/362.png',
      'bournemouth': 'https://a.espncdn.com/i/teamlogos/soccer/500/349.png',
      'brentford': 'https://a.espncdn.com/i/teamlogos/soccer/500/337.png',
      'brighton': 'https://a.espncdn.com/i/teamlogos/soccer/500/331.png',
      'chelsea': 'https://a.espncdn.com/i/teamlogos/soccer/500/363.png',
      'crystal palace': 'https://a.espncdn.com/i/teamlogos/soccer/500/384.png',
      'palace': 'https://a.espncdn.com/i/teamlogos/soccer/500/384.png',
      'everton': 'https://a.espncdn.com/i/teamlogos/soccer/500/368.png',
      'fulham': 'https://a.espncdn.com/i/teamlogos/soccer/500/370.png',
      'ipswich': 'https://a.espncdn.com/i/teamlogos/soccer/500/373.png',
      'liverpool': 'https://a.espncdn.com/i/teamlogos/soccer/500/364.png',
      'manchester city': 'https://a.espncdn.com/i/teamlogos/soccer/500/382.png',
      'man city': 'https://a.espncdn.com/i/teamlogos/soccer/500/382.png',
      'manchester united': 'https://a.espncdn.com/i/teamlogos/soccer/500/360.png',
      'man united': 'https://a.espncdn.com/i/teamlogos/soccer/500/360.png',
      'man utd': 'https://a.espncdn.com/i/teamlogos/soccer/500/360.png',
      'newcastle': 'https://a.espncdn.com/i/teamlogos/soccer/500/361.png',
      'nottingham forest': 'https://a.espncdn.com/i/teamlogos/soccer/500/393.png',
      'nottingham': 'https://a.espncdn.com/i/teamlogos/soccer/500/393.png',
      'forest': 'https://a.espncdn.com/i/teamlogos/soccer/500/393.png',
      'tottenham': 'https://a.espncdn.com/i/teamlogos/soccer/500/367.png',
      'spurs': 'https://a.espncdn.com/i/teamlogos/soccer/500/367.png',
      'west ham': 'https://a.espncdn.com/i/teamlogos/soccer/500/371.png',
      'wolves': 'https://a.espncdn.com/i/teamlogos/soccer/500/380.png',
      'wolverhampton': 'https://a.espncdn.com/i/teamlogos/soccer/500/380.png',
      'leicester': 'https://a.espncdn.com/i/teamlogos/soccer/500/375.png',
      'southampton': 'https://a.espncdn.com/i/teamlogos/soccer/500/376.png',
      'coventry': 'https://a.espncdn.com/i/teamlogos/soccer/500/392.png',
      'leeds': 'https://a.espncdn.com/i/teamlogos/soccer/500/357.png',
      'hull': 'https://a.espncdn.com/i/teamlogos/soccer/500/306.png',
      'real madrid': 'https://a.espncdn.com/i/teamlogos/soccer/500/86.png',
      'barcelona': 'https://a.espncdn.com/i/teamlogos/soccer/500/83.png',
      'atletico': 'https://a.espncdn.com/i/teamlogos/soccer/500/1068.png',
      'atlético': 'https://a.espncdn.com/i/teamlogos/soccer/500/1068.png',
      'sevilla': 'https://a.espncdn.com/i/teamlogos/soccer/500/243.png',
      'villarreal': 'https://a.espncdn.com/i/teamlogos/soccer/500/102.png',
      'real sociedad': 'https://a.espncdn.com/i/teamlogos/soccer/500/89.png',
      'bayern': 'https://a.espncdn.com/i/teamlogos/soccer/500/132.png',
      'dortmund': 'https://a.espncdn.com/i/teamlogos/soccer/500/124.png',
      'leverkusen': 'https://a.espncdn.com/i/teamlogos/soccer/500/131.png',
      'leipzig': 'https://a.espncdn.com/i/teamlogos/soccer/500/11420.png',
      'frankfurt': 'https://a.espncdn.com/i/teamlogos/soccer/500/125.png',
      'wolfsburg': 'https://a.espncdn.com/i/teamlogos/soccer/500/138.png',
      'inter': 'https://a.espncdn.com/i/teamlogos/soccer/500/110.png',
      'milan': 'https://a.espncdn.com/i/teamlogos/soccer/500/103.png',
      'juventus': 'https://a.espncdn.com/i/teamlogos/soccer/500/111.png',
      'napoli': 'https://a.espncdn.com/i/teamlogos/soccer/500/114.png',
      'roma': 'https://a.espncdn.com/i/teamlogos/soccer/500/104.png',
      'lazio': 'https://a.espncdn.com/i/teamlogos/soccer/500/112.png',
      'atalanta': 'https://a.espncdn.com/i/teamlogos/soccer/500/107.png',
      'psg': 'https://a.espncdn.com/i/teamlogos/soccer/500/160.png',
      'paris': 'https://a.espncdn.com/i/teamlogos/soccer/500/160.png',
    };
    for (final entry in map.entries) {
      if (n.contains(entry.key)) return entry.value;
    }
    return null;
  }

  String? _slugForCompetition(String id) {
    switch (id) {
      case 'epl_eng':
        return 'eng.1';
      case 'ucl':
        return 'uefa.champions';
      case 'europa':
        return 'uefa.europa';
      case 'conference':
        return 'uefa.europa.conf';
      case 'bundesliga':
        return 'ger.1';
      case 'laliga':
        return 'esp.1';
      case 'seriea':
        return 'ita.1';
      case 'ligue1':
        return 'fra.1';
      case 'caf_cl':
        return 'caf.champions';
      case 'caf_cc':
        return 'caf.confed';
      case 'afcon':
        return 'caf.nations';
      case 'world_cup':
        return 'fifa.world';
      default:
        return FootballData.sourceFor(id).espnSlug;
    }
  }

  String _compIdForSlug(String slug) {
    switch (slug) {
      case 'eng.1':
        return 'epl_eng';
      case 'uefa.champions':
        return 'ucl';
      case 'uefa.europa':
        return 'europa';
      case 'uefa.europa.conf':
        return 'conference';
      case 'ger.1':
        return 'bundesliga';
      case 'esp.1':
        return 'laliga';
      case 'ita.1':
        return 'seriea';
      case 'fra.1':
        return 'ligue1';
      case 'caf.champions':
        return 'caf_cl';
      case 'caf.confed':
        return 'caf_cc';
      case 'caf.nations':
        return 'afcon';
      case 'fifa.world':
        return 'world_cup';
      default:
        return slug;
    }
  }

  String _compNameForSlug(String slug) {
    switch (slug) {
      case 'eng.1':
        return 'English Premier League';
      case 'uefa.champions':
        return 'UEFA Champions League';
      case 'uefa.europa':
        return 'UEFA Europa League';
      case 'uefa.europa.conf':
        return 'UEFA Conference League';
      case 'ger.1':
        return 'Bundesliga';
      case 'esp.1':
        return 'La Liga';
      case 'ita.1':
        return 'Serie A';
      case 'fra.1':
        return 'Ligue 1';
      case 'caf.champions':
        return 'CAF Champions League';
      case 'caf.confed':
        return 'CAF Confederation Cup';
      case 'caf.nations':
        return 'Africa Cup of Nations';
      case 'fifa.world':
        return 'FIFA World Cup';
      default:
        return 'Football';
    }
  }

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'User-Agent': 'Zemen/1.0 (Flutter; football)',
      };

  /// HTTP GET with timeout, 429 Retry-After respect, and one transient retry.
  Future<http.Response> _get(
    Uri uri, {
    Duration timeout = _requestTimeout,
  }) async {
    final isSportsDb = uri.host.contains('thesportsdb') ||
        uri.pathSegments.contains('sportsdb');
    final isTesting = const bool.fromEnvironment('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    // Skip spacing in Flutter tests so widget suites do not leave pending timers.
    if (isSportsDb && !isTesting) {
      final previous = _sportsDbGate;
      final gate = Completer<void>();
      _sportsDbGate = gate.future;
      try {
        await previous;
      } catch (_) {}
      await _testAwareDelay(_sportsDbMinGap);
      gate.complete();
    }

    Future<http.Response> once() =>
        _client.get(uri, headers: _headers).timeout(timeout);

    var res = await once();
    if (res.statusCode == 429) {
      final retryAfter = int.tryParse(res.headers['retry-after'] ?? '') ?? 5;
      await _testAwareDelay(Duration(seconds: retryAfter.clamp(1, 60)));
      res = await once();
    } else if (res.statusCode >= 500 && res.statusCode < 600) {
      await _testAwareDelay(const Duration(milliseconds: 400));
      res = await once();
    }
    return res;
  }

  Future<FootballLeague> _fetchOpenLigaLeague(
    FootballLeague meta,
    String leagueShortcut,
  ) async {
    final year = DateTime.now().year;
    // OpenLiga seasons use the start year of the campaign (e.g. 2025 for 25/26).
    final seasonYear = DateTime.now().month >= 7 ? year : year - 1;
    final matchUri =
        Uri.tryParse('$_openLigaBase/getmatchdata/$leagueShortcut/$seasonYear');
    final tableUri =
        Uri.tryParse('$_openLigaBase/getbltable/$leagueShortcut/$seasonYear');
    if (matchUri == null || tableUri == null) {
      throw Exception('OpenLigaDB invalid URI');
    }

    final matchRes = await _get(matchUri, timeout: const Duration(seconds: 20));
    if (matchRes.statusCode != 200) {
      throw Exception('OpenLigaDB ${matchRes.statusCode}');
    }
    final raw = jsonDecode(matchRes.body);
    if (raw is! List) {
      throw Exception('OpenLigaDB malformed match payload');
    }

    final matches = <FootballMatch>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final mapped = _mapOpenLigaMatch(item, meta.id, meta.name);
      if (mapped != null) matches.add(mapped);
    }

    var standings = <StandingRow>[];
    try {
      final tableRes = await _get(tableUri);
      if (tableRes.statusCode == 200) {
        final tableRaw = jsonDecode(tableRes.body);
        if (tableRaw is List) {
          standings = _mapOpenLigaTable(tableRaw);
        }
      }
    } catch (_) {}

    return meta.copyWith(
      matches: matches,
      standings: standings,
      teams: standings.map((s) => s.team).toList(),
      fetchedAt: DateTime.now(),
      sourceLabel: 'OpenLigaDB',
    );
  }

  FootballMatch? _mapOpenLigaMatch(
    Map<String, dynamic> m,
    String competitionId,
    String competitionName,
  ) {
    final homeName = '${m['team1']?['teamName'] ?? ''}';
    final awayName = '${m['team2']?['teamName'] ?? ''}';
    if (homeName.isEmpty || awayName.isEmpty) return null;

    final kickoff = DateTime.tryParse('${m['matchDateTimeUTC'] ?? m['matchDateTime'] ?? ''}');
    final results = m['matchResults'] as List<dynamic>? ?? const [];
    int? homeScore;
    int? awayScore;
    int? homeHtScore;
    int? awayHtScore;
    int? homePenScore;
    int? awayPenScore;
    MatchPhase phase = MatchPhase.scheduled;
    String? statusLabel;

    if (m['matchIsFinished'] == true) {
      phase = MatchPhase.finished;
      statusLabel = 'FT';
    }
    for (final r in results) {
      if (r is! Map<String, dynamic>) continue;
      final rName = '${r['resultName'] ?? ''}'.toLowerCase();
      if (rName.contains('halbzeit')) {
        homeHtScore = r['pointsTeam1'] as int?;
        awayHtScore = r['pointsTeam2'] as int?;
      } else if (rName.contains('elfmeter')) {
        homePenScore = r['pointsTeam1'] as int?;
        awayPenScore = r['pointsTeam2'] as int?;
        statusLabel = 'PEN';
      } else if (rName.contains('verlängerung') || rName.contains('aet')) {
        statusLabel = 'AET';
      }
    }
    for (final r in results.reversed) {
      if (r is! Map<String, dynamic>) continue;
      homeScore = r['pointsTeam1'] as int? ?? homeScore;
      awayScore = r['pointsTeam2'] as int? ?? awayScore;
      break;
    }

    final rawGoals = m['goals'] as List<dynamic>? ?? const [];
    final events = <MatchEvent>[];
    int prevT1 = 0;
    for (final g in rawGoals) {
      if (g is! Map<String, dynamic>) continue;
      final minute = g['matchMinute'] as int? ?? 0;
      final scorer = '${g['goalGetterName'] ?? ''}'.trim();
      final isPen = g['isPenalty'] == true;
      final isOwn = g['isOwnGoal'] == true;
      final t1 = g['scoreTeam1'] as int? ?? 0;
      final isHome = t1 > prevT1;
      prevT1 = t1;

      MatchEventType type = MatchEventType.goal;
      if (isPen) {
        type = MatchEventType.penaltyGoal;
      } else if (isOwn) {
        type = MatchEventType.ownGoal;
      }

      if (scorer.isNotEmpty) {
        events.add(
          MatchEvent(
            minute: minute,
            type: type,
            teamName: isHome ? homeName : awayName,
            isHome: isHome,
            playerName: scorer,
            detail: isOwn ? 'Own Goal' : (isPen ? 'Penalty' : null),
          ),
        );
      }
    }

    final homeId = '${m['team1']?['teamId'] ?? homeName}';
    final awayId = '${m['team2']?['teamId'] ?? awayName}';
    final homeLogo = m['team1']?['teamIconUrl'] as String?;
    final awayLogo = m['team2']?['teamIconUrl'] as String?;

    String? time;
    String? period;
    if (kickoff != null) {
      final local = kickoff.toLocal();
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      time = '$hour:${local.minute.toString().padLeft(2, '0')}';
      period = local.hour >= 12 ? 'PM' : 'AM';
    }

    return FootballMatch(
      id: '${m['matchID'] ?? ''}',
      competitionId: competitionId,
      competitionName: competitionName,
      dateHeader: kickoff != null
          ? DateFormat('EEEE, MMM d').format(kickoff.toLocal())
          : '',
      home: FootballTeam(
        id: homeId,
        name: homeName,
        shortName: '${m['team1']?['shortName'] ?? homeName}',
        mark: ColorMark(_initials(homeName), 0xFFD20515),
        logoAsset: _matchLocalAsset(homeName),
        logoUrl: homeLogo ?? _matchOfficialLogoUrl(homeName),
      ),
      away: FootballTeam(
        id: awayId,
        name: awayName,
        shortName: '${m['team2']?['shortName'] ?? awayName}',
        mark: ColorMark(_initials(awayName), 0xFF37474F),
        logoAsset: _matchLocalAsset(awayName),
        logoUrl: awayLogo ?? _matchOfficialLogoUrl(awayName),
      ),
      homeScore: homeScore,
      awayScore: awayScore,
      homeHtScore: homeHtScore,
      awayHtScore: awayHtScore,
      homePenScore: homePenScore,
      awayPenScore: awayPenScore,
      phase: phase,
      statusLabel: statusLabel,
      kickoff: kickoff?.toLocal(),
      time: time,
      period: period,
      events: events,
      venue: m['location']?['locationStadium'] as String?,
    );
  }

  List<StandingRow> _mapOpenLigaTable(List<dynamic> rows) {
    final out = <StandingRow>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      if (r is! Map<String, dynamic>) continue;
      final name = '${r['teamName'] ?? ''}';
      if (name.isEmpty) continue;
      final played = (r['won'] as int? ?? 0) +
          (r['draw'] as int? ?? 0) +
          (r['lost'] as int? ?? 0);
      out.add(
        StandingRow(
          rank: i + 1,
          team: FootballTeam(
            id: '${r['teamInfoId'] ?? name}',
            name: name,
            shortName: '${r['shortName'] ?? name}',
            mark: ColorMark(_initials(name), 0xFFD20515),
            logoAsset: _matchLocalAsset(name),
            logoUrl: (r['teamIconUrl'] as String?) ?? _matchOfficialLogoUrl(name),
          ),
          played: played,
          won: r['won'] as int? ?? 0,
          drawn: r['draw'] as int? ?? 0,
          lost: r['lost'] as int? ?? 0,
          goalsFor: r['goals'] as int? ?? 0,
          goalsAgainst: r['opponentGoals'] as int? ?? 0,
          gd: r['goalDiff'] as int? ?? 0,
          pts: r['points'] as int? ?? 0,
        ),
      );
    }
    return out;
  }

  FootballMatch _parseSportsDbEventDetails(
    FootballMatch base,
    Map<String, dynamic> e,
  ) {
    final events = <MatchEvent>[];
    // TheSportsDB free tier often lacks structured timeline; only map known fields.
    void addGoals(String? raw, bool isHome, String team) {
      if (raw == null || raw.trim().isEmpty) return;
      for (final part in raw.split(';')) {
        final t = part.trim();
        if (t.isEmpty) continue;
        final minuteMatch = RegExp(r'(\d+)').firstMatch(t);
        final minute = int.tryParse(minuteMatch?.group(1) ?? '') ?? 0;
        final name = t.replaceAll(RegExp(r'\d+'), '').replaceAll("'", '').trim();
        if (name.isEmpty) continue;
        events.add(
          MatchEvent(
            minute: minute,
            type: MatchEventType.goal,
            teamName: team,
            isHome: isHome,
            playerName: name,
          ),
        );
      }
    }

    addGoals(e['strHomeGoalDetails'] as String?, true, base.home.name);
    addGoals(e['strAwayGoalDetails'] as String?, false, base.away.name);

    final homeScore = int.tryParse('${e['intHomeScore'] ?? ''}') ?? base.homeScore;
    final awayScore = int.tryParse('${e['intAwayScore'] ?? ''}') ?? base.awayScore;

    return base.copyWith(
      homeScore: homeScore,
      awayScore: awayScore,
      venue: (e['strVenue'] as String?) ?? base.venue,
      events: events.isNotEmpty ? events : base.events,
      // Never invent lineups/stats/H2H.
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'FC';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return ('${parts.first[0]}${parts.last[0]}').toUpperCase();
  }

  void dispose() => _client.close();
}

class _CacheEntry {
  final FootballLeague league;
  final DateTime at;
  _CacheEntry(this.league, this.at);
}
