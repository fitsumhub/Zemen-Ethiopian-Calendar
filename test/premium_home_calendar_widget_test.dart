import 'package:ethiocal/core/calendar/ethiopian_calendar_engine.dart';
import 'package:ethiocal/core/calendar/ethiopian_date.dart';
import 'package:ethiocal/core/calendar/geez_numeral.dart';
import 'package:ethiocal/core/widgets/home_widget_engine.dart';
import 'package:ethiocal/data/preferences/user_preferences_repository.dart';
import 'package:ethiocal/features/home/widgets/premium_home_calendar_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'pref_onboarding_completed': true,
      'pref_first_day_of_week': 'SUNDAY',
      'pref_calendar_format': 'ETHIOPIAN',
      'pref_numeral_type': 'ARABIC',
      'pref_show_fasting': true,
      'pref_show_monthly_saints': true,
    });
    await UserPreferencesRepository.initialize();
  });

  Widget buildTestableWidget({
    VoidCallback? onAddEvent,
    ValueChanged<EthiopianDate>? onDateSelected,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PremiumHomeCalendarWidget(
              onAddEvent: onAddEvent,
              onDateSelected: onDateSelected,
            ),
          ),
        ),
      ),
    );
  }

  group('PremiumHomeCalendarWidget Tests', () {
    testWidgets('Renders hero day, month, Ge\'ez badge, and Gregorian dual date', (tester) async {
      final todayEth = EthiopianCalendarEngine.todayEthiopian();
      final expectedGeez = GeezNumeral.toGeez(todayEth.day);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Large day number
      expect(find.text('${todayEth.day}'), findsAtLeastNWidgets(1));

      // Ge'ez numeral badge
      expect(find.text(expectedGeez), findsOneWidget);

      // Today status indicator
      expect(find.text('ዛሬ · Today'), findsOneWidget);

      // Gregorian anchor text
      expect(find.byIcon(Icons.public_rounded), findsOneWidget);

      // Quick action shortcuts
      expect(find.text('ማስታወሻ'), findsOneWidget);
      expect(find.text('አጋራ'), findsOneWidget);
      expect(find.text('የስልክ ዊጄት'), findsOneWidget);
    });

    testWidgets('Stepping navigation shifts date backward and forward, Today button resets', (tester) async {
      final todayEth = EthiopianCalendarEngine.todayEthiopian();
      final prevDate = HomeWidgetEngine.shiftDays(todayEth, -1);
      final nextDate = HomeWidgetEngine.shiftDays(todayEth, 1);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Find previous day stepping button by icon
      final prevBtn = find.byIcon(Icons.chevron_left_rounded);
      expect(prevBtn, findsOneWidget);

      // Step to yesterday
      await tester.tap(prevBtn);
      await tester.pumpAndSettle();

      // Yesterday status pill should appear
      expect(find.text('ትላንት · Yesterday'), findsOneWidget);
      expect(find.text('${prevDate.day}'), findsAtLeastNWidgets(1));

      // "Today" reset button should now appear
      final resetBtn = find.text('ዛሬ');
      expect(resetBtn, findsOneWidget);

      // Tap reset button
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Restored to today
      expect(find.text('ዛሬ · Today'), findsOneWidget);
      expect(find.text('${todayEth.day}'), findsAtLeastNWidgets(1));

      // Step to tomorrow
      final nextBtn = find.byIcon(Icons.chevron_right_rounded);
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Tomorrow status pill should appear
      expect(find.text('ነገ · Tomorrow'), findsOneWidget);
      expect(find.text('${nextDate.day}'), findsAtLeastNWidgets(1));
    });

    testWidgets('Quick action callbacks fire when tapped', (tester) async {
      bool addEventTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          onAddEvent: () {
            addEventTapped = true;
          },
        ),
      );
      await tester.pump();

      // Tap "ማስታወሻ"
      final addEventBtn = find.text('ማስታወሻ');
      expect(addEventBtn, findsOneWidget);
      await tester.tap(addEventBtn);
      await tester.pump();

      expect(addEventTapped, isTrue);
    });
  });
}
