import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ethiocal/core/calendar/ethiopian_calendar_engine.dart';
import 'package:ethiocal/core/calendar/ethiopian_date.dart';
import 'package:ethiocal/core/calendar/geez_numeral.dart';
import 'package:ethiocal/core/calendar/gregorian_date.dart';
import 'package:ethiocal/core/calendar/leap_year_calculator.dart';
import 'package:ethiocal/core/holidays/holiday_engine.dart';
import 'package:ethiocal/data/models/event_entity.dart';
import 'package:ethiocal/data/preferences/user_preferences_repository.dart';
import 'package:ethiocal/features/calendar/calendar_home_screen.dart';
import 'package:ethiocal/features/converter/converter_home_screen.dart';
import 'package:ethiocal/features/shared/providers.dart';

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

  group('Calendar Functional Logic Tests', () {
    test('Event matching recurrence rules', () {
      final baseDate = EthiopianDate(2017, 3, 6); // Hidar 6, 2017

      final nonRecurring = EventEntity(
        id: 1,
        title: 'Meeting',
        description: '',
        category: 'WORK',
        ethiopianYear: 2017,
        ethiopianMonth: 3,
        ethiopianDay: 6,
        gregorianYear: 2024,
        gregorianMonth: 11,
        gregorianDay: 15,
        hour: 9,
        minute: 0,
        isAllDay: false,
        recurrence: 'NONE',
        reminderMinutesBefore: 15,
        createdAt: 0,
      );
      expect(eventMatchesDate(nonRecurring, baseDate), isTrue);
      expect(eventMatchesDate(nonRecurring, EthiopianDate(2017, 3, 7)), isFalse);

      final daily = nonRecurring.copyWith(recurrence: 'DAILY');
      expect(eventMatchesDate(daily, EthiopianDate(2017, 3, 7)), isTrue);
      expect(eventMatchesDate(daily, EthiopianDate(2018, 1, 1)), isTrue);

      final monthlyEth = nonRecurring.copyWith(recurrence: 'MONTHLY_ETHIOPIAN');
      expect(eventMatchesDate(monthlyEth, EthiopianDate(2017, 4, 6)), isTrue);
      expect(eventMatchesDate(monthlyEth, EthiopianDate(2017, 4, 7)), isFalse);

      final yearlyEth = nonRecurring.copyWith(recurrence: 'YEARLY_ETHIOPIAN');
      expect(eventMatchesDate(yearlyEth, EthiopianDate(2018, 3, 6)), isTrue);
      expect(eventMatchesDate(yearlyEth, EthiopianDate(2018, 4, 6)), isFalse);
    });

    test('Relative date label formatting', () {
      final today = EthiopianDate(2017, 3, 6);
      expect(getRelativeDateLabel(today, today, false), contains('ዛሬ'));
      expect(getRelativeDateLabel(today, EthiopianDate(2017, 3, 7), false), contains('ነገ'));
      expect(getRelativeDateLabel(today, EthiopianDate(2017, 3, 5), false), contains('ትናንት'));
      expect(getRelativeDateLabel(today, EthiopianDate(2017, 3, 10), false), contains('4 ቀናት በኋላ'));
    });

    test('Selected date inspector month correctness', () {
      // Hidar 2017
      final sel = EthiopianDate(2017, 3, 6);
      final g = EthiopianCalendarEngine.toGregorian(sel);
      expect(g.year, 2024);
      expect(g.month, 11);
      expect(g.day, 15);

      final saint = HolidayEngine.monthlySaints.firstWhere((s) => s.day == 6);
      expect(saint.nameAmharic, contains('ኢየሱስ'));
    });

    test('Leap year Pagume 5 vs 6 days check', () {
      // 2015 Luke leap year -> Pagume has 6 days
      expect(EthiopianDate.daysInMonthFor(2015, 13), 6);
      expect(LeapYearCalculator.isEthiopianLeapYear(2015), isTrue);

      // 2016 John normal year -> Pagume has 5 days
      expect(EthiopianDate.daysInMonthFor(2016, 13), 5);
      expect(LeapYearCalculator.isEthiopianLeapYear(2016), isFalse);

      // 2019 Luke leap year -> Pagume has 6 days
      expect(EthiopianDate.daysInMonthFor(2019, 13), 6);
      expect(LeapYearCalculator.isEthiopianLeapYear(2019), isTrue);
    });

    test('Ge\'ez numerals conversion for calendar days', () {
      expect(GeezNumeral.toGeez(1), '፩');
      expect(GeezNumeral.toGeez(5), '፭');
      expect(GeezNumeral.toGeez(10), '፲');
      expect(GeezNumeral.toGeez(12), '፲፪');
      expect(GeezNumeral.toGeez(21), '፳፩');
      expect(GeezNumeral.toGeez(29), '፳፱');
      expect(GeezNumeral.toGeez(30), '፴');
    });

    test('GC month view uses sequential Gregorian days (not Eth remapped)', () {
      // November 2024 has 30 days; day numbers must be 1..30 consecutive.
      const year = 2024;
      const month = 11;
      final days = List.generate(
        GregorianDate.daysInMonthFor(year, month),
        (i) => i + 1,
      );
      expect(days.first, 1);
      expect(days.last, 30);
      expect(days, List.generate(30, (i) => i + 1));

      // Round-trip: GC day → Eth → GC keeps the same Gregorian day.
      for (final d in days) {
        final g = GregorianDate(year, month, d);
        final eth = EthiopianCalendarEngine.toEthiopian(g);
        final back = EthiopianCalendarEngine.toGregorian(eth);
        expect(back.year, year);
        expect(back.month, month);
        expect(back.day, d);
      }
    });
  });

  group('Calendar & Converter Widget Tests', () {
    testWidgets('CalendarHomeScreen renders month grid, week headers, and inspector',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: CalendarHomeScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // View switcher + legend follow app language (English default)
      expect(find.text('Month'), findsWidgets);
      expect(find.text('Week'), findsWidgets);
      expect(find.text('Year'), findsWidgets);
      expect(find.text('Day'), findsWidgets);

      expect(find.text('Public holiday'), findsWidgets);
      expect(find.text('Feast'), findsWidgets);
      expect(find.text('Event'), findsWidgets);

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('ConverterHomeScreen switches between modes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ConverterHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Convert (ቀን)'), findsOneWidget);
      expect(find.text('Age (ዕድሜ)'), findsOneWidget);
      expect(find.text('Math (ልዩነት)'), findsOneWidget);
      expect(find.text('Computus (ባሕረ ሐሳብ)'), findsOneWidget);
      expect(find.text("Ge'ez (ግዕዝ)"), findsOneWidget);
      expect(find.text('Time (ሰዓት)'), findsOneWidget);
    });
  });
}
