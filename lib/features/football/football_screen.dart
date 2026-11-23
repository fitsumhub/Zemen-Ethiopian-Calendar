import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ads/native_ad_widget.dart';
import '../../core/localization/locale_strings.dart';
import '../../core/theme/app_colors.dart';
import '../shared/providers.dart';
import 'football_data.dart';
import 'football_logo.dart';
import 'football_network_config.dart';
import 'football_providers.dart';
import 'league_detail_screen.dart';
import 'match_detail_screen.dart';

/// Professional Football hub — leagues, live scores, fixtures.
class FootballScreen extends ConsumerStatefulWidget {
  const FootballScreen({super.key});

  @override
  ConsumerState<FootballScreen> createState() => _FootballScreenState();
}

class _FootballScreenState extends ConsumerState<FootballScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeFilter = ref.watch(footballFilterProvider);
    final searchQuery = ref.watch(footballSearchProvider);
    final allLeagues = ref.watch(footballCatalogProvider);
    final favorites = ref.watch(footballFavoritesProvider);

    return ColoredBox(
      color: AppColors.canvas,
      child: Column(
        children: [
          const _FootballHeroBar(),
          if (FootballNetworkConfig.needsProxySetupHint)
            const _WebProxyHintBanner(),
          _FilterStrip(
            activeFilter: activeFilter,
            onSelect: (f) =>
                ref.read(footballFilterProvider.notifier).setFilter(f),
          ),
          Expanded(
            child: activeFilter == FootballFilter.leagues
                ? _LeagueListView(
                    leagues: allLeagues,
                    favorites: favorites,
                    searchQuery: searchQuery,
                    searchController: _searchController,
                    onSearchChanged: (q) =>
                        ref.read(footballSearchProvider.notifier).setQuery(q),
                    onToggleFav: (id) =>
                        ref.read(footballFavoritesProvider.notifier).toggle(id),
                  )
                : _MatchesListView(filter: activeFilter),
          ),
        ],
      ),
    );
  }
}

class _WebProxyHintBanner extends StatelessWidget {
  const _WebProxyHintBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentSoft.withValues(alpha: 0.65),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Row(
          children: [
            Icon(Icons.cloud_outlined, size: 18, color: AppColors.accentDeep),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Local CORS proxy not running. Start workers/football-proxy '
                '(npm run dev) or omit FOOTBALL_PROXY_BASE to use the '
                'deployed Worker.',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HERO
// ---------------------------------------------------------------------------
class _FootballHeroBar extends ConsumerWidget {
  const _FootballHeroBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshing = ref.watch(footballGlobalRefreshProvider);
    final isDark = AppColors.isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0A1612),
                  AppColors.accentDeep.withValues(alpha: 0.55),
                  const Color(0xFF121A22),
                ]
              : [
                  AppColors.accentSoft.withValues(alpha: 0.55),
                  AppColors.surface,
                  AppColors.surfaceElevated,
                ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -22,
            child: IgnorePointer(
              child: Icon(
                Icons.sports_soccer_rounded,
                size: 96,
                color: AppColors.accent.withValues(alpha: isDark ? 0.08 : 0.06),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accentDeep,
                      AppColors.accent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.sports_soccer_rounded,
                  color: AppColors.onAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  'Football',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.05,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  refreshing ? 'Updating scores…' : 'Scores, fixtures & tables',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.45),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: refreshing
                      ? null
                      : () async {
                          final n = await ref
                              .read(footballGlobalRefreshProvider.notifier)
                              .refreshAll();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                n > 0
                                    ? 'Live football refreshed · $n leagues'
                                    : 'Refresh in progress or failed — try again',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        },
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: refreshing
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.accent,
                              ),
                            )
                          : Icon(
                              Icons.refresh_rounded,
                              color: AppColors.textPrimary,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FILTER STRIP
// ---------------------------------------------------------------------------
class _FilterStrip extends ConsumerWidget {
  final FootballFilter activeFilter;
  final ValueChanged<FootballFilter> onSelect;

  const _FilterStrip({
    required this.activeFilter,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(currentAppLanguageProvider);
    // Leagues first, then match views.
    final items = [
      (
        FootballFilter.leagues,
        LocaleStrings.get('fb_filter_leagues', lang),
        Icons.emoji_events_rounded
      ),
      (
        FootballFilter.upcoming,
        LocaleStrings.get('fb_filter_upcoming', lang),
        Icons.schedule_rounded
      ),
      (
        FootballFilter.today,
        LocaleStrings.get('fb_filter_today', lang),
        Icons.today_rounded
      ),
      (
        FootballFilter.live,
        LocaleStrings.get('fb_filter_live', lang),
        Icons.fiber_manual_record_rounded
      ),
      (
        FootballFilter.finished,
        LocaleStrings.get('fb_filter_results', lang),
        Icons.check_circle_outline_rounded
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder.withValues(alpha: 0.7)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: items.map((item) {
            final isSelected = activeFilter == item.$1;
            final isLive = item.$1 == FootballFilter.live;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(item.$1),
                  borderRadius: BorderRadius.circular(22),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: isLive
                                  ? [
                                      AppColors.accent,
                                      const Color(0xFFB42318),
                                    ]
                                  : [
                                      AppColors.accent,
                                      AppColors.accentDeep,
                                    ],
                            )
                          : null,
                      color: isSelected ? null : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.0)
                            : AppColors.surfaceBorder,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (isLive
                                        ? const Color(0xFFB42318)
                                        : AppColors.accent)
                                    .withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.$3,
                          size: isLive ? 11 : 14,
                          color: isSelected
                              ? AppColors.onAccent
                              : (isLive
                                  ? AppColors.accent
                                  : AppColors.textSecondary),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.$2,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.onAccent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LEAGUE LIST
// ---------------------------------------------------------------------------
class _LeagueListView extends StatelessWidget {
  final List<FootballLeague> leagues;
  final Set<String> favorites;
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onToggleFav;

  const _LeagueListView({
    required this.leagues,
    required this.favorites,
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
    required this.onToggleFav,
  });

  @override
  Widget build(BuildContext context) {
    final q = searchQuery.trim().toLowerCase();
    final filtered = leagues.where((l) {
      if (q.isEmpty) return true;
      return l.name.toLowerCase().contains(q) ||
          l.shortName.toLowerCase().contains(q) ||
          (l.country?.toLowerCase().contains(q) ?? false);
    }).toList();

    final favLeagues =
        filtered.where((l) => favorites.contains(l.id)).toList();
    final otherLeagues =
        filtered.where((l) => !favorites.contains(l.id)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Find a league…',
              hintStyle: GoogleFonts.outfit(
                color: AppColors.textTertiary,
                fontSize: 13.5,
              ),
              prefixIcon: Icon(Icons.search_rounded,
                  color: AppColors.textSecondary),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.accent,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        if (favLeagues.isNotEmpty) ...[
          _SectionLabel(
            title: 'Favorites',
            subtitle: '${favLeagues.length}',
            icon: Icons.star_rounded,
            iconColor: AppColors.govHolidayGlow,
          ),
          ...favLeagues.map(
            (l) => _LeagueTile(
              league: l,
              isFavorite: true,
              onToggleFav: () => onToggleFav(l.id),
            ),
          ),
          const SizedBox(height: 8),
        ],
        _SectionLabel(
          title: favLeagues.isEmpty ? 'All competitions' : 'All leagues',
          subtitle: '${otherLeagues.length}',
          icon: Icons.public_rounded,
        ),
        if (filtered.isEmpty)
          const _EmptyPane(
            icon: Icons.search_off_rounded,
            title: 'No leagues found',
            subtitle: 'Try another search term',
          )
        else
          ...otherLeagues.map(
            (l) => _LeagueTile(
              league: l,
              isFavorite: favorites.contains(l.id),
              onToggleFav: () => onToggleFav(l.id),
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;

  const _SectionLabel({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor ?? AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeagueTile extends StatelessWidget {
  final FootballLeague league;
  final bool isFavorite;
  final VoidCallback onToggleFav;

  const _LeagueTile({
    required this.league,
    required this.isFavorite,
    required this.onToggleFav,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LeagueDetailScreen(leagueId: league.id),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                FootballLogo.league(league, size: 48, elevated: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        league.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (league.country != null &&
                              league.country!.isNotEmpty)
                            league.country!,
                          if (league.season.isNotEmpty) league.season,
                          if (league.shortName.isNotEmpty) league.shortName,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
                  onPressed: onToggleFav,
                  icon: Icon(
                    isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: isFavorite
                        ? AppColors.govHolidayGlow
                        : AppColors.textTertiary,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MATCHES LIST
// ---------------------------------------------------------------------------
class _MatchesListView extends ConsumerWidget {
  final FootballFilter filter;
  const _MatchesListView({required this.filter});

  bool _isToday(FootballMatch m) {
    if (m.kickoff != null) {
      final n = DateTime.now();
      final k = m.kickoff!;
      return k.year == n.year && k.month == n.month && k.day == n.day;
    }
    return m.isLive;
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
    return ra.compareTo(rb);
  }

  /// Next games only — live + soonest scheduled, capped for easy reading.
  List<FootballMatch> _nextMatches(List<FootballMatch> matches, {int limit = 8}) {
    final now = DateTime.now();
    final next = matches.where((m) {
      if (m.isLive) return true;
      if (!m.isScheduled && !m.isPostponed) return false;
      if (m.kickoff != null) return !m.kickoff!.isBefore(now.subtract(const Duration(hours: 3)));
      return true;
    }).toList()
      ..sort(_compareKickoff);
    if (next.length <= limit) return next;
    return next.take(limit).toList();
  }

  List<FootballMatch> _filterMatches(List<FootballMatch> matches) {
    switch (filter) {
      case FootballFilter.live:
        return matches.where((m) => m.isLive).toList();
      case FootballFilter.today:
        return matches.where(_isToday).toList()..sort(_compareKickoff);
      case FootballFilter.upcoming:
        return _nextMatches(matches);
      case FootballFilter.finished:
        final done = matches.where((m) => m.isFinished).toList()
          ..sort((a, b) => _compareKickoff(b, a));
        return done.take(10).toList();
      case FootballFilter.leagues:
        return matches;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void goLeagues() =>
        ref.read(footballFilterProvider.notifier).setFilter(FootballFilter.leagues);

    if (filter == FootballFilter.live) {
      final async = ref.watch(footballLiveMatchesProvider);
      return async.when(
        loading: () => const _LoadingPane(label: 'Loading live scores…'),
        error: (err, _) => _EmptyPane(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load live scores',
          subtitle: 'Check your connection, then try again',
          actionLabel: 'Browse leagues',
          onAction: goLeagues,
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return _EmptyPane(
              icon: Icons.sports_soccer_outlined,
              title: 'No live matches right now',
              subtitle: 'See upcoming fixtures instead',
              actionLabel: 'Upcoming',
              onAction: () => ref
                  .read(footballFilterProvider.notifier)
                  .setFilter(FootballFilter.upcoming),
            );
          }
          final sorted = [...matches]..sort(_compareKickoff);
          return _CrossLeagueMatchList(matches: sorted);
        },
      );
    }

    if (filter == FootballFilter.today) {
      final async = ref.watch(footballTodayMatchesProvider);
      return async.when(
        loading: () => const _LoadingPane(label: 'Loading today\'s matches…'),
        error: (err, _) => _EmptyPane(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load today\'s matches',
          subtitle: 'Check your connection, then try again',
          actionLabel: 'Upcoming',
          onAction: () => ref
              .read(footballFilterProvider.notifier)
              .setFilter(FootballFilter.upcoming),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            // Perfect path: if nothing today, jump users to next games.
            return _EmptyPane(
              icon: Icons.event_busy_rounded,
              title: 'No matches today',
              subtitle: 'See the next fixtures coming up',
              actionLabel: 'Show upcoming',
              onAction: () => ref
                  .read(footballFilterProvider.notifier)
                  .setFilter(FootballFilter.upcoming),
            );
          }
          final sorted = [...matches]..sort(_compareKickoff);
          return _CrossLeagueMatchList(matches: sorted);
        },
      );
    }

    final catalog = ref.watch(footballCatalogProvider);
    var loadingCount = 0;
    var errorCount = 0;
    final groups = <({FootballLeague league, List<FootballMatch> matches, int catalogIndex})>[];

    for (var i = 0; i < catalog.length; i++) {
      final meta = catalog[i];
      final async = ref.watch(footballLeagueProvider(meta.id));

      async.when(
        loading: () {
          loadingCount++;
        },
        error: (_, _) {
          errorCount++;
        },
        data: (league) {
          final matches = _filterMatches(league.matches);
          if (matches.isEmpty) return;
          groups.add((league: league, matches: matches, catalogIndex: i));
        },
      );
    }

    // Soonest kickoff first so next games rise to the top.
    groups.sort((a, b) {
      final am = a.matches.first;
      final bm = b.matches.first;
      return _compareKickoff(am, bm);
    });

    if (groups.isEmpty && loadingCount > 0) {
      return const _LoadingPane(label: 'Loading next fixtures…');
    }

    if (groups.isEmpty && errorCount > 0) {
      final lang = ref.watch(currentAppLanguageProvider);
      return _EmptyPane(
        icon: Icons.wifi_off_rounded,
        title: LocaleStrings.get('fb_load_error', lang),
        subtitle: LocaleStrings.get('fb_load_error_sub', lang),
        actionLabel: LocaleStrings.get('fb_retry', lang),
        onAction: () {
          ref.read(footballGlobalRefreshProvider.notifier).refreshAll();
        },
      );
    }

    if (groups.isEmpty) {
      final label = switch (filter) {
        FootballFilter.live => 'No live matches right now',
        FootballFilter.today => 'No matches scheduled for today',
        FootballFilter.upcoming => 'No upcoming fixtures',
        FootballFilter.finished => 'No recent results',
        FootballFilter.leagues => 'No matches',
      };
      return _EmptyPane(
        icon: Icons.sports_soccer_outlined,
        title: label,
        subtitle: 'Browse leagues for full schedules',
        actionLabel: 'Browse leagues',
        onAction: goLeagues,
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        await ref.read(footballGlobalRefreshProvider.notifier).refreshAll();
      },
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 28),
        children: [
          if (filter == FootballFilter.upcoming)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Text(
                'Next games',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          for (var i = 0; i < groups.length; i++)
            _LeagueMatchGroup(
              league: groups[i].league,
              matches: groups[i].matches,
              showAd: i == 1,
            ),
        ],
      ),
    );
  }
}

class _CrossLeagueMatchList extends ConsumerWidget {
  final List<FootballMatch> matches;
  const _CrossLeagueMatchList({required this.matches});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byComp = <String, List<FootballMatch>>{};
    for (final m in matches) {
      final key = m.competitionId.isNotEmpty
          ? m.competitionId
          : m.competitionName;
      byComp.putIfAbsent(key, () => []).add(m);
    }

    final children = <Widget>[];
    var i = 0;
    for (final entry in byComp.entries) {
      final meta = FootballData.catalogById(entry.key);
      final league = meta ??
          FootballLeague(
            id: entry.key,
            name: entry.value.first.competitionName.isNotEmpty
                ? entry.value.first.competitionName
                : entry.key,
            shortName: entry.key,
            mark: const ColorMark('FC', 0xFF37474F),
            matches: entry.value,
            standings: [],
          );
      children.add(
        _LeagueMatchGroup(
          league: league.copyWith(matches: entry.value),
          matches: entry.value,
          showAd: i == 1,
        ),
      );
      i++;
    }

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(footballLiveMatchesProvider);
        ref.invalidate(footballTodayMatchesProvider);
        await ref.read(footballGlobalRefreshProvider.notifier).refreshAll();
      },
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 28),
        children: children,
      ),
    );
  }
}

class _LeagueMatchGroup extends StatelessWidget {
  final FootballLeague league;
  final List<FootballMatch> matches;
  final bool showAd;

  const _LeagueMatchGroup({
    required this.league,
    required this.matches,
    this.showAd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: AppColors.surfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: InkWell(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LeagueDetailScreen(leagueId: league.id),
                  ),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    FootballLogo.league(league, size: 26, elevated: false),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        league.name,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Text(
                        '${matches.length}',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < matches.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: AppColors.surfaceBorder),
                  _HomeMatchRow(match: matches[i]),
                ],
              ],
            ),
          ),
          if (showAd)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: NativeAdWidget(),
            ),
        ],
      ),
    );
  }
}

class _HomeMatchRow extends StatelessWidget {
  final FootballMatch match;
  const _HomeMatchRow({required this.match});

  String get _status {
    if (match.isLive) return match.statusLabel ?? 'LIVE';
    if (match.isFinished) return match.statusLabel ?? 'FT';
    final bits = <String>[
      if (match.time != null) match.time!,
      if (match.period != null) match.period!,
    ];
    if (bits.isNotEmpty) return bits.join(' ');
    return match.statusLabel ?? 'Soon';
  }

  @override
  Widget build(BuildContext context) {
    // Stacked scoreboard (home / away) — easiest to scan on phones.
    return Material(
      color: match.isLive
          ? AppColors.accent.withValues(alpha: 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MatchDetailScreen(match: match),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: match.isLive
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
                        color: match.isLive
                            ? AppColors.onAccent
                            : match.isFinished
                                ? AppColors.textSecondary
                                : AppColors.accentDeep,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (match.dateHeader.isNotEmpty)
                    Flexible(
                      child: Text(
                        match.dateHeader,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _EasyTeamLine(
                team: match.home,
                score: match.hasScore ? '${match.homeScore}' : null,
                emphasizeScore: match.isLive,
              ),
              const SizedBox(height: 8),
              _EasyTeamLine(
                team: match.away,
                score: match.hasScore ? '${match.awayScore}' : null,
                emphasizeScore: match.isLive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EasyTeamLine extends StatelessWidget {
  final FootballTeam team;
  final String? score;
  final bool emphasizeScore;

  const _EasyTeamLine({
    required this.team,
    required this.score,
    this.emphasizeScore = false,
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
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            score ?? '–',
            textAlign: TextAlign.right,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: emphasizeScore && score != null
                  ? AppColors.accent
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingPane extends StatelessWidget {
  final String label;
  const _LoadingPane({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 14),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPane extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyPane({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 28),
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
            child: Icon(icon, size: 34, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel!,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
