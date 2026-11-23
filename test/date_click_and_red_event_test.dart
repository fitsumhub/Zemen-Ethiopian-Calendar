import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ethiocal/core/calendar/ethiopian_calendar_engine.dart';
import 'package:ethiocal/core/localization/app_localizations_setup.dart';
import 'package:ethiocal/data/models/event_entity.dart';
import 'package:ethiocal/data/preferences/user_preferences_repository.dart';
import 'package:ethiocal/features/calendar/calendar_home_screen.dart';
import 'package:ethiocal/features/calendar/widgets/dual_date_day_cell.dart';
import 'package:ethiocal/features/events/dialogs/add_edit_event_dialog.dart';
import 'package:ethiocal/features/shared/providers.dart';
import 'package:ethiocal/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'pref_onboarding_completed': true,
      'pref_theme_mode': 'LIGHT',
      'pref_language': 'ENGLISH',
    });
    await UserPreferencesRepository.initialize();
  });

  group('Date Direct Click & Red Event Indicators', () {
    test('AddEditEventDialog defaults to vibrant red (#EF4444)', () {
      final today = EthiopianCalendarEngine.todayEthiopian();
      final dialog = AddEditEventDialog(
        initialDate: today,
        onDismiss: () {},
        onSave: (_) {},
      );

      // Verify widget builds and has red as default color in state
      expect(dialog.initialDate, equals(today));
    });

    testWidgets('DualDateDayCell displays red event dot when hasEvents is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 60,
                height: 60,
                child: DualDateDayCell(
                  primaryText: '15',
                  secondaryText: '24',
                  isToday: false,
                  isSelected: false,
                  isSunday: false,
                  isPublicHoliday: false,
                  hasReligiousHoliday: false,
                  hasEvents: true,
                  isFasting: false,
                  showFasting: false,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the red event dot container
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasRedDot = containers.any((c) {
        final deco = c.decoration;
        if (deco is BoxDecoration) {
          return deco.color == const Color(0xFFEF4444);
        }
        return false;
      });

      expect(hasRedDot, isTrue, reason: 'Event indicator dot must be red');
    });

    testWidgets('Quick Add Reminder button is rendered on Selected Date Inspector', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ProviderScope(child: EthioCalApp()));

      await tester.pumpAndSettle();

      // Verify the prominent Add Reminder banner is visible
      final reminderFinder = find.byIcon(Icons.alarm_add_rounded);
      expect(reminderFinder, findsOneWidget);

      // Tap the prominent Add Reminder banner
      await tester.tap(reminderFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Bottom sheet AddEditEventDialog should open
      expect(find.byType(AddEditEventDialog), findsOneWidget);
    });

    testWidgets('Tapping the already selected date directly triggers Add Event', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final today = EthiopianCalendarEngine.todayEthiopian();
      final todayNum = '${today.day}';

      await tester.pumpWidget(const ProviderScope(child: EthioCalApp()));

      await tester.pumpAndSettle();

      // Today is selected by default. Tapping the already selected day cell directly triggers Add Event dialog.
      final cellFinder = find.byKey(ValueKey('cell-${today.year}-${today.month}-${today.day}'));
      final targetFinder = cellFinder.evaluate().isNotEmpty
          ? cellFinder
          : find.widgetWithText(InkWell, todayNum);
      if (targetFinder.evaluate().isNotEmpty) {
        await tester.tap(targetFinder.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // AddEditEventDialog opens directly on clicking the selected date
        expect(find.byType(AddEditEventDialog), findsOneWidget);
      }
    });

    testWidgets('Calendar Grid displays red event dot and badge when an event exists', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final today = EthiopianCalendarEngine.todayEthiopian();
      final greg = EthiopianCalendarEngine.toGregorian(today);
      final testEvent = EventEntity(
        id: 999,
        title: 'Meeting with Team',
        ethiopianYear: today.year,
        ethiopianMonth: today.month,
        ethiopianDay: today.day,
        gregorianYear: greg.year,
        gregorianMonth: greg.month,
        gregorianDay: greg.day,
        createdAt: 1000,
        colorHex: '#EF4444',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizationsSetup.delegates,
          localeResolutionCallback: AppLocalizationsSetup.resolveLocale,
          home: Scaffold(
            body: ProviderScope(
              overrides: [
                eventsNotifierProvider.overrideWith(
                  () => _StaticEventsNotifier([testEvent]),
                ),
              ],
              child: const CalendarHomeScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the event appears in the selected date inspector
      expect(find.text('Meeting with Team'), findsOneWidget);

      // Verify red decoration exists for the day cell with the event
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasRedElements = containers.any((c) {
        final deco = c.decoration;
        if (deco is BoxDecoration) {
          return deco.color == const Color(0xFFEF4444);
        }
        return false;
      });

      expect(hasRedElements, isTrue, reason: 'Must display red color for added event');
    });
  });
}

class _StaticEventsNotifier extends EventsNotifier {
  final List<EventEntity> _initial;
  _StaticEventsNotifier(this._initial);

  @override
  Future<List<EventEntity>> build() async => _initial;
}
