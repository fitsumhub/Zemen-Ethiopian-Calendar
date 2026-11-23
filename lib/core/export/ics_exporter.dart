import '../../data/models/event_entity.dart';

class IcsExporter {
  /// Exports a list of EventEntity items into standard iCalendar (.ics) format.
  static String exportToIcs(List<EventEntity> events) {
    final sb = StringBuffer();
    sb.write('BEGIN:VCALENDAR\r\n');
    sb.write('VERSION:2.0\r\n');
    sb.write('PRODID:-//Zemen: Ethiopian Calendar//Ethiopian Calendar//EN\r\n');
    sb.write('CALSCALE:GREGORIAN\r\n');
    sb.write('METHOD:PUBLISH\r\n');

    for (final event in events) {
      sb.write('BEGIN:VEVENT\r\n');
      sb.write('UID:event-${event.id}-${event.createdAt}@ethiocal.pro\r\n');

      final dtStampUtc = DateTime.fromMillisecondsSinceEpoch(
        event.createdAt,
        isUtc: true,
      );
      final dtStampStr =
          '${dtStampUtc.year.toString().padLeft(4, '0')}'
          '${dtStampUtc.month.toString().padLeft(2, '0')}'
          '${dtStampUtc.day.toString().padLeft(2, '0')}T'
          '${dtStampUtc.hour.toString().padLeft(2, '0')}'
          '${dtStampUtc.minute.toString().padLeft(2, '0')}'
          '${dtStampUtc.second.toString().padLeft(2, '0')}Z';
      sb.write('DTSTAMP:$dtStampStr\r\n');

      if (event.isAllDay) {
        final dt =
            '${event.gregorianYear.toString().padLeft(4, '0')}'
            '${event.gregorianMonth.toString().padLeft(2, '0')}'
            '${event.gregorianDay.toString().padLeft(2, '0')}';
        sb.write('DTSTART;VALUE=DATE:$dt\r\n');
      } else {
        final dt =
            '${event.gregorianYear.toString().padLeft(4, '0')}'
            '${event.gregorianMonth.toString().padLeft(2, '0')}'
            '${event.gregorianDay.toString().padLeft(2, '0')}T'
            '${event.hour.toString().padLeft(2, '0')}'
            '${event.minute.toString().padLeft(2, '0')}00';
        sb.write('DTSTART:$dt\r\n');
      }

      sb.write('SUMMARY:${_escapeIcs(event.title)}\r\n');
      if (event.description.isNotEmpty) {
        sb.write('DESCRIPTION:${_escapeIcs(event.description)}\r\n');
      }
      sb.write('CATEGORIES:${_escapeIcs(event.category)}\r\n');

      switch (event.recurrence) {
        case 'DAILY':
          sb.write('RRULE:FREQ=DAILY\r\n');
          break;
        case 'WEEKLY':
          sb.write('RRULE:FREQ=WEEKLY\r\n');
          break;
        case 'MONTHLY_GREGORIAN':
          sb.write('RRULE:FREQ=MONTHLY\r\n');
          break;
        case 'YEARLY_GREGORIAN':
          sb.write('RRULE:FREQ=YEARLY\r\n');
          break;
      }

      sb.write('END:VEVENT\r\n');
    }

    sb.write('END:VCALENDAR\r\n');
    return sb.toString();
  }

  static String _escapeIcs(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('\n', '\\n');
  }
}
