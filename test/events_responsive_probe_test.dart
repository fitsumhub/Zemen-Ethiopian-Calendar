import 'package:ethiocal/core/calendar/ethiopian_calendar_engine.dart';
import 'package:ethiocal/data/preferences/user_preferences_repository.dart';
import 'package:ethiocal/features/events/dialogs/add_edit_event_dialog.dart';
import 'package:ethiocal/features/events/events_hub_screen.dart';
import 'package:ethiocal/features/events/events_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({'pref_onboarding_completed': true});
    await UserPreferencesRepository.initialize();
  });

  Future<List<String>> capture(WidgetTester tester, Size size, {double scale = 1, double keyboard = 0, required Widget home}) async {
    final errors = <String>[];
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      final s = d.exceptionAsString();
      if (s.contains('overflowed') || s.contains('RenderFlex') || s.contains('UNBOUNDED')) {
        errors.add(s.split('\n').take(5).join(' || '));
      }
      old?.call(d);
    };
    addTearDown(() {
      FlutterError.onError = old;
      tester.view.resetPhysicalSize();
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
            viewInsets: EdgeInsets.only(bottom: keyboard),
            padding: const EdgeInsets.only(bottom: 24),
          ),
          child: home,
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return errors;
  }

  testWidgets('events hub compact + large text', (tester) async {
    final e = await capture(tester, const Size(320, 568), scale: 1.4, home: Scaffold(body: EventsHubScreen(onOpenDate: (_) {})));
    expect(e, isEmpty);
  });

  testWidgets('events list compact', (tester) async {
    final e = await capture(tester, const Size(320, 568), scale: 1.3, home: const Scaffold(body: EventsScreen()));
    expect(e, isEmpty);
  });

  testWidgets('dialog with keyboard', (tester) async {
    final today = EthiopianCalendarEngine.todayEthiopian();
    final e = await capture(
      tester,
      const Size(360, 740),
      keyboard: 320,
      home: Scaffold(
        body: Builder(builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AddEditEventDialog.open(context, initialDate: today);
          });
          return const SizedBox.expand();
        }),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(e, isEmpty);
  });
}
