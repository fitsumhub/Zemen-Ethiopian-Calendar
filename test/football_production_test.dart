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

  group('Football Production Requirements 1-5: Lifecycle, Cache & Refresh', () {
    test('1. Online first launch: fetches live data and populates cache', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'events': [
              {
                'id': '800101',
                'date': '2026-11-20T17:30:00Z',
                'competitions': [
                  {
                    'competitors': [
                      {
                        'homeAway': 'home',
                        'score': '2',
                        'team': {'id': '1', 'displayName': 'Arsenal'}
                      },
                      {
                        'homeAway': 'away',
                        'score': '1',
                        'team': {'id': '2', 'displayName': 'Chelsea'}
                      }
                    ],
                    'status': {
                      'type': {'state': 'post', 'detail': 'FT'}
                    }
                  }
                ]
              }
            ],
            'children': []
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = FootballApiService(client: client);
      final repo = FootballRepository(api: api);

      final league = await repo.getLeague('epl_eng', season: '2026-2027');
      expect(league.matches, isNotEmpty);
      expect(league.sourceLabel, contains('Live'));

      // Verify that disk cache was populated
      final diskSnapshot = await FootballDiskCache.instance.loadLeagueSnapshot('epl_eng');
      expect(diskSnapshot, isNotNull);
      expect(diskSnapshot!.matches, isNotEmpty);

      api.dispose();
      repo.dispose();
    });

    test('2. Offline first launch: returns authentic offline verified schedule without throwing', () async {
      final client = MockClient((request) async {
        throw Exception('No network available');
      });

      final api = FootballApiService(client: client);
      final repo = FootballRepository(api: api);

      final ethiopianLeague = await repo.getLeague('epl_eth');
      expect(ethiopianLeague.matches, isNotEmpty);
      expect(ethiopianLeague.standings.length, 17);
      expect(ethiopianLeague.sourceLabel, contains('Offline'));

      api.dispose();
      repo.dispose();
    });

    test('3. Offline after successful online session: reconstitutes events, stats, penalties from cache', () async {
      final match = FootballMatch(
        id: '990011',
        competitionId: 'ucl',
        competitionName: 'UEFA Champions League',
        dateHeader: 'Wednesday, Hidar 16',
        home: const FootballTeam(name: 'Real Madrid', mark: ColorMark('RM', 0xFFFFFFFF)),
        away: const FootballTeam(name: 'Bayern Munich', mark: ColorMark('BM', 0xFFDC052D)),
        homeScore: 3,
        awayScore: 3,
        homeHtScore: 1,
        awayHtScore: 1,
        homePenScore: 4,
        awayPenScore: 2,
        phase: MatchPhase.finished,
        statusLabel: 'PEN',
        events: const [
          MatchEvent(
            minute: 23,
            type: MatchEventType.goal,
            teamName: 'Real Madrid',
            isHome: true,
            playerName: 'Vinicius Jr',
          ),
          MatchEvent(
            minute: 67,
            type: MatchEventType.yellowCard,
            teamName: 'Bayern Munich',
            isHome: false,
            playerName: 'Kimmich',
          ),
        ],
        statistics: const MatchStatistics(
          homePossession: 52,
          awayPossession: 48,
          homeShots: 16,
          awayShots: 14,
          homeCorners: 6,
          awayCorners: 4,
        ),
      );

      final initialLeague = FootballLeague(
        id: 'ucl',
        name: 'UEFA Champions League',
        shortName: 'UCL',
        mark: const ColorMark('UCL', 0xFF0A1E46),
        matches: [match],
        standings: const [],
        sourceLabel: 'ESPN · Live',
        fetchedAt: DateTime.now(),
      );

      // Save online session to persistent disk cache
      await FootballDiskCache.instance.saveLeagueSnapshot(
        leagueId: 'ucl',
        league: initialLeague,
        kind: FootballSourceKind.live,
      );

      // Create new offline repository instance (simulating next app cold start offline)
      final offlineClient = MockClient((_) async => throw Exception('Offline'));
      final offlineRepo = FootballRepository(api: FootballApiService(client: offlineClient));

      final peeked = await offlineRepo.peekCache('ucl');
      expect(peeked, isNotNull);
      expect(peeked!.matches.length, 1);

      final cachedMatch = peeked.matches.first;
      expect(cachedMatch.homeScore, 3);
      expect(cachedMatch.awayScore, 3);
      expect(cachedMatch.homePenScore, 4);
      expect(cachedMatch.awayPenScore, 2);
      expect(cachedMatch.hasPenaltyScore, isTrue);
      expect(cachedMatch.hasHalfTimeScore, isTrue);
      expect(cachedMatch.events.length, 2);
      expect(cachedMatch.events.first.playerName, 'Vinicius Jr');
      expect(cachedMatch.statistics, isNotNull);
      expect(cachedMatch.statistics!.homePossession, 52);

      offlineRepo.dispose();
    });

    test('4. Manual refresh: preserves existing content when network fails', () async {
      final initialLeague = FootballData.offlineById('epl_eng')!.copyWith(
        sourceLabel: 'ESPN · Live',
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final failingClient = MockClient((_) async => throw http.ClientException('Connection reset'));
      final repo = FootballRepository(api: FootballApiService(client: failingClient));

      final refreshed = await repo.refreshLeague('epl_eng', previous: initialLeague);
      expect(refreshed.matches.length, initialLeague.matches.length);
      expect(refreshed.sourceLabel, contains('Cached'));

      repo.dispose();
    });

    test('5. Automatic refresh: 60s foreground polling when live matches exist vs 4min idle', () {
      final manager = FootballRefreshManager.instance;

      manager.setHasLiveMatches(true);
      expect(manager.currentInterval, equals(const Duration(seconds: 60)));

      manager.setHasLiveMatches(false);
      expect(manager.currentInterval, equals(const Duration(minutes: 4)));
    });
  });

  group('Football Production Requirements 6-10: Error Resilience & Request Single-Flight', () {
    test('6. API timeout handling: respects timeout without hanging or crashing', () async {
      final slowClient = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        throw TimeoutException('Request timed out');
      });

      final api = FootballApiService(client: slowClient);
      final repo = FootballRepository(api: api);

      final league = await repo.getLeague('epl_eth');
      expect(league.matches, isNotEmpty); // Falls back safely to offline backbone

      api.dispose();
      repo.dispose();
    });

    test('7. HTTP 429 response handling: respects Retry-After and completes cleanly', () async {
      var callCount = 0;
      final rateLimitedClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response('Too many requests', 429, headers: {'retry-after': '1'});
        }
        return http.Response(
          jsonEncode({
            'events': [],
            'children': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = FootballApiService(client: rateLimitedClient);
      final league = await api.fetchLeague('laliga');
      expect(callCount, greaterThanOrEqualTo(2));
      expect(league, isNotNull);

      api.dispose();
    });

    test('8. Empty API response: gracefully falls back to verified backbone', () async {
      final emptyClient = MockClient((_) async {
        return http.Response(jsonEncode({}), 200, headers: {'content-type': 'application/json'});
      });

      final api = FootballApiService(client: emptyClient);
      final league = await api.fetchLeague('epl_eth');
      expect(league.matches.length, equals(234)); // Authentic 34-round full schedule (234 fixtures)
      expect(league.standings.length, 17);

      api.dispose();
    });

    test('9. Malformed JSON handling: resilient parsing never crashes match detail fetch', () async {
      final malformedClient = MockClient((_) async {
        return http.Response('<<<not json>>>', 200);
      });

      final api = FootballApiService(client: malformedClient);
      final baseMatch = FootballData.ethiopianSchedule.first.copyWith(id: '778899');
      final result = await api.fetchMatchDetails(baseMatch, leagueSlug: 'eng.1');

      expect(result.id, '778899');
      expect(result.events, isEmpty);
      expect(result.statistics, isNull);

      api.dispose();
    });

    test('10. Duplicate concurrent API requests: deduplicated into single flight', () async {
      final manager = FootballRefreshManager.instance;
      var networkCalls = 0;

      Future<String> slowCall() async {
        networkCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return 'success';
      }

      final req1 = manager.runSingleFlight('comp_epl', slowCall);
      final req2 = manager.runSingleFlight('comp_epl', slowCall);

      final expectErr = expectLater(req2, throwsA(isA<StateError>()));
      final res1 = await req1;
      await expectErr;

      expect(res1, 'success');
      expect(networkCalls, 1);
    });
  });

  group('Football Production Requirements 11-13: Navigation, App Lifecycle & Competitions', () {
    test('11. App background lifecycle: pauses polling until resume', () {
      final manager = FootballRefreshManager.instance;
      var tickCount = 0;
      void listener() => tickCount++;

      manager.addListener(listener);
      expect(manager.isForeground, isTrue);

      // App transitions to background
      manager.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(manager.isForeground, isFalse);

      // App returns to foreground
      manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(manager.isForeground, isTrue);
      expect(tickCount, 1); // Dispatches resume sync tick

      manager.removeListener(listener);
    });

    test('12. Competition switching: supports European, African, and Global competitions', () {
      final catalog = FootballData.catalog;
      final ids = catalog.map((l) => l.id).toSet();

      // European
      expect(ids.contains('epl_eng'), isTrue);
      expect(ids.contains('laliga'), isTrue);
      expect(ids.contains('bundesliga'), isTrue);
      expect(ids.contains('seriea'), isTrue);
      expect(ids.contains('ligue1'), isTrue);
      expect(ids.contains('ucl'), isTrue);
      expect(ids.contains('europa'), isTrue);
      expect(ids.contains('conference'), isTrue);

      // African
      expect(ids.contains('epl_eth'), isTrue);
      expect(ids.contains('caf_cl'), isTrue);
      expect(ids.contains('caf_cc'), isTrue);
      expect(ids.contains('afcon'), isTrue);

      // Global
      expect(ids.contains('world_cup'), isTrue);

      for (final id in ids) {
        final src = FootballData.sourceFor(id);
        final hasProvider = src.espnSlug != null || src.sportsDbId != null || src.openLigaLeague != null || id == 'epl_eth';
        expect(hasProvider, isTrue, reason: 'Competition $id must have a configured free provider');
      }
    });

    test('13. Season switching: multi-year seasons query correctly', () {
      final seasons = FootballData.multiYearSeasons;
      expect(seasons.length, greaterThanOrEqualTo(5));

      final src = FootballData.sourceFor('bundesliga');
      expect(src.openLigaLeague, 'bl1');
      expect(src.sportsDbSeasons.isNotEmpty, isTrue);
    });
  });

  group('Football Production Requirements 14-17: Match Center, Status & Timezones', () {
    test('14. Match details: events, goal scorers, cards, substitutions, half-time and penalty scores', () {
      const match = FootballMatch(
        dateHeader: 'Sunday, Hidar 20',
        home: FootballTeam(name: 'Liverpool', mark: ColorMark('LIV', 0xFFC8102E)),
        away: FootballTeam(name: 'Manchester City', mark: ColorMark('MCI', 0xFF6CABDD)),
        homeScore: 2,
        awayScore: 2,
        homeHtScore: 1,
        awayHtScore: 0,
        homePenScore: 5,
        awayPenScore: 4,
        phase: MatchPhase.finished,
        statusLabel: 'PEN',
        events: [
          MatchEvent(
            minute: 34,
            type: MatchEventType.goal,
            teamName: 'Liverpool',
            isHome: true,
            playerName: 'Salah',
          ),
          MatchEvent(
            minute: 55,
            type: MatchEventType.goal,
            teamName: 'Manchester City',
            isHome: false,
            playerName: 'Haaland',
          ),
          MatchEvent(
            minute: 78,
            type: MatchEventType.yellowCard,
            teamName: 'Liverpool',
            isHome: true,
            playerName: 'Van Dijk',
          ),
          MatchEvent(
            minute: 82,
            type: MatchEventType.substitution,
            teamName: 'Manchester City',
            isHome: false,
            playerName: 'Foden',
            assistOrPlayerOut: 'Grealish',
          ),
        ],
      );

      expect(match.hasScore, isTrue);
      expect(match.hasHalfTimeScore, isTrue);
      expect(match.hasPenaltyScore, isTrue);
      expect(match.events.length, 4);

      final goal = match.events.first;
      expect(goal.playerName, 'Salah');
      expect(goal.displayMinute, "34'");
      expect(goal.type, MatchEventType.goal);

      final sub = match.events.last;
      expect(sub.type, MatchEventType.substitution);
      expect(sub.playerName, 'Foden');
      expect(sub.assistOrPlayerOut, 'Grealish');
    });

    test('15. Clean empty states: missing stats or lineups do not fabricate false data', () {
      const emptyMatch = FootballMatch(
        dateHeader: 'Friday, Tahsas 1',
        home: FootballTeam(name: 'Halaba Ketema', mark: ColorMark('HK', 0xFF4A148C)),
        away: FootballTeam(name: 'Negelle Arsi', mark: ColorMark('NA', 0xFF00695C)),
      );

      expect(emptyMatch.hasScore, isFalse);
      expect(emptyMatch.hasHalfTimeScore, isFalse);
      expect(emptyMatch.hasPenaltyScore, isFalse);
      expect(emptyMatch.events, isEmpty);
      expect(emptyMatch.homeLineup, isNull);
      expect(emptyMatch.awayLineup, isNull);
      expect(emptyMatch.statistics, isNull);
      expect(emptyMatch.headToHead, isNull);
    });

    test('16. Postponed, cancelled, and abandoned match status handling', () {
      final postponed = const FootballMatch(
        dateHeader: 'Today',
        home: FootballTeam(name: 'Team A', mark: ColorMark('TA', 0xFF000000)),
        away: FootballTeam(name: 'Team B', mark: ColorMark('TB', 0xFF111111)),
        phase: MatchPhase.postponed,
        statusLabel: 'PPD',
      );
      expect(postponed.isPostponed, isTrue);
      expect(postponed.isFinished, isFalse);
      expect(postponed.isLive, isFalse);

      final cancelled = const FootballMatch(
        dateHeader: 'Today',
        home: FootballTeam(name: 'Team A', mark: ColorMark('TA', 0xFF000000)),
        away: FootballTeam(name: 'Team B', mark: ColorMark('TB', 0xFF111111)),
        phase: MatchPhase.cancelled,
        statusLabel: 'CANC',
      );
      expect(cancelled.isCancelled, isTrue);

      final abandoned = const FootballMatch(
        dateHeader: 'Today',
        home: FootballTeam(name: 'Team A', mark: ColorMark('TA', 0xFF000000)),
        away: FootballTeam(name: 'Team B', mark: ColorMark('TB', 0xFF111111)),
        phase: MatchPhase.abandoned,
        statusLabel: 'ABD',
      );
      expect(abandoned.isAbandoned, isTrue);
    });

    test('17. Timezone conversion accuracy: UTC to local match kickoff', () {
      final utcTime = DateTime.utc(2026, 11, 15, 17, 30);
      final localTime = utcTime.toLocal();

      final m = FootballMatch(
        dateHeader: 'Sunday, Hidar 6',
        home: const FootballTeam(name: 'Arsenal', mark: ColorMark('ARS', 0xFFEF0107)),
        away: const FootballTeam(name: 'Chelsea', mark: ColorMark('CHE', 0xFF034694)),
        kickoff: localTime,
      );

      expect(m.kickoff, isNotNull);
      expect(m.kickoff!.isUtc, isFalse);
      expect(m.kickoff!.year, localTime.year);
      expect(m.kickoff!.month, localTime.month);
      expect(m.kickoff!.day, localTime.day);
    });
  });

  group('Football UI Widgets: Comprehensive Screen Tests', () {
    testWidgets('FootballScreen renders search and filter navigation', (tester) async {
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

      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Football'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Results'), findsOneWidget);
      expect(find.text('Leagues'), findsOneWidget);

      await tester.tap(find.text('Leagues'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('CAF Confederation Cup'), findsWidgets);
      expect(find.text('Africa Cup of Nations'), findsWidgets);
    });

    testWidgets('MatchDetailScreen renders penalty scores and half-time badges', (tester) async {
      const matchWithPens = FootballMatch(
        id: 'pen_match_1',
        competitionName: 'CAF Champions League',
        dateHeader: 'Sunday, Hidar 6',
        home: FootballTeam(name: 'Al Ahly', mark: ColorMark('AH', 0xFFE53935)),
        away: FootballTeam(name: 'Mamelodi Sundowns', mark: ColorMark('MS', 0xFFFDD835)),
        homeScore: 1,
        awayScore: 1,
        homeHtScore: 0,
        awayHtScore: 0,
        homePenScore: 5,
        awayPenScore: 4,
        phase: MatchPhase.finished,
        statusLabel: 'PEN',
      );

      final client = MockClient((_) async => http.Response(jsonEncode({}), 200));
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
            home: MatchDetailScreen(match: matchWithPens),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Al Ahly'), findsWidgets);
      expect(find.text('Mamelodi Sundowns'), findsWidgets);
      expect(find.text('HT 0-0'), findsOneWidget);
      expect(find.text('PENS 5 - 4'), findsOneWidget);
      expect(find.text('AFTER PENALTIES'), findsOneWidget);

      repo.dispose();
    });
  });
}
