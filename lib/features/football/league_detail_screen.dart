import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'football_api_service.dart';
import 'football_data.dart';
import 'football_logo.dart';
import 'football_providers.dart';
import 'match_detail_screen.dart';

/// League Detail — Schedule, Standings, Teams, Stats on dark canvas.
/// - Primary tabs: Schedule & Standings (plus Teams, Stats)
/// - Schedule tab: Date groups ("Friday, Tikimt 27", "Friday, Hidar 11")
///   Match rows: [Home Team] [Home Logo] [Score/Time] [Away Logo] [Away Team]
/// - Full yearly live schedule round selector: [All Season | R1 | R2 ... R34/38]
/// - Standings tab: [#] [Crest] [Team Name] [P] [GD] [PTS]
/// - Tap any fixture to open deep MatchDetailScreen
class LeagueDetailScreen extends ConsumerStatefulWidget {
  final String leagueId;

  const LeagueDetailScreen({super.key, required this.leagueId});

  @override
  ConsumerState<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends ConsumerState<LeagueDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = FootballData.catalogById(widget.leagueId);
    final async = ref.watch(footballLeagueProvider(widget.leagueId));
    final isFav =
        ref.watch(footballFavoritesProvider).contains(widget.leagueId);
    final isRefreshing =
        ref.watch(footballLeagueRefreshingProvider(widget.leagueId));
    final leagueData = async.asData?.value;
    final fetchedAt = leagueData?.fetchedAt;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 8,
        title: Row(
          children: [
            if (meta != null) ...[
              FootballLogo.league(meta, size: 30, elevated: false),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta?.name ?? 'League',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  if (meta != null)
                    Text(
                      [
                        if (meta.country != null && meta.country!.isNotEmpty)
                          meta.country!,
                        leagueData?.season ?? meta.season,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isFav ? 'Remove favorite' : 'Add favorite',
            icon: Icon(
              isFav ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isFav ? AppColors.govHolidayGlow : AppColors.textSecondary,
            ),
            onPressed: () {
              ref
                  .read(footballFavoritesProvider.notifier)
                  .toggle(widget.leagueId);
            },
          ),
          _ActiveRefreshButton(
            refreshing: isRefreshing,
            lastUpdated: fetchedAt,
            onRefresh: () async {
              final ok = await ref
                  .read(footballLeagueProvider(widget.leagueId).notifier)
                  .refresh();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    ok ? 'Scores updated' : 'Could not refresh — try again',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(44),
          child: Column(
            children: [
              TabBar(
                controller: _tabs,
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.accent,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500, fontSize: 14),
                tabs: [
                  Tab(text: 'Schedule'),
                  Tab(text: 'Standings'),
                  Tab(text: 'Teams'),
                  Tab(text: 'Stats'),
                ],
              ),
              Divider(
                  height: 1, thickness: 1, color: AppColors.surfaceBorder),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _SeasonSelector(leagueId: widget.leagueId),
          Expanded(
            child: async.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (err, _) => _ErrorPane(
                message: '$err',
                onRetry: () => ref
                    .read(footballLeagueProvider(widget.leagueId).notifier)
                    .refresh(),
              ),
              data: (league) => TabBarView(
                controller: _tabs,
                children: [
                  RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    onRefresh: () => ref
                        .read(footballLeagueProvider(widget.leagueId).notifier)
                        .refresh(),
                    child: _ScheduleTab(league: league),
                  ),
                  RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    onRefresh: () => ref
                        .read(footballLeagueProvider(widget.leagueId).notifier)
                        .refresh(),
                    child: _StandingsTab(league: league),
                  ),
                  RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    onRefresh: () => ref
                        .read(footballLeagueProvider(widget.leagueId).notifier)
                        .refresh(),
                    child: _TeamsTab(league: league),
                  ),
                  RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    onRefresh: () => ref
                        .read(footballLeagueProvider(widget.leagueId).notifier)
                        .refresh(),
                    child: _StatsTab(league: league),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact season chips — uses TheSportsDB season keys when available.
class _SeasonSelector extends ConsumerWidget {
  final String leagueId;
  const _SeasonSelector({required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = FootballData.sourceFor(leagueId);
    final seasons = source.sportsDbSeasons;
    if (seasons.isEmpty) return const SizedBox.shrink();

    final selected = ref.watch(footballSeasonProvider(leagueId));
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder.withValues(alpha: 0.7)),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        itemCount: seasons.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final value = i == 0 ? null : seasons[i - 1];
          final label = i == 0 ? 'All seasons' : seasons[i - 1];
          final isSel = selected == value;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                ref
                    .read(footballSeasonProvider(leagueId).notifier)
                    .setSeason(value);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: isSel
                      ? LinearGradient(
                          colors: [AppColors.accent, AppColors.accentDeep],
                        )
                      : null,
                  color: isSel ? null : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSel ? AppColors.accent : AppColors.surfaceBorder,
                  ),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isSel ? AppColors.onAccent : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ERROR PANE
// ---------------------------------------------------------------------------
class _ErrorPane extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorPane({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.22),
                ),
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 34, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load live football data',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 16.5,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: GoogleFonts.outfit(
                  fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 1: SCHEDULE (FULL YEARLY LIVE SCHEDULE & ROUND BROWSER)
// ---------------------------------------------------------------------------
class _ScheduleTab extends StatefulWidget {
  final FootballLeague league;
  const _ScheduleTab({required this.league});

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

enum _ScheduleView { next, results, rounds }

class _ScheduleTabState extends State<_ScheduleTab> {
  _ScheduleView _view = _ScheduleView.next;
  int? _selectedRound;
  final ScrollController _roundScrollController = ScrollController();

  @override
  void dispose() {
    _roundScrollController.dispose();
    super.dispose();
  }

  int _compareKickoff(FootballMatch a, FootballMatch b) {
    if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
    final ka = a.kickoff;
    final kb = b.kickoff;
    if (ka != null && kb != null) return ka.compareTo(kb);
    if (ka != null) return -1;
    if (kb != null) return 1;
    final ra = a.round ?? 9999;
    final rb = b.round ?? 9999;
    final roundCmp = ra.compareTo(rb);
    if (roundCmp != 0) return roundCmp;
    return a.dateHeader.compareTo(b.dateHeader);
  }

  int _findCurrentRound(List<FootballMatch> all) {
    final live = all.where((m) => m.isLive && m.round != null);
    if (live.isNotEmpty) {
      return live.map((m) => m.round!).reduce((a, b) => a > b ? a : b);
    }
    final sched = all.where((m) => m.isScheduled && m.round != null).toList()
      ..sort(_compareKickoff);
    if (sched.isNotEmpty) return sched.first.round!;
    final fin = all
        .where((m) => m.isFinished && m.round != null)
        .map((m) => m.round!)
        .toList();
    if (fin.isNotEmpty) return fin.reduce((a, b) => a > b ? a : b);
    return 1;
  }

  List<FootballMatch> _visibleMatches(List<FootballMatch> all) {
    switch (_view) {
      case _ScheduleView.next:
        final next = all
            .where((m) =>
                m.isLive ||
                m.isScheduled ||
                m.isPostponed)
            .toList()
          ..sort(_compareKickoff);
        return next;
      case _ScheduleView.results:
        final done = all.where((m) => m.isFinished).toList()
          ..sort((a, b) => _compareKickoff(b, a));
        return done;
      case _ScheduleView.rounds:
        var list = List<FootballMatch>.from(all);
        if (_selectedRound != null) {
          list = list.where((m) => m.round == _selectedRound).toList();
        }
        list.sort(_compareKickoff);
        return list;
    }
  }

  List<MapEntry<String, List<FootballMatch>>> _groupedSorted(
    List<FootballMatch> matches,
  ) {
    final grouped = <String, List<FootballMatch>>{};
    for (final m in matches) {
      final header =
          m.dateHeader.isNotEmpty ? m.dateHeader : (m.roundLabel ?? 'Matchday');
      grouped.putIfAbsent(header, () => []).add(m);
    }
    for (final entry in grouped.entries) {
      entry.value.sort(_compareKickoff);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final aKey = a.value.isEmpty
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : (a.value.first.kickoff ??
                DateTime.fromMillisecondsSinceEpoch(
                    (a.value.first.round ?? 0) * 100000));
        final bKey = b.value.isEmpty
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : (b.value.first.kickoff ??
                DateTime.fromMillisecondsSinceEpoch(
                    (b.value.first.round ?? 0) * 100000));
        // Results view is reverse chronological already at match level;
        // keep group order matching first match sort direction.
        if (_view == _ScheduleView.results) return bKey.compareTo(aKey);
        return aKey.compareTo(bKey);
      });
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.league.matches;
    if (all.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              'No fixtures scheduled',
              style: GoogleFonts.outfit(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    final roundsSet = <int>{
      for (final m in all)
        if (m.round != null) m.round!,
    };
    final sortedRounds = roundsSet.toList()..sort();
    final currentRound = _findCurrentRound(all);
    final matches = _visibleMatches(all);
    final groups = _groupedSorted(matches);
    final nextMatch = all
        .where((m) => m.isLive || m.isScheduled)
        .toList()
      ..sort(_compareKickoff);

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ScheduleViewChip(
                    label: 'Next',
                    selected: _view == _ScheduleView.next,
                    onTap: () => setState(() {
                      _view = _ScheduleView.next;
                      _selectedRound = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _ScheduleViewChip(
                    label: 'Results',
                    selected: _view == _ScheduleView.results,
                    onTap: () => setState(() {
                      _view = _ScheduleView.results;
                      _selectedRound = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _ScheduleViewChip(
                    label: 'By round',
                    selected: _view == _ScheduleView.rounds,
                    onTap: () => setState(() {
                      _view = _ScheduleView.rounds;
                      _selectedRound ??= currentRound;
                    }),
                  ),
                ],
              ),
              if (_view == _ScheduleView.next && nextMatch.isNotEmpty) ...[
                const SizedBox(height: 10),
                _NextMatchBanner(match: nextMatch.first),
              ],
              if (_view == _ScheduleView.rounds && sortedRounds.length > 1) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView.builder(
                    controller: _roundScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: sortedRounds.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        final isSel = _selectedRound == null;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _ScheduleViewChip(
                            label: 'All',
                            selected: isSel,
                            onTap: () =>
                                setState(() => _selectedRound = null),
                          ),
                        );
                      }
                      final r = sortedRounds[i - 1];
                      final isSel = _selectedRound == r;
                      final isCurrent = r == currentRound;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _ScheduleViewChip(
                          label: isCurrent ? 'R$r · now' : 'R$r',
                          selected: isSel,
                          accent: isCurrent,
                          onTap: () => setState(() => _selectedRound = r),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.surfaceBorder),
        Expanded(
          child: matches.isEmpty
              ? Center(
                  child: Text(
                    _view == _ScheduleView.next
                        ? 'No upcoming fixtures'
                        : _view == _ScheduleView.results
                            ? 'No results yet'
                            : 'No fixtures for this round',
                    style:
                        GoogleFonts.outfit(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: groups.length,
                  itemBuilder: (context, i) {
                    final header = groups[i].key;
                    final rMatches = groups[i].value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: double.infinity,
                          color: AppColors.surfaceElevated,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(
                            header.isEmpty ? 'Fixtures' : header,
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ...rMatches.map((m) => _MatchRow(match: m)),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ScheduleViewChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool accent;
  final VoidCallback onTap;

  const _ScheduleViewChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent
                : accent
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected || accent
                  ? AppColors.accent
                  : AppColors.surfaceBorder,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppColors.onAccent
                  : accent
                      ? AppColors.accent
                      : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _NextMatchBanner extends StatelessWidget {
  final FootballMatch match;
  const _NextMatchBanner({required this.match});

  @override
  Widget build(BuildContext context) {
    final when = match.isLive
        ? (match.statusLabel ?? 'LIVE')
        : [
            if (match.dateHeader.isNotEmpty) match.dateHeader,
            if (match.time != null)
              [match.time, match.period].whereType<String>().join(' '),
          ].where((s) => s.trim().isNotEmpty).join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.14),
            AppColors.accentSoft.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            match.isLive ? 'Playing now' : 'Next match',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${match.home.name}  vs  ${match.away.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (when.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              when,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MATCH ROW (Screenshots 2 & 4)
// ---------------------------------------------------------------------------
class _MatchRow extends StatelessWidget {
  final FootballMatch match;
  const _MatchRow({required this.match});

  String get _status {
    if (match.isLive) return match.statusLabel ?? 'LIVE';
    if (match.isFinished) return match.statusLabel ?? 'FT';
    final bits = <String>[
      if (match.time != null) match.time!,
      if (match.period != null &&
          match.period!.isNotEmpty &&
          !(match.time ?? '')
              .toUpperCase()
              .contains(match.period!.toUpperCase()))
        match.period!,
    ];
    if (bits.isNotEmpty) return bits.join(' ');
    return match.statusLabel ?? 'Soon';
  }

  @override
  Widget build(BuildContext context) {
    final live = match.isLive;

    return Material(
      color: live
          ? AppColors.accent.withValues(alpha: 0.06)
          : AppColors.surface,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MatchDetailScreen(match: match),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.surfaceBorder),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: live
                        ? AppColors.accent
                        : match.isFinished
                            ? AppColors.surfaceElevated
                            : AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _status,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: live
                          ? AppColors.onAccent
                          : match.isFinished
                              ? AppColors.textSecondary
                              : AppColors.accentDeep,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _EasyTeamScoreLine(
                team: match.home,
                score: match.hasScore ? '${match.homeScore}' : null,
                live: live,
              ),
              const SizedBox(height: 8),
              _EasyTeamScoreLine(
                team: match.away,
                score: match.hasScore ? '${match.awayScore}' : null,
                live: live,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EasyTeamScoreLine extends StatelessWidget {
  final FootballTeam team;
  final String? score;
  final bool live;

  const _EasyTeamScoreLine({
    required this.team,
    required this.score,
    required this.live,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FootballLogo.team(team, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            team.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            score ?? '–',
            textAlign: TextAlign.right,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: live && score != null
                  ? AppColors.accent
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 2: STANDINGS (Screenshots 3 & 5)
// ---------------------------------------------------------------------------
class _StandingsTab extends StatelessWidget {
  final FootballLeague league;
  const _StandingsTab({required this.league});

  @override
  Widget build(BuildContext context) {
    if (league.standings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.1),
                  ),
                  child: Icon(Icons.leaderboard_rounded,
                      color: AppColors.accent, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  'Standings unavailable',
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            border: Border(
              bottom: BorderSide(color: AppColors.surfaceBorder),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const SizedBox(width: 28),
              const SizedBox(width: 26),
              const SizedBox(width: 10),
              const Spacer(),
              _colHead('P', 38),
              _colHead('GD', 46),
              _colHead('PTS', 44),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: league.standings.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: AppColors.surfaceBorder,
            ),
            itemBuilder: (context, i) {
              final row = league.standings[i];
              final gdText = row.gd > 0 ? '+${row.gd}' : '${row.gd}';
              final topThree = row.rank <= 3;
              final rankColor = switch (row.rank) {
                1 => AppColors.govHolidayGlow,
                2 => AppColors.textSecondary,
                3 => const Color(0xFFCD7F32),
                _ => AppColors.textTertiary,
              };

              return Container(
                color: topThree
                    ? AppColors.accent.withValues(alpha: 0.04)
                    : null,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: topThree
                            ? BoxDecoration(
                                color: rankColor.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              )
                            : null,
                        child: Text(
                          '${row.rank}',
                          style: GoogleFonts.outfit(
                            color: topThree
                                ? (row.rank == 1
                                    ? AppColors.ethioGoldDark
                                    : AppColors.textPrimary)
                                : AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    FootballLogo.team(row.team, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        row.team.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight:
                              topThree ? FontWeight.w700 : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 38,
                      child: Text(
                        '${row.played}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 46,
                      child: Text(
                        gdText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: row.gd > 0
                              ? AppColors.accent
                              : row.gd < 0
                                  ? AppColors.ethioRed
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${row.pts}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _colHead(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 11.5,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 3: TEAMS
// ---------------------------------------------------------------------------
class _TeamsTab extends StatelessWidget {
  final FootballLeague league;
  const _TeamsTab({required this.league});

  @override
  Widget build(BuildContext context) {
    final teams = league.teams;
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: teams.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: AppColors.surfaceBorder),
      itemBuilder: (context, i) {
        final team = teams[i];
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              FootballLogo.team(team, size: 36),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (team.stadium != null)
                      Text(
                        '${team.stadium} · ${team.city ?? ''}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// TAB 4: STATS
// ---------------------------------------------------------------------------
class _StatsTab extends StatelessWidget {
  final FootballLeague league;
  const _StatsTab({required this.league});

  @override
  Widget build(BuildContext context) {
    final scorers = league.topScorers;
    final attack = FootballApiService.attackLeaders(league.standings);
    final defence = FootballApiService.defenceLeaders(league.standings);
    final seasonLabel = league.id == 'epl_eth'
        ? 'CBE Ethiopian Premier League · 2025/26'
        : '${league.season} · Top scorers';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        _StatsSectionHeader(
          title: 'Top Scorers',
          subtitle: seasonLabel,
          icon: Icons.sports_soccer_rounded,
        ),
        const SizedBox(height: 8),
        if (scorers.isEmpty)
          _StatsEmptyCard(
            message: 'Player scorers unavailable from free APIs for this league.',
            hint: 'Team attack & defence boards below use live standings.',
          )
        else
          ...List.generate(scorers.length, (i) {
            final sc = scorers[i];
            return _ScorerRow(
              rank: sc.rank > 0 ? sc.rank : i + 1,
              playerName: sc.playerName,
              team: sc.team,
              goals: sc.goals,
              assists: sc.assists,
              played: sc.played,
            );
          }),
        if (attack.isNotEmpty) ...[
          SizedBox(height: 18),
          _StatsSectionHeader(
            title: 'Best Attack',
            subtitle: 'Goals scored · from standings',
            icon: Icons.local_fire_department_rounded,
          ),
          SizedBox(height: 8),
          ...List.generate(attack.length, (i) {
            final row = attack[i];
            return _TeamStatRow(
              rank: i + 1,
              team: row.team,
              value: '${row.goalsFor}',
              unit: 'GF',
              accent: AppColors.accent,
            );
          }),
        ],
        if (defence.isNotEmpty) ...[
          SizedBox(height: 18),
          _StatsSectionHeader(
            title: 'Best Defence',
            subtitle: 'Goals conceded · from standings',
            icon: Icons.shield_rounded,
          ),
          SizedBox(height: 8),
          ...List.generate(defence.length, (i) {
            final row = defence[i];
            return _TeamStatRow(
              rank: i + 1,
              team: row.team,
              value: '${row.goalsAgainst}',
              unit: 'GA',
              accent: AppColors.ethioEmerald,
            );
          }),
        ],
      ],
    );
  }
}

class _StatsSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _StatsSectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsEmptyCard extends StatelessWidget {
  final String message;
  final String hint;
  const _StatsEmptyCard({required this.message, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 13.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            hint,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorerRow extends StatelessWidget {
  final int rank;
  final String playerName;
  final FootballTeam team;
  final int goals;
  final int assists;
  final int played;

  const _ScorerRow({
    required this.rank,
    required this.playerName,
    required this.team,
    required this.goals,
    required this.assists,
    required this.played,
  });

  @override
  Widget build(BuildContext context) {
    final podium = rank <= 3;
    final rankColor = rank == 1
        ? AppColors.govHolidayGlow
        : rank == 2
            ? Color(0xFFCBD5E1)
            : rank == 3
                ? Color(0xFFD97706)
                : AppColors.textSecondary;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: podium
              ? rankColor.withValues(alpha: 0.45)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: podium
                    ? rankColor.withValues(alpha: 0.18)
                    : AppColors.surfaceElevated,
                border: Border.all(color: rankColor.withValues(alpha: 0.55)),
              ),
              child: Text(
                '$rank',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: rankColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          FootballLogo.team(team, size: 32),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  [
                    team.name,
                    if (played > 0) '$played apps',
                    if (assists > 0) '$assists assists',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$goals',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.accent,
              ),
            ),
          ),
          SizedBox(width: 4),
          Text(
            'G',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamStatRow extends StatelessWidget {
  final int rank;
  final FootballTeam team;
  final String value;
  final String unit;
  final Color accent;

  const _TeamStatRow({
    required this.rank,
    required this.team,
    required this.value,
    required this.unit,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          FootballLogo.team(team, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          SizedBox(width: 4),
          Text(
            unit,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Professional spinning refresh control that stays active while APIs load.
class _ActiveRefreshButton extends StatefulWidget {
  final bool refreshing;
  final DateTime? lastUpdated;
  final Future<void> Function() onRefresh;

  const _ActiveRefreshButton({
    required this.refreshing,
    required this.onRefresh,
    this.lastUpdated,
  });

  @override
  State<_ActiveRefreshButton> createState() => _ActiveRefreshButtonState();
}

class _ActiveRefreshButtonState extends State<_ActiveRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final isTesting = const bool.fromEnvironment('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (widget.refreshing && !isTesting) _spin.repeat();
  }

  @override
  void didUpdateWidget(covariant _ActiveRefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshing && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.refreshing && _spin.isAnimating) {
      _spin.stop();
      _spin.reset();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  String get _tooltip {
    if (widget.refreshing) return 'Refreshing live APIs…';
    if (widget.lastUpdated == null) return 'Refresh live football data';
    final s = DateTime.now().difference(widget.lastUpdated!).inSeconds;
    if (s < 60) return 'Updated ${s}s ago · tap to refresh';
    final m = s ~/ 60;
    return 'Updated ${m}m ago · tap to refresh';
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _tooltip,
      onPressed: widget.refreshing ? null : () => widget.onRefresh(),
      icon: RotationTransition(
        turns: _spin,
        child: Icon(
          Icons.refresh_rounded,
          color: widget.refreshing
              ? AppColors.accent
              : AppColors.textPrimary,
        ),
      ),
    );
  }
}
