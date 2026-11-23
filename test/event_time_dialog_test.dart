import 'package:ethiocal/core/calendar/ethiopian_calendar_engine.dart';
import 'package:ethiocal/core/localization/app_language.dart';
import 'package:ethiocal/core/notifications/notification_scheduler.dart';
import 'package:ethiocal/data/models/event_entity.dart';
import 'package:ethiocal/data/preferences/user_preferences_repository.dart';
import 'package:ethiocal/features/events/dialogs/add_edit_event_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'pref_onboarding_completed': true,
    });
    await UserPreferencesRepository.initialize();
  });

  testWidgets('new event dialog defaults to a clock time, not all-day', (tester) async {
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

    expect(find.text('Time'), findsWidgets);
    expect(find.textContaining('Tap to change'), findsOneWidget);
    expect(find.textContaining('All day (no clock time)'), findsNothing);
    expect(find.byIcon(Icons.access_time_rounded), findsWidgets);
  });

  test('all-day reminders schedule at 08:00 local', () {
    final event = EventEntity(
      id: 1,
      title: 'All day',
      ethiopianYear: 2017,
      ethiopianMonth: 1,
      ethiopianDay: 1,
      gregorianYear: 2024,
      gregorianMonth: 9,
      gregorianDay: 11,
      hour: 22,
      minute: 45,
      isAllDay: true,
      reminderMinutesBefore: 0,
      createdAt: 1,
    );

    final trigger = NotificationScheduler.calculateNextTriggerTime(
      event,
      now: DateTime(2024, 9, 10, 12),
    );

    expect(trigger, isNotNull);
    expect(trigger!.hour, 8);
    expect(trigger.minute, 0);
  });

  test('timed reminders keep the chosen clock time', () {
    final event = EventEntity(
      id: 2,
      title: 'Timed',
      ethiopianYear: 2017,
      ethiopianMonth: 1,
      ethiopianDay: 2,
      gregorianYear: 2024,
      gregorianMonth: 9,
      gregorianDay: 12,
      hour: 15,
      minute: 30,
      isAllDay: false,
      reminderMinutesBefore: 0,
      createdAt: 1,
    );

    final trigger = NotificationScheduler.calculateNextTriggerTime(
      event,
      now: DateTime(2024, 9, 10, 12),
    );

    expect(trigger, isNotNull);
    expect(trigger!.hour, 15);
    expect(trigger.minute, 30);
  });
}
