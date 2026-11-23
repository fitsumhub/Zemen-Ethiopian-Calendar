import 'package:ethiocal/core/notifications/notification_scheduler.dart';
import 'package:ethiocal/data/models/event_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MONTHLY_ETHIOPIAN advances by Ethiopian month, not Gregorian', () {
    final event = EventEntity(
      id: 9,
      title: 'Monthly EC',
      ethiopianYear: 2017,
      ethiopianMonth: 1,
      ethiopianDay: 5,
      gregorianYear: 2024,
      gregorianMonth: 9,
      gregorianDay: 15,
      hour: 9,
      minute: 0,
      isAllDay: false,
      recurrence: 'MONTHLY_ETHIOPIAN',
      reminderMinutesBefore: 0,
      createdAt: 1,
    );

    final trigger = NotificationScheduler.calculateNextTriggerTime(
      event,
      now: DateTime(2024, 9, 20, 12),
    );

    expect(trigger, isNotNull);
    expect(trigger!.isAfter(DateTime(2024, 9, 20, 12)), isTrue);
  });

  test('NONE past event returns null', () {
    final event = EventEntity(
      id: 10,
      title: 'Past',
      ethiopianYear: 2016,
      ethiopianMonth: 1,
      ethiopianDay: 1,
      gregorianYear: 2023,
      gregorianMonth: 9,
      gregorianDay: 11,
      hour: 8,
      minute: 0,
      reminderMinutesBefore: 0,
      createdAt: 1,
    );
    expect(
      NotificationScheduler.calculateNextTriggerTime(
        event,
        now: DateTime(2024, 1, 1),
      ),
      isNull,
    );
  });
}
