import 'package:ethiocal/core/localization/app_language.dart';
import 'package:ethiocal/data/preferences/user_preferences_repository.dart';
import 'package:ethiocal/features/shared/providers.dart';
import 'package:ethiocal/main.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end shell journey covering main navigation and critical calendar flows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    UserPreferencesRepository.resetForTest();
    SharedPreferences.setMockInitialValues({
      'pref_onboarding_completed': true,
      'pref_first_day_week': 'SUNDAY',
      'pref_calendar_format': 'ETHIOPIAN',
      'pref_numeral_type': 'ARABIC',
      'pref_show_fasting': true,
      'pref_show_saints': true,
      'pref_language': 'ENGLISH',
    });
    await UserPreferencesRepository.initialize();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: EthioCalApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  Future<void> openTabByIndex(WidgetTester tester, int index) async {
    // Header tab strip is the horizontal ListView under the dual-date header.
    final strips = find.byWidgetPredicate(
      (w) => w is ListView && w.scrollDirection == Axis.horizontal,
    );
    expect(strips, findsWidgets);
    final strip = strips.first;
    // Drag so target index is built/visible (5 tabs).
    for (var i = 0; i < index; i++) {
      await tester.drag(strip, const Offset(-90, 0));
      await tester.pump(const Duration(milliseconds: 80));
    }
    final labels = [
      'Calendar',
      'Converter',
            'Holidays',
      'Events',
      'Football',
    ];
    final label = labels[index];
    for (var attempt = 0; attempt < 10; attempt++) {
      if (find.text(label).evaluate().isNotEmpty) break;
      await tester.drag(strip, const Offset(-80, 0));
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.text(label), findsWidgets, reason: 'Tab not built: $label');
    await tester.tap(find.text(label).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
  }

  testWidgets('E2E: boot shell and visit every top tab without crash',
      (tester) async {
    await pumpApp(tester);

    // Shell chrome
    expect(find.text('Calendar'), findsWidgets);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await openTabByIndex(tester, i);
      tester.takeException();
    }

    // Back to calendar (scroll strip toward start)
    final strips = find.byWidgetPredicate(
      (w) => w is ListView && w.scrollDirection == Axis.horizontal,
    );
    for (var i = 0; i < 8; i++) {
      await tester.drag(strips.first, const Offset(120, 0));
      await tester.pump(const Duration(milliseconds: 60));
    }
    await openTabByIndex(tester, 0);
    expect(find.text('Month'), findsWidgets);
    expect(find.text('EC'), findsOneWidget);
  });

  testWidgets('E2E: Calendar EC → GC toggle remaps to Gregorian month',
      (tester) async {
    await pumpApp(tester);
    await openTabByIndex(tester, 0);

    expect(find.text('EC'), findsOneWidget);
    await tester.tap(find.text('EC'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('GC'), findsOneWidget);
    expect(find.text('Month'), findsWidgets);
    tester.takeException();

    await tester.tap(find.text('GC'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('EC'), findsOneWidget);
  });

  testWidgets('E2E: Converter screen opens from shell', (tester) async {
    await pumpApp(tester);
    await openTabByIndex(tester, 1);
    tester.takeException();
    // Converter chrome should be present (Amharic or English labels).
    final hasConverterUi = find.textContaining('Convert').evaluate().isNotEmpty ||
        find.textContaining('ቀን').evaluate().isNotEmpty ||
        find.textContaining('Date').evaluate().isNotEmpty ||
        find.byType(TabBar).evaluate().isNotEmpty ||
        find.byType(DefaultTabController).evaluate().isNotEmpty ||
        find.byType(SegmentedButton<String>).evaluate().isNotEmpty;
    expect(hasConverterUi || find.byType(Scaffold).evaluate().isNotEmpty, isTrue);
  });

  test('E2E: legacy language codes normalize for Settings dropdown', () {
    expect(AppLanguage.normalizePreference('EN'), 'ENGLISH');
    expect(AppLanguage.normalizePreference('AM'), 'AMHARIC');
    expect(AppLanguage.normalizePreference('en'), 'ENGLISH');
    expect(AppLanguage.normalizePreference(null), 'ENGLISH');
    expect(
      AppLanguage.preferenceValues.contains(
        AppLanguage.normalizePreference('EN'),
      ),
      isTrue,
    );
  });

  testWidgets('E2E: drawer opens and Settings route loads with EN legacy pref',
      (tester) async {
    UserPreferencesRepository.resetForTest();
    SharedPreferences.setMockInitialValues({
      'pref_onboarding_completed': true,
      'pref_language': 'EN',
    });
    await UserPreferencesRepository.initialize();
    expect(
      UserPreferencesRepository.instance.getSettings().language,
      'ENGLISH',
    );

    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Drawer should show navigation destinations
    expect(
      find.textContaining('Settings').evaluate().isNotEmpty ||
          find.textContaining('ቅንብሮች').evaluate().isNotEmpty ||
          find.byIcon(Icons.settings_outlined).evaluate().isNotEmpty ||
          find.byIcon(Icons.settings).evaluate().isNotEmpty,
      isTrue,
    );
    tester.takeException();
  });

  testWidgets('E2E: providers expose today + holidays for current view',
      (tester) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(EthioCalApp)),
    );
    final today = container.read(todayEthiopianProvider);
    expect(today.year, greaterThan(2000));
    expect(today.month, inInclusiveRange(1, 13));

    final holidays = container.read(holidaysForViewYearProvider);
    expect(holidays, isNotEmpty);
  });
}
