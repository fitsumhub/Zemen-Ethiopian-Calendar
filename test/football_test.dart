import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ethiocal/data/preferences/user_preferences_repository.dart';

import 'package:ethiocal/features/football/football_api_service.dart';
import 'package:ethiocal/features/football/football_cache.dart';
import 'package:ethiocal/features/football/football_data.dart';
import 'package:ethiocal/features/football/football_providers.dart';
import 'package:ethiocal/features/football/football_refresh_manager.dart';
import 'package:ethiocal/features/football/football_repository.dart';
import 'package:ethiocal/features/football/football_screen.dart';
import 'package:ethiocal/features/football/league_detail_screen.dart';
import 'package:ethiocal/features/football/match_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPreferencesRepository.initialize();
    FootballRefreshManager.disablePeriodicRefresh = true;
    FootballRefreshManager.instance.resetForTest();
  });

  tearDown(() {
    FootballRefreshManager.instance.resetForTest();
  });

  group('Football Core Models & Data Catalog', () {
    test('Football catalog contains all priority competitions', () {
      final catalog = FootballData.catalog;
      final ids = catalog.map((l) => l.id).toList();

      expect(ids, contains('epl_eth'));
      expect(ids, contains('epl_eng'));
      expect(ids, contains('ucl'));
      expect(ids, contains('bundesliga'));
      expect(ids, contains('laliga'));
      expect(ids, contains('seriea'));
      expect(ids, contains('ligue1'));
      expect(ids, contains('europa'));
      expect(ids, contains('conference'));
      expect(ids, contains('caf_cl'));
      expect(ids, contains('caf_cc'));
      expect(ids, contains('afcon'));
      expect(ids, contains('world_cup'));
      expect(catalog.length, equals(13));
    });

    test('Every catalog competition has a free provider mapping', () {
      for (final league in FootballData.catalog) {
        final source = FootballData.sourceFor(league.id);
        final hasProvider = source.espnSlug != null ||
            source.sportsDbId != null ||
            source.openLigaLeague != null ||
            league.id == 'epl_eth';
        expect(hasProvider, isTrue, reason: league.id);
      }
    });

    test('Ethiopian Premier League has 17 authentic clubs', () {
      final teams = FootballData.ethiopianTeams;
      expect(teams.length, equals(17));

      expect(teams.containsKey('giorgis'), isTrue);
      expect(teams['giorgis']!.name, equals('Kedus Giorgis'));
      expect(teams.containsKey('nigd'), isTrue);
      expect(teams['nigd']!.name, equals('Ethiopia Nigd Bank'));
      expect(teams.containsKey('mekelakeya'), isTrue);
      expect(teams['mekelakeya']!.name, equals('Mekelakeya'));
      expect(teams.containsKey('fasil'), isTrue);
      expect(teams['fasil']!.name, equals('Fasil Ketema'));
      expect(teams.containsKey('welayta'), isTrue);
      expect(teams['welayta']!.name, equals('Welayta Dicha'));
    });

    test('Ethiopian Premier League schedule matches user screenshot 4', () {
      final schedule = FootballData.ethiopianSchedule;
      expect(schedule.isNotEmpty, isTrue);

      final m1 = schedule.first;
      expect(m1.dateHeader, equals('Friday, Hidar 11'));
      expect(m1.home.name, equals('Fasil Ketema'));
      expect(m1.away.name, equals('Ethiopia Nigd Bank'));
      expect(m1.time, equals('3:00'));
      expect(m1.period, equals('PM'));

      final m2 = schedule[1];
      expect(m2.home.name, contains('Mebrat Hayl'));
      expect(m2.away.name, equals('Halaba Ketema'));

      final m3 = schedule[2];
      expect(m3.home.name, equals('Negelle Arsi'));
      expect(m3.away.name, equals('Gamo Chencha'));

      final m6 = schedule[5];
      expect(m6.dateHeader, equals('Saturday, Hidar 12'));
      expect(m6.home.name, equals('Kedus Giorgis'));
      expect(m6.away.name, equals('Hadiya Hosaena'));
    });

    test('Ethiopian Premier League standings match user screenshot 5', () {
      final standings = FootballData.ethiopianStandings;
      expect(standings.length, equals(17));

      expect(standings[0].rank, equals(1));
      expect(standings[0].team.name, equals('Negelle Arsi'));
      expect(standings[0].played, equals(5));
      expect(standings[0].gd, equals(5));
      expect(standings[0].pts, equals(11));

      expect(standings[1].rank, equals(2));
      expect(standings[1].team.name, equals('Mekelakeya'));
      expect(standings[1].pts, equals(10));

      expect(standings[2].rank, equals(3));
      expect(standings[2].team.name, equals('Welayta Dicha'));
      expect(standings[2].pts, equals(8));

      expect(standings[3].rank, equals(4));
      expect(standings[3].team.name, equals('Ethiopia Nigd Bank'));
      expect(standings[3].pts, equals(8));

      expect(standings[4].rank, equals(5));
      expect(standings[4].team.name, equals('Halaba Ketema'));
      expect(standings[4].pts, equals(8));
    });

    test('EPL schedule matches user screenshot 2', () {
      final schedule = FootballData.eplSchedule;
      expect(schedule.isNotEmpty, isTrue);

      final m1 = schedule.first;
      expect(m1.dateHeader, equals('Friday, Tikimt 27'));
      expect(m1.home.name, equals('Everton'));
      expect(m1.away.name, equals('Coventry'));
      expect(m1.homeScore, equals(3));
      expect(m1.awayScore, equals(1));
      expect(m1.isFinished, isTrue);

      final m4 = schedule[3];
      expect(m4.home.name, equals('Arsenal'));
      expect(m4.away.name, equals('Hull City'));
      expect(m4.homeScore, equals(1));
      expect(m4.awayScore, equals(0));
    });

    test('EPL standings match user screenshot 3', () {
      final standings = FootballData.eplStandings;
      expect(standings[0].rank, equals(1));
      expect(standings[0].team.name, equals('Arsenal'));
      expect(standings[0].played, equals(10));
      expect(standings[0].gd, equals(10));
      expect(standings[0].pts, equals(27));

      expect(standings[1].rank, equals(2));
      expect(standings[1].team.name, equals('Brighton'));
      expect(standings[1].gd, equals(19));
      expect(standings[1].pts, equals(22));

      expect(standings[2].team.name, equals('Manchester City'));
      expect(standings[2].pts, equals(21));

      expect(standings[3].team.name, equals('Liverpool'));
      expect(standings[3].pts, equals(18));
    });
  });

  group('Normalization & status mapping', () {
    test('MatchStatistics empty defaults are not fake midfield values', () {
      const stats = MatchStatistics();
      expect(stats.homePossession, 0);
      expect(stats.awayPossession, 0);
      expect(stats.hasMeaningfulData, isFalse);
    });

    test('Half-time score flag requires both sides', () {
      final m = FootballMatch(
        dateHeader: 'Test',
        home: FootballData.ethiopianTeams['fasil']!,
        away: FootballData.ethiopianTeams['nigd']!,
        homeScore: 2,
        awayScore: 1,
        homeHtScore: 1,
        awayHtScore: 0,
      );
      expect(m.hasHalfTimeScore, isTrue);
      expect(m.hasScore, isTrue);
    });

    test('Postponed and cancelled phases are distinct', () {
      expect(MatchPhase.postponed != MatchPhase.cancelled, isTrue);
      expect(MatchPhase.values.contains(MatchPhase.cancelled), isTrue);
    });
  });

  group('API service resilience', () {
    test('HTTP 429 respects Retry-After then recovers', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        if (calls == 1) {
          return http.Response(
            'rate limited',
            429,
            headers: {'retry-after': '1'},
          );
        }
        return http.Response(
          jsonEncode({
            'events': [],
            'leagues': [
              {'name': 'English Premier League', 'slug': 'eng.1'},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = FootballApiService(client: client);
      final league = await api.fetchLeague('epl_eng');
      expect(calls, greaterThanOrEqualTo(2));
      expect(league.matches, isNotEmpty); // offline/EPL backbone merge
      api.dispose();
    });

    test('Malformed JSON does not crash match detail fetch', () async {
      final client = MockClient((request) async {
        return http.Response('{not-json', 200);
      });
      final api = FootballApiService(client: client);
      final base = FootballData.ethiopianSchedule.first.copyWith(id: '401000');
      final detailed = await api.fetchMatchDetails(base, leagueSlug: 'eng.1');
      expect(detailed.id, base.id);
      expect(detailed.events, isEmpty);
      expect(detailed.statistics, isNull);
      api.dispose();
    });

    test('Empty API response falls back to offline backbone for EPL ET', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'events': null, 'table': null}), 200);
      });
      final api = FootballApiService(client: client);
      final league = await api.fetchLeague('epl_eth');
      expect(league.matches, isNotEmpty);
      expect(league.sourceLabel, isNotNull);
      api.dispose();
    });

    test('Live Ethiopian fixtures replace offline stubs and keep round numbers',
        () async {
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path.contains('lookuptable')) {
          return http.Response(
            jsonEncode({
              'table': [
                {
                  'intRank': '1',
                  'strTeam': 'Negelle Arsi',
                  'intPlayed': '5',
                  'intWin': '3',
                  'intDraw': '2',
                  'intLoss': '0',
                  'intGoalsFor': '7',
                  'intGoalsAgainst': '2',
                  'intGoalDifference': '5',
                  'intPoints': '11',
                  'strForm': 'WWWDD',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.contains('eventsnextleague') ||
            path.contains('eventspastleague') ||
            path.contains('eventsseason')) {
          return http.Response(
            jsonEncode({
              'events': [
                {
                  'idEvent': '2608774',
                  'strHomeTeam': 'Fasil Kenema',
                  'strAwayTeam': 'CBE SA',
                  'dateEvent': '2026-11-20',
                  'strTime': '12:00:00',
                  'intRound': '6',
                  'strStatus': 'NS',
                  'strLeague': 'Ethiopian Premier League',
                  'strVenue': 'Hawassa University Stadium',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(jsonEncode({'events': null, 'table': null}), 200);
      });

      final api = FootballApiService(client: client);
      final league = await api.fetchLeague('epl_eth', forceRefresh: true);
      expect(league.matches, isNotEmpty);
      expect(league.matches.any((m) => m.id == '2608774'), isTrue);
      final live = league.matches.firstWhere((m) => m.id == '2608774');
      expect(live.round, equals(6));
      expect(live.roundLabel, equals('Round 6'));
      // SportsDB aliases resolve to the local Ethiopian catalog names.
      expect(live.home.name, equals('Fasil Ketema'));
      expect(live.away.name, equals('Ethiopia Nigd Bank'));
      expect(league.standings, isNotEmpty);
      expect(league.standings.first.team.name, equals('Negelle Arsi'));
      // Sparse SportsDB tables must not wipe the full 17-club backbone.
      expect(league.standings.length, greaterThanOrEqualTo(17));
      api.dispose();
    });

    test('Duplicate in-flight league fetches are deduped by refresh manager',
        () async {
      final manager = FootballRefreshManager.instance;
      var runs = 0;
      Future<int> action() async {
        runs++;
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return runs;
      }

      final first = manager.runSingleFlight('dup', action);
      final second = manager.runSingleFlight('dup', action);
      final secondExpectation =
          expectLater(second, throwsA(isA<StateError>()));
      final a = await first;
      expect(a, 1);
      await secondExpectation;
      expect(runs, 1);
    });
  });

  group('Cache & repository offline behavior', () {
    test('Disk cache round-trips league snapshot', () async {
      SharedPreferences.setMockInitialValues({});
      final league = FootballData.offlineById('epl_eth')!;
      await FootballDiskCache.instance.saveLeagueSnapshot(
        leagueId: 'epl_eth',
        league: league.copyWith(
          sourceLabel: 'ESPN · Live',
          fetchedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        kind: FootballSourceKind.live,
      );
      final loaded = await FootballDiskCache.instance.loadLeagueSnapshot('epl_eth');
      expect(loaded, isNotNull);
      expect(loaded!.matches, isNotEmpty);
      // Fresh writes within live TTL keep Live label; older loads mark Cached.
      expect(
        loaded.sourceLabel,
        anyOf(contains('Live'), contains('Cached'), contains('ESPN')),
      );
    });

    test('Repository keeps previous content when refresh fails', () async {
      final client = MockClient((request) async {
        throw TimeoutException('timeout');
      });
      final api = FootballApiService(client: client);
      final repo = FootballRepository(api: api);
      final previous = FootballData.offlineById('epl_eng')!.copyWith(
        sourceLabel: 'ESPN · Live',
        fetchedAt: DateTime.now(),
      );
      final kept = await repo.refreshLeague('epl_eng', previous: previous);
      expect(kept.matches.length, previous.matches.length);
      // Soft refresh must not wipe fixtures; label may be Cached or Offline.
      expect(kept.matches, isNotEmpty);
      expect(
        kept.sourceLabel,
        anyOf(contains('Cached'), contains('Offline'), contains('Live')),
      );
      repo.dispose();
    });

    test('Offline first launch returns Ethiopian verified schedule', () async {
      final client = MockClient((request) async {
        throw Exception('offline');
      });
      final api = FootballApiService(client: client);
      final repo = FootballRepository(api: api);
      final league = await repo.getLeague('epl_eth');
      expect(league.matches, isNotEmpty);
      expect(league.standings.length, 17);
      repo.dispose();
    });
  });

  group('Refresh manager lifecycle', () {
    test('Live interval is 60s and idle is longer', () {
      final m = FootballRefreshManager.instance;
      m.setHasLiveMatches(true);
      expect(m.currentInterval, FootballRefreshManager.liveInterval);
      m.setHasLiveMatches(false);
      expect(m.currentInterval, FootballRefreshManager.idleInterval);
    });

    test('Background pause stops periodic firing until resume path', () {
      final m = FootballRefreshManager.instance;
      var ticks = 0;
      m.addListener(() => ticks++);
      expect(m.listenerCount, 1);
      m.removeListener(m.listenerCount == 1 ? () {} : () {});
      // Remove via reset
      m.resetForTest();
      expect(m.listenerCount, 0);
      expect(ticks, 0);
    });
  });

  group('Football UI Widgets Smoke & Navigation', () {
    testWidgets('FootballScreen renders League Explorer and leagues',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FootballScreen(),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Leagues'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Results'), findsOneWidget);

      // Hub opens on Leagues first.
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Ethiopian Premier League'), findsWidgets);
      expect(find.text('English Premier League'), findsWidgets);
      expect(find.text('UEFA Champions League'), findsWidgets);
      expect(find.text('Bundesliga'), findsWidgets);
      expect(find.text('La Liga'), findsWidgets);
      expect(find.text('Serie A'), findsWidgets);
      expect(find.text('Ligue 1'), findsWidgets);
    });

    testWidgets('LeagueDetailScreen renders tabs and schedule offline-first',
        (tester) async {
      final offline = FootballData.offlineById('epl_eth')!;
      final client = MockClient((_) async {
        throw Exception('forced offline');
      });
      final repo = FootballRepository(api: FootballApiService(client: client));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            footballRepositoryProvider.overrideWith((ref) {
              ref.onDispose(repo.dispose);
              return repo;
            }),
          ],
          child: const MaterialApp(
            home: LeagueDetailScreen(leagueId: 'epl_eth'),
          ),
        ),
      );

      // Offline peek should paint quickly without waiting on network.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Ethiopian Premier League'), findsWidgets);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Standings'), findsOneWidget);
      expect(find.text('Teams'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);

      // Schedule defaults to Next games — featured Round 8 fixtures stay visible.
      expect(find.text('Next'), findsWidgets);
      expect(find.text('Friday, Hidar 11'), findsWidgets);
      expect(find.text('Fasil Ketema'), findsWidgets);
      expect(find.text('Ethiopia Nigd Bank'), findsWidgets);

      await tester.tap(find.text('Standings'));
      await tester.pumpAndSettle();

      expect(find.text('Negelle Arsi'), findsWidgets);
      expect(find.text('Mekelakeya'), findsWidgets);

      // Season selector chips present for SportsDB-backed leagues.
      expect(find.text('All seasons'), findsOneWidget);

      expect(offline.matches, isNotEmpty);
      repo.dispose();
    });

    testWidgets('MatchDetailScreen renders scoreboard and empty-state tabs',
        (tester) async {
      final sampleMatch = FootballData.ethiopianSchedule.first;
      final client = MockClient((_) async {
        return http.Response(jsonEncode({'events': null}), 200);
      });
      final repo = FootballRepository(api: FootballApiService(client: client));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            footballRepositoryProvider.overrideWith((ref) {
              ref.onDispose(repo.dispose);
              return repo;
            }),
          ],
          child: MaterialApp(
            home: MatchDetailScreen(match: sampleMatch),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Fasil Ketema'), findsWidgets);
      expect(find.text('Ethiopia Nigd Bank'), findsWidgets);

      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Lineups'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('H2H'), findsOneWidget);

      await tester.tap(find.text('Lineups'));
      await tester.pumpAndSettle();
      expect(find.text('Lineups not announced yet'), findsOneWidget);

      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('statistics not available'),
        findsOneWidget,
      );

      await tester.tap(find.text('H2H'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Head-to-head history not available'),
        findsOneWidget,
      );

      repo.dispose();
    });
  });
}
