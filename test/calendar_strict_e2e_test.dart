import 'package:ethiocal/core/calendar/ethiopian_calendar_engine.dart';
import 'package:ethiocal/core/calendar/ethiopian_date.dart';
import 'package:ethiocal/data/preferences/user_preferences_repository.dart';
import 'package:ethiocal/features/shared/providers.dart';
import 'package:ethiocal/main.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Strict end-to-end journeys: unlike the smoke journey these never swallow
/// framework errors — any layout overflow or build exception fails the test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WidgetTester currentTester;

  setUp(() async {
    UserPreferencesRepository.resetForTest();
    SharedPreferences.setMockInitialValues({
      'pref_onboarding_completed': true,
      'pref_calendar_format': 'ETHIOPIAN',
      'pref_numeral_type': 'ARABIC',
      'pref_language': 'ENGLISH',
    });
    await UserPreferencesRepository.initialize();
  });

  /// Boots the full app on a small phone (360 x 740 dp) and records every
  /// framework error instead of stopping at the first one.
  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    currentTester = tester;
    await tester.pumpWidget(const ProviderScope(child: EthioCalApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    return ProviderScope.containerOf(tester.element(find.byType(EthioCalApp)));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  void expectNoErrors(String stage) {
    final error = currentTester.takeException();
    final summary = error?.toString().split('\n').take(4).join(' | ');
    expect(summary, isNull, reason: 'Framework error during: $stage');
  }

  Future<void> setMode(WidgetTester tester, ProviderContainer c, String mode) async {
    c.read(calendarViewModeProvider.notifier).state = mode;
    await settle(tester);
  }

  testWidgets('every top tab renders on a small phone without errors',
      (tester) async {
    await pumpApp(tester);
    expectNoErrors('boot');

    const labels = ['Converter', 'Holidays', 'Events', 'Football'];
    final strip = find.byWidgetPredicate(
      (w) => w is ListView && w.scrollDirection == Axis.horizontal,
    ).first;
    for (final label in labels) {
      for (var i = 0; i < 12 && find.text(label).evaluate().isEmpty; i++) {
        await tester.drag(strip, const Offset(-80, 0));
        await tester.pump(const Duration(milliseconds: 80));
      }
      await tester.ensureVisible(find.text(label).first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(label).first);
      await settle(tester);
      expectNoErrors('tab $label');
    }
  });

  testWidgets('all four calendar modes render in EC and GC without errors',
      (tester) async {
    final c = await pumpApp(tester);
    for (final format in ['ETHIOPIAN', 'GREGORIAN']) {
      await c.read(userSettingsProvider.notifier).setCalendarFormat(format);
      await settle(tester);
      for (final mode in ['MONTH', 'WEEK', 'YEAR', 'DAY', 'MONTH']) {
        await setMode(tester, c, mode);
        expectNoErrors('$format / $mode');
      }
    }
  });

  testWidgets('every Ethiopian month across two leap cycles builds a valid grid',
      (tester) async {
    final c = await pumpApp(tester);
    // 2012–2019 E.C. covers both Pagume lengths and the worst cases where
    // Meskerem / Nehase need six padding days next to a 5-day Pagume
    // (e.g. Meskerem 1, 2014 is a Saturday).
    for (var y = 2012; y <= 2019; y++) {
      for (var m = 1; m <= 13; m++) {
        c.read(viewYearProvider.notifier).state = y;
        c.read(viewMonthProvider.notifier).state = m;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expectNoErrors('EC month $y-$m');
      }
    }
  });

  testWidgets('week navigation in GC mode keeps the view in Gregorian terms',
      (tester) async {
    final c = await pumpApp(tester);
    await c.read(userSettingsProvider.notifier).setCalendarFormat('GREGORIAN');
    await settle(tester);
    await setMode(tester, c, 'WEEK');

    await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
    await settle(tester);
    expectNoErrors('GC week forward');

    final selected = c.read(selectedDateProvider);
    final g = EthiopianCalendarEngine.toGregorian(selected);
    expect(c.read(viewYearProvider), g.year);
    expect(c.read(viewMonthProvider), g.month);

    // Returning to the month grid must show the month of the selected date.
    await setMode(tester, c, 'MONTH');
    expectNoErrors('GC back to month');
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December',
    ];
    expect(find.text('${names[g.month - 1]} ${g.year}'), findsOneWidget);
  });

  testWidgets('year view in GC mode shows Gregorian months and opens them',
      (tester) async {
    final c = await pumpApp(tester);
    await c.read(userSettingsProvider.notifier).setCalendarFormat('GREGORIAN');
    await settle(tester);
    await setMode(tester, c, 'YEAR');
    expectNoErrors('GC year view');

    final gYear = EthiopianCalendarEngine.todayGregorian().year;
    expect(find.textContaining('$gYear'), findsWidgets);
    expect(find.textContaining('ዓ.ም'), findsNothing,
        reason: 'A Gregorian year must not be labelled as an Ethiopian year');
    expect(find.text('March'), findsOneWidget);

    await tester.tap(find.text('March'));
    await settle(tester);
    expectNoErrors('GC year → month');
    expect(c.read(calendarViewModeProvider), 'MONTH');
    expect(c.read(viewMonthProvider), 3);
    expect(find.text('March $gYear'), findsOneWidget);
  });

  testWidgets('month grid follows the view after navigating in another mode',
      (tester) async {
    final c = await pumpApp(tester);
    final today = c.read(todayEthiopianProvider);
    await setMode(tester, c, 'DAY');

    // Step forward 40 days so the selection leaves the starting month.
    for (var i = 0; i < 40; i++) {
      await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
      await tester.pump(const Duration(milliseconds: 30));
    }
    await settle(tester);
    final selected = c.read(selectedDateProvider);
    expect(EthiopianCalendarEngine.daysBetween(today, selected), 40);

    await setMode(tester, c, 'MONTH');
    expectNoErrors('day → month');

    // The visible grid page must be the selected date's month: its first
    // in-month Gregorian day number is rendered as the secondary date.
    final first = EthiopianCalendarEngine.toGregorian(
      EthiopianDate(selected.year, selected.month, 1),
    );
    expect(c.read(viewMonthProvider), selected.month);
    expect(
      find.byKey(ValueKey('cell-${selected.year}-${selected.month}-1')),
      findsOneWidget,
      reason: 'grid page is stale (expected month starting ${first.toString()})',
    );
  });

  testWidgets('selected day shows holidays even when it is outside the view year',
      (tester) async {
    final c = await pumpApp(tester);
    final year = c.read(todayEthiopianProvider).year;
    // Enkutatash of NEXT year, while the view stays on the current year.
    c.read(selectedDateProvider.notifier).state = EthiopianDate(year + 1, 1, 1);
    await setMode(tester, c, 'DAY');
    expectNoErrors('day view next-year holiday');
    expect(find.textContaining('Ethiopian New Year'), findsWidgets);
  });

  testWidgets('back button returns to the Calendar tab before leaving the app',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Converter').first);
    await settle(tester);
    expect(find.text('EC'), findsNothing);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('EC'), findsOneWidget);
    expectNoErrors('back to calendar');
  });
}
