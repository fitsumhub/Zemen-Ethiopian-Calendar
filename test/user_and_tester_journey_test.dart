import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ethiocal/core/brand/brand.dart';
import 'package:ethiocal/data/preferences/user_preferences_repository.dart';
import 'package:ethiocal/features/calendar/calendar_home_screen.dart';
import 'package:ethiocal/features/converter/converter_home_screen.dart';
import 'package:ethiocal/features/football/football_screen.dart';
import 'package:ethiocal/features/holidays/holidays_screen.dart';
import 'package:ethiocal/features/onboarding/onboarding_screen.dart';
import 'package:ethiocal/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    UserPreferencesRepository.resetForTest();
    SharedPreferences.setMockInitialValues({
      'pref_onboarding_completed': true,
      'pref_theme_mode': 'LIGHT',
      'pref_language': 'ENGLISH',
    });
    await UserPreferencesRepository.initialize();
  });

  void setViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> openTabByIndex(WidgetTester tester, int index) async {
    final strips = find.byWidgetPredicate(
      (w) => w is ListView && w.scrollDirection == Axis.horizontal,
    );
    expect(strips, findsWidgets);
    final strip = strips.first;
    for (var i = 0; i < index; i++) {
      await tester.drag(strip, const Offset(-140, 0));
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

  group('End-to-End User & QA Tester Simulation Suite', () {
    testWidgets('Persona 1: First-Time User Onboarding Journey & Responsiveness', (tester) async {
      setViewport(tester);
      UserPreferencesRepository.resetForTest();
      SharedPreferences.setMockInitialValues({
        'pref_onboarding_completed': false,
        'pref_theme_mode': 'LIGHT',
      });
      await UserPreferencesRepository.initialize();

      await tester.pumpWidget(const ProviderScope(child: EthioCalApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Onboarding rendered without any RenderFlex overflow');
    });

    testWidgets('Persona 2: Daily Calendar User & EC/GC Exploration', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(const ProviderScope(child: EthioCalApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(MainNavigationShell), findsOneWidget);
      expect(find.byType(CalendarHomeScreen), findsOneWidget);

      // Verify grid day interaction
      final dayCells = find.text('15');
      if (dayCells.evaluate().isNotEmpty) {
        await tester.tap(dayCells.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('Persona 3: Navigation Drawer & Brand Hub Verification', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(const ProviderScope(child: EthioCalApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      final menuIcon = find.byIcon(Icons.menu_rounded);
      expect(menuIcon, findsOneWidget);

      await tester.tap(menuIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(Brand.shortName), findsWidgets);
      expect(find.text('Calendar'), findsWidgets);
      expect(find.text('Converter'), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'Drawer opened without MaterialLocalizations crash');
    });

    testWidgets('Persona 4: Converter Features Navigation', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(const ProviderScope(child: EthioCalApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      await openTabByIndex(tester, 1);

      expect(find.byType(ConverterHomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Persona 5: Football Tab Exploration', (tester) async {
      setViewport(tester);
      UserPreferencesRepository.resetForTest();
      SharedPreferences.setMockInitialValues({
        'pref_onboarding_completed': true,
        'pref_theme_mode': 'LIGHT',
        'pref_language': 'ENGLISH',
        'pref_show_football': true,
      });
      await UserPreferencesRepository.initialize();

      await tester.pumpWidget(const ProviderScope(child: EthioCalApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      await openTabByIndex(tester, 4);

      expect(find.byType(FootballScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Flush pending football refresh delays / HTTP timeout timers.
      await tester.pump(const Duration(seconds: 20));
      await tester.pump(const Duration(seconds: 20));
    });

    testWidgets('Persona 6: Holidays Tab Exploration', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(const ProviderScope(child: EthioCalApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      await openTabByIndex(tester, 2);

      expect(find.byType(HolidaysScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
