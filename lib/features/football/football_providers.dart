import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'football_api_service.dart';
import 'football_data.dart';
import 'football_refresh_manager.dart';
import 'football_repository.dart';

enum FootballFilter {
  leagues,
  live,
  today,
  upcoming,
  finished,
}

final footballRepositoryProvider = Provider<FootballRepository>((ref) {
  final repo = FootballRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final footballApiProvider = Provider<FootballApiService>((ref) {
  return ref.watch(footballRepositoryProvider).api;
});

final footballCatalogProvider = Provider<List<FootballLeague>>((ref) {
  return FootballData.catalog;
});

/// Current active filter tab on Football home screen.
final footballFilterProvider =
    NotifierProvider<FootballFilterNotifier, FootballFilter>(
  FootballFilterNotifier.new,
);

class FootballFilterNotifier extends Notifier<FootballFilter> {
  @override
  // Open on upcoming fixtures so users always see the next games first.
  FootballFilter build() => FootballFilter.leagues;

  void setFilter(FootballFilter value) => state = value;
}

/// Search query for filtering leagues and clubs.
final footballSearchProvider =
    NotifierProvider<FootballSearchNotifier, String>(FootballSearchNotifier.new);

class FootballSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

/// Optional season override per competition (null = provider default / multi-year).
final footballSeasonProvider =
    NotifierProvider.family<FootballSeasonNotifier, String?, String>(
  FootballSeasonNotifier.new,
);

class FootballSeasonNotifier extends Notifier<String?> {
  FootballSeasonNotifier(this.leagueId);
  final String leagueId;

  @override
  String? build() => null;

  void setSeason(String? season) => state = season;
}

/// User's favorite competition IDs (stored in SharedPreferences).
final footballFavoritesProvider =
    NotifierProvider<FootballFavoritesNotifier, Set<String>>(
  FootballFavoritesNotifier.new,
);

class FootballFavoritesNotifier extends Notifier<Set<String>> {
  static const _prefKey = 'ethiocal_football_favorites';

  @override
  Set<String> build() {
    Future.microtask(_loadFavorites);
    return {'epl_eth', 'epl_eng'};
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKey);
      if (list != null && list.isNotEmpty) {
        state = list.toSet();
      }
    } catch (_) {}
  }

  Future<void> toggle(String id) async {
    final next = Set<String>.from(state);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, next.toList());
    } catch (_) {}
  }

  bool isFavorite(String id) => state.contains(id);
}

/// Soft refresh spinner state per league (keeps data visible while updating).
final footballLeagueRefreshingProvider =
    NotifierProvider.family<FootballRefreshingNotifier, bool, String>(
  FootballRefreshingNotifier.new,
);

class FootballRefreshingNotifier extends Notifier<bool> {
  FootballRefreshingNotifier(this.leagueId);
  final String leagueId;

  @override
  bool build() => false;

  void setRefreshing(bool value) => state = value;
}

/// Live league detail (fixtures + standings). Auto-refreshes while watched.
final footballLeagueProvider =
    AsyncNotifierProvider.family<FootballLeagueNotifier, FootballLeague, String>(
  FootballLeagueNotifier.new,
);

class FootballLeagueNotifier extends AsyncNotifier<FootballLeague> {
  FootballLeagueNotifier(this.leagueId);

  final String leagueId;
  VoidCallback? _tick;
  bool _refreshingBackground = false;

  @override
  Future<FootballLeague> build() async {
    final season = ref.watch(footballSeasonProvider(leagueId));
    final repo = ref.watch(footballRepositoryProvider);
    final manager = FootballRefreshManager.instance;

    _tick = () {
      unawaited(_backgroundRefresh());
    };
    manager.addListener(_tick!);
    ref.onDispose(() {
      if (_tick != null) manager.removeListener(_tick!);
      _tick = null;
    });

    // Instant disk/offline content, then sync from free APIs.
    // Skip generic cache when a specific season override is active.
    final cached = season == null ? await repo.peekCache(leagueId) : null;
    if (cached != null) {
      if (!FootballRefreshManager.disablePeriodicRefresh) {
        Future.microtask(() => _backgroundRefresh());
      }
      manager.setHasLiveMatches(
        manager.hasLiveMatches || cached.matches.any((m) => m.isLive),
      );
      return cached;
    }

    final league = await repo.getLeague(leagueId, season: season);
    manager.setHasLiveMatches(
      manager.hasLiveMatches || league.matches.any((m) => m.isLive),
    );
    return league;
  }

  Future<void> _backgroundRefresh() async {
    if (_refreshingBackground) return;
    if (!FootballRefreshManager.instance.isForeground) return;
    _refreshingBackground = true;
    try {
      final repo = ref.read(footballRepositoryProvider);
      final season = ref.read(footballSeasonProvider(leagueId));
      final previous = state.asData?.value;
      final fresh = await repo.refreshLeague(
        leagueId,
        previous: previous,
        season: season,
      );
      state = AsyncData(fresh);
      FootballRefreshManager.instance.setHasLiveMatches(
        FootballRefreshManager.instance.hasLiveMatches ||
            fresh.matches.any((m) => m.isLive),
      );
    } catch (_) {
      // Keep previous successful data on background refresh failure.
    } finally {
      _refreshingBackground = false;
    }
  }

  /// Active professional refresh — keeps previous data on screen while fetching.
  Future<bool> refresh() async {
    final refreshing = ref.read(footballLeagueRefreshingProvider(leagueId));
    if (refreshing) return false;

    ref.read(footballLeagueRefreshingProvider(leagueId).notifier).setRefreshing(true);
    try {
      final repo = ref.read(footballRepositoryProvider);
      final season = ref.read(footballSeasonProvider(leagueId));
      repo.api.clearLeagueCache(leagueId);
      final previous = state.asData?.value;
      final fresh = await repo.refreshLeague(
        leagueId,
        previous: previous,
        season: season,
      );
      state = AsyncData(fresh);
      return true;
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncError(e, st);
      }
      return false;
    } finally {
      ref
          .read(footballLeagueRefreshingProvider(leagueId).notifier)
          .setRefreshing(false);
    }
  }
}

/// Deep match details (events, lineups, statistics, h2h).
final footballMatchDetailProvider =
    FutureProvider.family<FootballMatch, FootballMatch>((ref, match) async {
  final repo = ref.watch(footballRepositoryProvider);
  return repo.getMatchDetails(match);
});

/// Live matches currently playing across supported ESPN competitions.
final footballLiveMatchesProvider =
    FutureProvider<List<FootballMatch>>((ref) async {
  final repo = ref.watch(footballRepositoryProvider);
  return repo.getLiveMatches();
});

/// Today's matches across supported competitions.
final footballTodayMatchesProvider =
    FutureProvider<List<FootballMatch>>((ref) async {
  final repo = ref.watch(footballRepositoryProvider);
  return repo.getTodayMatches();
});

/// Refresh every catalog league (home pull-to-refresh / hero button).
final footballGlobalRefreshProvider =
    NotifierProvider<FootballGlobalRefreshNotifier, bool>(
  FootballGlobalRefreshNotifier.new,
);

class FootballGlobalRefreshNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<int> refreshAll() async {
    if (state) return 0;
    state = true;
    var ok = 0;
    try {
      final repo = ref.read(footballRepositoryProvider);
      repo.clearMemoryCaches();
      final catalog = ref.read(footballCatalogProvider);
      for (final league in catalog) {
        try {
          await ref
              .read(footballLeagueProvider(league.id).notifier)
              .refresh();
          ok++;
        } catch (_) {}
      }
      ref.invalidate(footballLiveMatchesProvider);
      ref.invalidate(footballTodayMatchesProvider);
    } finally {
      state = false;
    }
    return ok;
  }
}
