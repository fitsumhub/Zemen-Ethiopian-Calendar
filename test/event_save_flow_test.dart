import 'package:ethiocal/core/calendar/ethiopian_calendar_engine.dart';
import 'package:ethiocal/core/localization/app_language.dart';
import 'package:ethiocal/data/models/event_entity.dart';
import 'package:ethiocal/data/preferences/user_preferences_repository.dart';
import 'package:ethiocal/features/events/dialogs/add_edit_event_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'pref_onboarding_completed': true,
    });
    await UserPreferencesRepository.initialize();
  });

  testWidgets('Save event returns draft with title and dual dates', (tester) async {
    final today = EthiopianCalendarEngine.todayEthiopian();
    EventEntity? saved;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    saved = await AddEditEventDialog.open(
                      context,
                      initialDate: today,
                      currentLanguage: AppLanguage.english,
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Add reminder / event'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Team standup');
    await tester.pump();

    await tester.ensureVisible(find.text('Save event'));
    await tester.tap(find.text('Save event'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.title, 'Team standup');
    expect(saved!.ethiopianYear, today.year);
    expect(saved!.ethiopianMonth, today.month);
    expect(saved!.ethiopianDay, today.day);
    expect(saved!.gregorianYear, greaterThan(2000));
  });

  testWidgets('Save event without title shows field error and stays open', (
    tester,
  ) async {
    final today = EthiopianCalendarEngine.todayEthiopian();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    AddEditEventDialog.open(
                      context,
                      initialDate: today,
                      currentLanguage: AppLanguage.english,
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save event'));
    await tester.tap(find.text('Save event'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Please enter a title'), findsOneWidget);
    expect(find.text('Add reminder / event'), findsOneWidget);
  });
}
