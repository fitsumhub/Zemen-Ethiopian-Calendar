import 'package:material_ui/material_ui.dart';

/// Phase / status of a football match.
enum MatchPhase { scheduled, live, finished, postponed, cancelled, abandoned }

/// Event type occurring in a match timeline.
enum MatchEventType {
  goal,
  penaltyGoal,
  missedPenalty,
  ownGoal,
  yellowCard,
  redCard,
  substitution,
  varDecision,
}

/// A football competition / league.
class Competition {
  final String id;
  final String name;
  final String shortName;
  final String country;
  final String? logoAsset;
  final String? logoUrl;
  final String season;
  final bool isFavorite;
  final String? sourceLabel;

  const Competition({
    required this.id,
    required this.name,
    required this.shortName,
    required this.country,
    this.logoAsset,
    this.logoUrl,
    this.season = '2026-2027',
    this.isFavorite = false,
    this.sourceLabel,
  });

  Competition copyWith({
    String? id,
    String? name,
    String? shortName,
    String? country,
    String? logoAsset,
    String? logoUrl,
    String? season,
    bool? isFavorite,
    String? sourceLabel,
  }) {
    return Competition(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      country: country ?? this.country,
      logoAsset: logoAsset ?? this.logoAsset,
      logoUrl: logoUrl ?? this.logoUrl,
      season: season ?? this.season,
      isFavorite: isFavorite ?? this.isFavorite,
      sourceLabel: sourceLabel ?? this.sourceLabel,
    );
  }
}

/// Color badge / abbreviation fallback mark.
class ColorMark {
  final String letters;
  final int colorValue;
  const ColorMark(this.letters, this.colorValue);

  Color get color => Color(colorValue);
}

/// A football team / club.
class FootballTeam {
  final String id;
  final String name;
  final String shortName;
  final ColorMark mark;
  final String? logoAsset;
  final String? logoUrl;
  final String? stadium;
  final String? city;
  final int? formedYear;

  const FootballTeam({
    required this.name,
    required this.mark,
    this.id = '',
    this.shortName = '',
    this.logoAsset,
    this.logoUrl,
    this.stadium,
    this.city,
    this.formedYear,
  });

  String get effectiveShortName =>
      shortName.isNotEmpty ? shortName : mark.letters;
}

/// A player in a team roster or match lineup.
class LineupPlayer {
  final String id;
  final String name;
  final int number;
  final String position; // GK, DF, MF, FW
  final bool isCaptain;
  final int? gridRow;
  final int? gridCol;

  const LineupPlayer({
    required this.id,
    required this.name,
    required this.number,
    required this.position,
    this.isCaptain = false,
    this.gridRow,
    this.gridCol,
  });
}

/// Team lineup and formation for a specific match.
class MatchLineup {
  final String teamName;
  final String formation; // e.g. "4-3-3", "4-2-3-1"
  final String? coach;
  final List<LineupPlayer> startingXI;
  final List<LineupPlayer> substitutes;

  const MatchLineup({
    required this.teamName,
    required this.formation,
    required this.startingXI,
    this.substitutes = const [],
    this.coach,
  });
}

/// Key event in match timeline (goal, card, substitution, VAR).
class MatchEvent {
  final int minute;
  final int? extraMinute;
  final MatchEventType type;
  final String teamName;
  final bool isHome;
  final String playerName;
  final String? assistOrPlayerOut;
  final String? detail;

  const MatchEvent({
    required this.minute,
    required this.type,
    required this.teamName,
    required this.isHome,
    required this.playerName,
    this.extraMinute,
    this.assistOrPlayerOut,
    this.detail,
  });

  String get displayMinute {
    if (extraMinute != null && extraMinute! > 0) {
      return "$minute'+$extraMinute'";
    }
    return "$minute'";
  }
}

/// Comparative match statistics.
class MatchStatistics {
  final int homePossession; // percentage e.g. 58
  final int awayPossession; // percentage e.g. 42
  final int homeShots;
  final int awayShots;
  final int homeShotsOnTarget;
  final int awayShotsOnTarget;
  final int homeCorners;
  final int awayCorners;
  final int homeFouls;
  final int awayFouls;
  final int homeYellowCards;
  final int awayYellowCards;
  final int homeRedCards;
  final int awayRedCards;
  final int homeOffsides;
  final int awayOffsides;
  final int homePassAccuracy;
  final int awayPassAccuracy;

  const MatchStatistics({
    this.homePossession = 0,
    this.awayPossession = 0,
    this.homeShots = 0,
    this.awayShots = 0,
    this.homeShotsOnTarget = 0,
    this.awayShotsOnTarget = 0,
    this.homeCorners = 0,
    this.awayCorners = 0,
    this.homeFouls = 0,
    this.awayFouls = 0,
    this.homeYellowCards = 0,
    this.awayYellowCards = 0,
    this.homeRedCards = 0,
    this.awayRedCards = 0,
    this.homeOffsides = 0,
    this.awayOffsides = 0,
    this.homePassAccuracy = 0,
    this.awayPassAccuracy = 0,
  });

  bool get hasMeaningfulData =>
      homePossession + awayPossession + homeShots + awayShots > 0;
}

/// Head-to-Head historical record.
class HeadToHead {
  final int totalPlayed;
  final int homeWins;
  final int awayWins;
  final int draws;
  final List<FootballMatch> previousMatches;

  const HeadToHead({
    required this.totalPlayed,
    required this.homeWins,
    required this.awayWins,
    required this.draws,
    this.previousMatches = const [],
  });
}

/// A football match / fixture.
class FootballMatch {
  final String id;
  final String competitionId;
  final String competitionName;
  final String dateHeader; // Ethiopian date header e.g. "Friday, Tikimt 27"
  final FootballTeam home;
  final FootballTeam away;
  final int? round; // e.g. 1..38
  final String? roundLabel; // e.g. "Round 8" or "Matchday 10"
  final String? time; // e.g. "3:00"
  final String? period; // e.g. "PM" or "1H"
  final int? homeScore;
  final int? awayScore;
  final int? homeHtScore;
  final int? awayHtScore;
  final int? homePenScore;
  final int? awayPenScore;
  final MatchPhase phase;
  final String? statusLabel; // e.g. "FT", "LIVE 74'", "3:00 PM"
  final DateTime? kickoff;
  final String? venue;
  final String? referee;
  final List<MatchEvent> events;
  final MatchLineup? homeLineup;
  final MatchLineup? awayLineup;
  final MatchStatistics? statistics;
  final HeadToHead? headToHead;

  const FootballMatch({
    required this.dateHeader,
    required this.home,
    required this.away,
    this.id = '',
    this.competitionId = '',
    this.competitionName = '',
    this.round,
    this.roundLabel,
    this.time,
    this.period,
    this.homeScore,
    this.awayScore,
    this.homeHtScore,
    this.awayHtScore,
    this.homePenScore,
    this.awayPenScore,
    this.phase = MatchPhase.scheduled,
    this.statusLabel,
    this.kickoff,
    this.venue,
    this.referee,
    this.events = const [],
    this.homeLineup,
    this.awayLineup,
    this.statistics,
    this.headToHead,
  });

  bool get hasScore => homeScore != null && awayScore != null;
  bool get isLive => phase == MatchPhase.live;
  bool get isFinished => phase == MatchPhase.finished;
  bool get isScheduled => phase == MatchPhase.scheduled;
  bool get isPostponed => phase == MatchPhase.postponed;
  bool get isCancelled => phase == MatchPhase.cancelled;
  bool get isAbandoned => phase == MatchPhase.abandoned;
  bool get hasHalfTimeScore => homeHtScore != null && awayHtScore != null;
  bool get hasPenaltyScore => homePenScore != null && awayPenScore != null;

  /// Stable cache / provider key — never merge on team-name similarity alone.
  String get stableKey {
    if (id.isNotEmpty) {
      return '${competitionId.isEmpty ? 'x' : competitionId}|$id';
    }
    final day = kickoff != null
        ? '${kickoff!.year}-${kickoff!.month}-${kickoff!.day}'
        : dateHeader;
    return '$competitionId|${home.name}|${away.name}|$day';
  }

  FootballMatch copyWith({
    String? id,
    String? competitionId,
    String? competitionName,
    String? dateHeader,
    FootballTeam? home,
    FootballTeam? away,
    int? round,
    String? roundLabel,
    String? time,
    String? period,
    int? homeScore,
    int? awayScore,
    int? homeHtScore,
    int? awayHtScore,
    int? homePenScore,
    int? awayPenScore,
    MatchPhase? phase,
    String? statusLabel,
    DateTime? kickoff,
    String? venue,
    String? referee,
    List<MatchEvent>? events,
    MatchLineup? homeLineup,
    MatchLineup? awayLineup,
    MatchStatistics? statistics,
    HeadToHead? headToHead,
  }) {
    return FootballMatch(
      id: id ?? this.id,
      competitionId: competitionId ?? this.competitionId,
      competitionName: competitionName ?? this.competitionName,
      dateHeader: dateHeader ?? this.dateHeader,
      home: home ?? this.home,
      away: away ?? this.away,
      round: round ?? this.round,
      roundLabel: roundLabel ?? this.roundLabel,
      time: time ?? this.time,
      period: period ?? this.period,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      homeHtScore: homeHtScore ?? this.homeHtScore,
      awayHtScore: awayHtScore ?? this.awayHtScore,
      homePenScore: homePenScore ?? this.homePenScore,
      awayPenScore: awayPenScore ?? this.awayPenScore,
      phase: phase ?? this.phase,
      statusLabel: statusLabel ?? this.statusLabel,
      kickoff: kickoff ?? this.kickoff,
      venue: venue ?? this.venue,
      referee: referee ?? this.referee,
      events: events ?? this.events,
      homeLineup: homeLineup ?? this.homeLineup,
      awayLineup: awayLineup ?? this.awayLineup,
      statistics: statistics ?? this.statistics,
      headToHead: headToHead ?? this.headToHead,
    );
  }
}

/// Official league standing table row.
class StandingRow {
  final int rank;
  final FootballTeam team;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int gd;
  final int pts;
  final String? form; // e.g. "WWDLD"

  const StandingRow({
    required this.rank,
    required this.team,
    required this.played,
    required this.gd,
    required this.pts,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.form,
  });
}

/// Top scorer in a league.
class TopScorer {
  final int rank;
  final String playerName;
  final FootballTeam team;
  final int goals;
  final int assists;
  final int played;

  const TopScorer({
    required this.rank,
    required this.playerName,
    required this.team,
    required this.goals,
    this.assists = 0,
    this.played = 0,
  });
}

/// Complete league data container.
class FootballLeague {
  final String id;
  final String name;
  final String shortName;
  final ColorMark mark;
  final String? logoAsset;
  final String? logoUrl;
  final String? country;
  final String season;
  final List<FootballMatch> matches;
  final List<StandingRow> standings;
  final List<FootballTeam> teams;
  final List<TopScorer> topScorers;
  final bool isLive;
  final DateTime? fetchedAt;
  final String? sourceLabel;

  const FootballLeague({
    required this.id,
    required this.name,
    required this.shortName,
    required this.mark,
    required this.matches,
    required this.standings,
    this.teams = const [],
    this.topScorers = const [],
    this.logoAsset,
    this.logoUrl,
    this.country,
    this.season = '2026-2027',
    this.isLive = false,
    this.fetchedAt,
    this.sourceLabel,
  });

  FootballLeague copyWith({
    List<FootballMatch>? matches,
    List<StandingRow>? standings,
    List<FootballTeam>? teams,
    List<TopScorer>? topScorers,
    bool? isLive,
    DateTime? fetchedAt,
    String? sourceLabel,
    String? logoUrl,
    String? country,
    String? season,
  }) {
    return FootballLeague(
      id: id,
      name: name,
      shortName: shortName,
      mark: mark,
      logoAsset: logoAsset,
      logoUrl: logoUrl ?? this.logoUrl,
      country: country ?? this.country,
      season: season ?? this.season,
      matches: matches ?? this.matches,
      standings: standings ?? this.standings,
      teams: teams ?? this.teams,
      topScorers: topScorers ?? this.topScorers,
      isLive: isLive ?? this.isLive,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      sourceLabel: sourceLabel ?? this.sourceLabel,
    );
  }
}
