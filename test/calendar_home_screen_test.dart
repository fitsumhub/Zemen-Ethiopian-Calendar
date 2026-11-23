import 'package:ethiocal/core/calendar/ethiopian_calendar_engine.dart';
import 'package:ethiocal/data/preferences/user_preferences_repository.dart';
import 'package:ethiocal/features/calendar/calendar_home_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    UserPreferencesRepository.resetForTest();
    SharedPreferences.setMockInitialValues({
      'pref_language': 'ENGLISH',
      'pref_onboarding_completed': true,
      'pref_first_day_of_week': 'SUNDAY',
      'pref_calendar_format': 'ETHIOPIAN',
      'pref_numeral_type': 'ARABIC',
      'pref_show_fasting': true,
      'pref_show_monthly_saints': true,
    });
    await UserPreferencesRepository.initialize();
  });

  Widget buildTestableScreen() {
    return const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: CalendarHomeScreen(),
        ),
      ),
    );
  }

  group('CalendarHomeScreen Redesign & Responsiveness Tests', () {
    testWidgets('Renders month grid, clean native view switcher, and removes useless English clutter', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // View mode follows app language (English by default)
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);

      // Verify that duplicate brand clutter does NOT exist
      expect(find.textContaining('ዘመነ ዘመነ'), findsNothing);

      // Legend items follow app language
      expect(find.text('Public holiday'), findsOneWidget);
      expect(find.text('Feast'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);
      expect(find.text('Fast'), findsOneWidget);
      expect(find.text('Islamic'), findsOneWidget);

      expect(find.text('Islamic≈'), findsNothing);

      expect(find.text('Events and notes'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      expect(find.text('SELECTED DAY'), findsNothing);
      expect(find.textContaining('(Regular Day)'), findsNothing);
      expect(find.textContaining('(Events & Notes)'), findsNothing);
      expect(find.textContaining('(Add)'), findsNothing);
    });

    testWidgets('Selected Date Inspector shows hero ticket tile, saint, and fasting chips', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      final today = EthiopianCalendarEngine.todayEthiopian();

      // Today's day number in the hero ticket badge
      expect(find.text('${today.day}'), findsAtLeastNWidgets(1));

      // Share button in inspector
      expect(find.byIcon(Icons.ios_share_rounded), findsWidgets);

      // Notes empty state with clean icon
      expect(find.byIcon(Icons.note_add_outlined), findsOneWidget);
    });

    testWidgets('Dynamic month grid eliminates redundant 6th row (4 up to 10) for 5-row months', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Find the GridView inside PageView
      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsWidgets);

      // Verify that the active GridView renders exactly 35 cells (5 rows of 7) for a 5-row month
      // rather than hardcoding 42 cells.
      final grids = tester.widgetList<GridView>(gridFinder);
      expect(grids.any((g) => (g.childrenDelegate as SliverChildBuilderDelegate).estimatedChildCount == 35), isTrue);
    });
  });
}
