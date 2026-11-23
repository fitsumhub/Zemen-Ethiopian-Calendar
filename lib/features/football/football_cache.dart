import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'football_data.dart';

/// Persistent snapshot cache for football leagues (SharedPreferences JSON).
/// Distinguishes LIVE / CACHED / OFFLINE via [FootballCacheEntry.sourceKind].
enum FootballSourceKind { live, cached, offline }

class FootballCacheEntry {
  final String leagueId;
  final FootballSourceKind sourceKind;
  final String sourceLabel;
  final DateTime fetchedAt;
  final String payloadJson;

  const FootballCacheEntry({
    required this.leagueId,
    required this.sourceKind,
    required this.sourceLabel,
    required this.fetchedAt,
    required this.payloadJson,
  });

  Map<String, dynamic> toJson() => {
        'leagueId': leagueId,
        'sourceKind': sourceKind.name,
        'sourceLabel': sourceLabel,
        'fetchedAt': fetchedAt.toIso8601String(),
        'payloadJson': payloadJson,
      };

  factory FootballCacheEntry.fromJson(Map<String, dynamic> json) {
    return FootballCacheEntry(
      leagueId: '${json['leagueId']}',
      sourceKind: FootballSourceKind.values.firstWhere(
        (e) => e.name == json['sourceKind'],
        orElse: () => FootballSourceKind.cached,
      ),
      sourceLabel: '${json['sourceLabel'] ?? 'Cached'}',
      fetchedAt: DateTime.tryParse('${json['fetchedAt']}') ?? DateTime.now(),
      payloadJson: '${json['payloadJson'] ?? '{}'}',
    );
  }
}

/// Lightweight durable cache. Full object graphs are reconstituted via
/// [FootballData] + match snapshot maps (never invents scores/events).
class FootballDiskCache {
  FootballDiskCache._();
  static final FootballDiskCache instance = FootballDiskCache._();

  static const _prefix = 'football_league_cache_v1_';
  static const _metaPrefix = 'football_league_meta_v1_';

  /// Live data freshness window before treated as stale-but-usable cache.
  static const liveTtl = Duration(minutes: 5);
  static const softTtl = Duration(hours: 12);

  Future<void> saveLeagueSnapshot({
    required String leagueId,
    required FootballLeague league,
    required FootballSourceKind kind,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = _encodeLeague(league);
      final entry = FootballCacheEntry(
        leagueId: leagueId,
        sourceKind: kind,
        sourceLabel: league.sourceLabel ?? kind.name,
        fetchedAt: league.fetchedAt ?? DateTime.now(),
        payloadJson: jsonEncode(payload),
      );
      await prefs.setString('$_prefix$leagueId', jsonEncode(entry.toJson()));
      await prefs.setString(
        '$_metaPrefix$leagueId',
        jsonEncode({
          'fetchedAt': entry.fetchedAt.toIso8601String(),
          'sourceKind': kind.name,
          'sourceLabel': entry.sourceLabel,
          'matchCount': league.matches.length,
          'standingCount': league.standings.length,
        }),
      );
    } catch (_) {
      // Cache write failures must never break the UX.
    }
  }

  Future<FootballLeague?> loadLeagueSnapshot(String leagueId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$leagueId');
      if (raw == null || raw.isEmpty) return null;
      final entry = FootballCacheEntry.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final map = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
      final league = _decodeLeague(leagueId, map, entry);
      return league;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> loadMeta(String leagueId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_metaPrefix$leagueId');
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearLeague(String leagueId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$leagueId');
    await prefs.remove('$_metaPrefix$leagueId');
  }

  Map<String, dynamic> _encodeLeague(FootballLeague league) {
    return {
      'id': league.id,
      'name': league.name,
      'shortName': league.shortName,
      'country': league.country,
      'season': league.season,
      'sourceLabel': league.sourceLabel,
      'isLive': league.isLive,
      'fetchedAt': league.fetchedAt?.toIso8601String(),
      'matches': league.matches.map(_encodeMatch).toList(),
      'standings': league.standings.map(_encodeStanding).toList(),
      'topScorers': league.topScorers.map(_encodeScorer).toList(),
      'teams': league.teams.map(_encodeTeam).toList(),
    };
  }

  FootballLeague _decodeLeague(
    String leagueId,
    Map<String, dynamic> map,
    FootballCacheEntry entry,
  ) {
    final meta = FootballData.catalogById(leagueId);
    final mark = meta?.mark ?? const ColorMark('FC', 0xFF37474F);
    final age = DateTime.now().difference(entry.fetchedAt);
    final kindLabel = age <= liveTtl
        ? (entry.sourceLabel.contains('Live')
            ? entry.sourceLabel
            : '${entry.sourceLabel} · Live')
        : 'Cached · ${entry.sourceLabel}';

    return FootballLeague(
      id: leagueId,
      name: '${map['name'] ?? meta?.name ?? leagueId}',
      shortName: '${map['shortName'] ?? meta?.shortName ?? ''}',
      mark: mark,
      logoAsset: meta?.logoAsset,
      logoUrl: meta?.logoUrl,
      country: map['country'] as String? ?? meta?.country,
      season: '${map['season'] ?? meta?.season ?? ''}',
      matches: (map['matches'] as List<dynamic>? ?? const [])
          .map((e) => _decodeMatch(e as Map<String, dynamic>))
          .toList(),
      standings: (map['standings'] as List<dynamic>? ?? const [])
          .map((e) => _decodeStanding(e as Map<String, dynamic>))
          .toList(),
      topScorers: (map['topScorers'] as List<dynamic>? ?? const [])
          .map((e) => _decodeScorer(e as Map<String, dynamic>))
          .toList(),
      teams: (map['teams'] as List<dynamic>? ?? const [])
          .map((e) => _decodeTeam(e as Map<String, dynamic>))
          .toList(),
      isLive: map['isLive'] == true,
      fetchedAt: entry.fetchedAt,
      sourceLabel: kindLabel,
    );
  }

  Map<String, dynamic> _encodeMatch(FootballMatch m) => {
        'id': m.id,
        'competitionId': m.competitionId,
        'competitionName': m.competitionName,
        'dateHeader': m.dateHeader,
        'round': m.round,
        'roundLabel': m.roundLabel,
        'time': m.time,
        'period': m.period,
        'homeScore': m.homeScore,
        'awayScore': m.awayScore,
        'homeHtScore': m.homeHtScore,
        'awayHtScore': m.awayHtScore,
        'homePenScore': m.homePenScore,
        'awayPenScore': m.awayPenScore,
        'phase': m.phase.name,
        'statusLabel': m.statusLabel,
        'kickoff': m.kickoff?.toIso8601String(),
        'venue': m.venue,
        'referee': m.referee,
        'home': _encodeTeam(m.home),
        'away': _encodeTeam(m.away),
        'events': m.events.map(_encodeEvent).toList(),
        if (m.statistics != null)
          'statistics': _encodeStatistics(m.statistics!),
      };

  FootballMatch _decodeMatch(Map<String, dynamic> m) {
    final rawEvents = m['events'] as List<dynamic>? ?? const [];
    final events = rawEvents
        .whereType<Map<String, dynamic>>()
        .map(_decodeEvent)
        .toList();
    final rawStats = m['statistics'] as Map<String, dynamic>?;
    final stats = rawStats != null ? _decodeStatistics(rawStats) : null;

    return FootballMatch(
      id: '${m['id'] ?? ''}',
      competitionId: '${m['competitionId'] ?? ''}',
      competitionName: '${m['competitionName'] ?? ''}',
      dateHeader: '${m['dateHeader'] ?? ''}',
      round: m['round'] as int?,
      roundLabel: m['roundLabel'] as String?,
      time: m['time'] as String?,
      period: m['period'] as String?,
      homeScore: m['homeScore'] as int?,
      awayScore: m['awayScore'] as int?,
      homeHtScore: m['homeHtScore'] as int?,
      awayHtScore: m['awayHtScore'] as int?,
      homePenScore: m['homePenScore'] as int?,
      awayPenScore: m['awayPenScore'] as int?,
      phase: MatchPhase.values.firstWhere(
        (e) => e.name == m['phase'],
        orElse: () => MatchPhase.scheduled,
      ),
      statusLabel: m['statusLabel'] as String?,
      kickoff: DateTime.tryParse('${m['kickoff'] ?? ''}'),
      venue: m['venue'] as String?,
      referee: m['referee'] as String?,
      home: _decodeTeam(m['home'] as Map<String, dynamic>? ?? const {}),
      away: _decodeTeam(m['away'] as Map<String, dynamic>? ?? const {}),
      events: events,
      statistics: stats,
    );
  }

  Map<String, dynamic> _encodeEvent(MatchEvent e) => {
        'minute': e.minute,
        'extraMinute': e.extraMinute,
        'type': e.type.name,
        'teamName': e.teamName,
        'isHome': e.isHome,
        'playerName': e.playerName,
        'assistOrPlayerOut': e.assistOrPlayerOut,
        'detail': e.detail,
      };

  MatchEvent _decodeEvent(Map<String, dynamic> e) => MatchEvent(
        minute: e['minute'] as int? ?? 0,
        extraMinute: e['extraMinute'] as int?,
        type: MatchEventType.values.firstWhere(
          (t) => t.name == e['type'],
          orElse: () => MatchEventType.goal,
        ),
        teamName: '${e['teamName'] ?? ''}',
        isHome: e['isHome'] == true,
        playerName: '${e['playerName'] ?? ''}',
        assistOrPlayerOut: e['assistOrPlayerOut'] as String?,
        detail: e['detail'] as String?,
      );

  Map<String, dynamic> _encodeStatistics(MatchStatistics s) => {
        'homePossession': s.homePossession,
        'awayPossession': s.awayPossession,
        'homeShots': s.homeShots,
        'awayShots': s.awayShots,
        'homeShotsOnTarget': s.homeShotsOnTarget,
        'awayShotsOnTarget': s.awayShotsOnTarget,
        'homeCorners': s.homeCorners,
        'awayCorners': s.awayCorners,
        'homeFouls': s.homeFouls,
        'awayFouls': s.awayFouls,
        'homeYellowCards': s.homeYellowCards,
        'awayYellowCards': s.awayYellowCards,
        'homeRedCards': s.homeRedCards,
        'awayRedCards': s.awayRedCards,
        'homeOffsides': s.homeOffsides,
        'awayOffsides': s.awayOffsides,
        'homePassAccuracy': s.homePassAccuracy,
        'awayPassAccuracy': s.awayPassAccuracy,
      };

  MatchStatistics _decodeStatistics(Map<String, dynamic> s) => MatchStatistics(
        homePossession: s['homePossession'] as int? ?? 0,
        awayPossession: s['awayPossession'] as int? ?? 0,
        homeShots: s['homeShots'] as int? ?? 0,
        awayShots: s['awayShots'] as int? ?? 0,
        homeShotsOnTarget: s['homeShotsOnTarget'] as int? ?? 0,
        awayShotsOnTarget: s['awayShotsOnTarget'] as int? ?? 0,
        homeCorners: s['homeCorners'] as int? ?? 0,
        awayCorners: s['awayCorners'] as int? ?? 0,
        homeFouls: s['homeFouls'] as int? ?? 0,
        awayFouls: s['awayFouls'] as int? ?? 0,
        homeYellowCards: s['homeYellowCards'] as int? ?? 0,
        awayYellowCards: s['awayYellowCards'] as int? ?? 0,
        homeRedCards: s['homeRedCards'] as int? ?? 0,
        awayRedCards: s['awayRedCards'] as int? ?? 0,
        homeOffsides: s['homeOffsides'] as int? ?? 0,
        awayOffsides: s['awayOffsides'] as int? ?? 0,
        homePassAccuracy: s['homePassAccuracy'] as int? ?? 0,
        awayPassAccuracy: s['awayPassAccuracy'] as int? ?? 0,
      );

  Map<String, dynamic> _encodeStanding(StandingRow s) => {
        'rank': s.rank,
        'played': s.played,
        'won': s.won,
        'drawn': s.drawn,
        'lost': s.lost,
        'goalsFor': s.goalsFor,
        'goalsAgainst': s.goalsAgainst,
        'gd': s.gd,
        'pts': s.pts,
        'form': s.form,
        'team': _encodeTeam(s.team),
      };

  StandingRow _decodeStanding(Map<String, dynamic> s) {
    return StandingRow(
      rank: s['rank'] as int? ?? 0,
      played: s['played'] as int? ?? 0,
      won: s['won'] as int? ?? 0,
      drawn: s['drawn'] as int? ?? 0,
      lost: s['lost'] as int? ?? 0,
      goalsFor: s['goalsFor'] as int? ?? 0,
      goalsAgainst: s['goalsAgainst'] as int? ?? 0,
      gd: s['gd'] as int? ?? 0,
      pts: s['pts'] as int? ?? 0,
      form: s['form'] as String?,
      team: _decodeTeam(s['team'] as Map<String, dynamic>? ?? const {}),
    );
  }

  Map<String, dynamic> _encodeScorer(TopScorer s) => {
        'rank': s.rank,
        'playerName': s.playerName,
        'goals': s.goals,
        'assists': s.assists,
        'played': s.played,
        'team': _encodeTeam(s.team),
      };

  TopScorer _decodeScorer(Map<String, dynamic> s) {
    return TopScorer(
      rank: s['rank'] as int? ?? 0,
      playerName: '${s['playerName'] ?? ''}',
      goals: s['goals'] as int? ?? 0,
      assists: s['assists'] as int? ?? 0,
      played: s['played'] as int? ?? 0,
      team: _decodeTeam(s['team'] as Map<String, dynamic>? ?? const {}),
    );
  }

  Map<String, dynamic> _encodeTeam(FootballTeam t) => {
        'id': t.id,
        'name': t.name,
        'shortName': t.shortName,
        'logoAsset': t.logoAsset,
        'logoUrl': t.logoUrl,
        'letters': t.mark.letters,
        'color': t.mark.colorValue,
        'stadium': t.stadium,
        'city': t.city,
      };

  FootballTeam _decodeTeam(Map<String, dynamic> t) {
    return FootballTeam(
      id: '${t['id'] ?? ''}',
      name: '${t['name'] ?? 'Team'}',
      shortName: '${t['shortName'] ?? ''}',
      logoAsset: t['logoAsset'] as String?,
      logoUrl: t['logoUrl'] as String?,
      mark: ColorMark(
        '${t['letters'] ?? 'FC'}',
        t['color'] as int? ?? 0xFF37474F,
      ),
      stadium: t['stadium'] as String?,
      city: t['city'] as String?,
    );
  }
}
