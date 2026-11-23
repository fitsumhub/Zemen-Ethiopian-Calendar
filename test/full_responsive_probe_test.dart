import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ethiocal/data/preferences/user_preferences_repository.dart';
import 'package:ethiocal/features/calendar/calendar_home_screen.dart';
import 'package:ethiocal/features/converter/converter_home_screen.dart';
import 'package:ethiocal/features/events/events_hub_screen.dart';
import 'package:ethiocal/features/holidays/holidays_screen.dart';
import 'package:ethiocal/features/home/home_screen.dart';
import 'package:ethiocal/features/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    UserPreferencesRepository.resetForTest();
    SharedPreferences.setMockInitialValues({
      'pref_onboarding_completed': true,
      'pref_language': 'AMHARIC',
      'pref_theme_mode': 'DARK',
      'pref_calendar_format': 'ETHIOPIAN',
    });
    await UserPreferencesRepository.initialize();
  });

  Future<List<String>> testViewport(
    WidgetTester tester, {
    required Size size,
    double scale = 1.0,
    required Widget child,
  }) async {
    final errors = <String>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final s = details.exceptionAsString();
      if (s.contains('overflowed') || s.contains('RenderFlex') || s.contains('A RenderFlex')) {
        errors.add(s);
      }
      originalOnError?.call(details);
    };

    addTearDown(() {
      FlutterError.onError = originalOnError;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return errors;
  }

  group('Full App 100% Responsiveness Probe', () {
    final testSizes = [
      ('Ultra-compact 320x568 scale 1.3', const Size(320, 568), 1.3),
      ('Compact phone 360x640', const Size(360, 640), 1.0),
      ('Modern phone 390x844', const Size(390, 844), 1.0),
      ('Large phone 412x915 scale 1.2', const Size(412, 915), 1.2),
      ('Foldable inner 673x841', const Size(673, 841), 1.0),
      ('Tablet Portrait 768x1024', const Size(768, 1024), 1.0),
      ('Tablet Landscape 1024x768', const Size(1024, 768), 1.0),
      ('Desktop/Web 1440x900', const Size(1440, 900), 1.0),
    ];

    for (final (label, size, scale) in testSizes) {
      testWidgets('CalendarHomeScreen on $label', (tester) async {
        final errs = await testViewport(
          tester,
          size: size,
          scale: scale,
          child: const CalendarHomeScreen(),
        );
        expect(errs, isEmpty, reason: 'Overflow in CalendarHomeScreen on $label');
      });

      testWidgets('ConverterHomeScreen on $label', (tester) async {
        final errs = await testViewport(
          tester,
          size: size,
          scale: scale,
          child: const ConverterHomeScreen(),
        );
        expect(errs, isEmpty, reason: 'Overflow in ConverterHomeScreen on $label');
      });

      testWidgets('HolidaysScreen on $label', (tester) async {
        final errs = await testViewport(
          tester,
          size: size,
          scale: scale,
          child: const HolidaysScreen(),
        );
        expect(errs, isEmpty, reason: 'Overflow in HolidaysScreen on $label');
      });

      testWidgets('EventsHubScreen on $label', (tester) async {
        final errs = await testViewport(
          tester,
          size: size,
          scale: scale,
          child: EventsHubScreen(onOpenDate: (_) {}),
        );
        expect(errs, isEmpty, reason: 'Overflow in EventsHubScreen on $label');
      });

      testWidgets('SettingsScreen on $label', (tester) async {
        final errs = await testViewport(
          tester,
          size: size,
          scale: scale,
          child: const SettingsScreen(),
        );
        expect(errs, isEmpty, reason: 'Overflow in SettingsScreen on $label');
      });

      testWidgets('HomeScreen on $label', (tester) async {
        final errs = await testViewport(
          tester,
          size: size,
          scale: scale,
          child: HomeScreen(onNavigateDestination: (_) {}),
        );
        expect(errs, isEmpty, reason: 'Overflow in HomeScreen on $label');
      });
    }
  });
}
