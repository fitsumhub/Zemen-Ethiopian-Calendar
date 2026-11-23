package com.example.calendar.data

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

object IcsExporter {

    /**
     * Exports a list of EventEntity items into standard iCalendar (.ics) format.
     */
    fun exportToIcs(events: List<EventEntity>): String {
        val dateFormat = SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
        val dateOnlyFormat = SimpleDateFormat("yyyyMMdd", Locale.US)

        val sb = StringBuilder()
        sb.append("BEGIN:VCALENDAR\r\n")
        sb.append("VERSION:2.0\r\n")
        sb.append("PRODID:-//EthioCal Pro//Ethiopian Calendar//EN\r\n")
        sb.append("CALSCALE:GREGORIAN\r\n")
        sb.append("METHOD:PUBLISH\r\n")

        for (event in events) {
            sb.append("BEGIN:VEVENT\r\n")
            sb.append("UID:event-${event.id}-${event.createdAt}@ethiocal.pro\r\n")
            sb.append("DTSTAMP:${dateFormat.format(Date(event.createdAt))}\r\n")

            // Format event start
            if (event.isAllDay) {
                val dt = String.format(Locale.US, "%04d%02d%02d", event.gregorianYear, event.gregorianMonth, event.gregorianDay)
                sb.append("DTSTART;VALUE=DATE:$dt\r\n")
            } else {
                val dt = String.format(
                    Locale.US,
                    "%04d%02d%02dT%02d%02d00",
                    event.gregorianYear,
                    event.gregorianMonth,
                    event.gregorianDay,
                    event.hour,
                    event.minute
                )
                sb.append("DTSTART:$dt\r\n")
            }

            sb.append("SUMMARY:${escapeIcs(event.title)}\r\n")
            if (event.description.isNotEmpty()) {
                sb.append("DESCRIPTION:${escapeIcs(event.description)}\r\n")
            }
            sb.append("CATEGORIES:${escapeIcs(event.category)}\r\n")

            // Recurrence rule
            when (event.recurrence) {
                "DAILY" -> sb.append("RRULE:FREQ=DAILY\r\n")
                "WEEKLY" -> sb.append("RRULE:FREQ=WEEKLY\r\n")
                "MONTHLY_GREGORIAN" -> sb.append("RRULE:FREQ=MONTHLY\r\n")
                "YEARLY_GREGORIAN" -> sb.append("RRULE:FREQ=YEARLY\r\n")
            }

            sb.append("END:VEVENT\r\n")
        }

        sb.append("END:VCALENDAR\r\n")
        return sb.toString()
    }

    private fun escapeIcs(value: String): String {
        return value
            .replace("\\", "\\\\")
            .replace(";", "\\;")
            .replace(",", "\\,")
            .replace("\n", "\\n")
    }
}
