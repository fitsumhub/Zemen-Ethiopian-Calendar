package com.example.calendar.data

import android.Manifest
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.CalendarContract
import androidx.core.content.ContextCompat
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.GregorianDate
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

/**
 * Manages two-way synchronization between EthioCal Pro events and the native Android
 * CalendarProvider (Google Calendar, Device Account calendars, etc.).
 */
object AndroidCalendarSyncManager {

    data class DeviceCalendar(
        val id: Long,
        val displayName: String,
        val accountName: String,
        val isPrimary: Boolean
    )

    data class SyncResult(
        val successCount: Int,
        val failCount: Int,
        val message: String
    )

    fun hasCalendarPermissions(context: Context): Boolean {
        val readGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_CALENDAR
        ) == PackageManager.PERMISSION_GRANTED
        val writeGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.WRITE_CALENDAR
        ) == PackageManager.PERMISSION_GRANTED
        return readGranted && writeGranted
    }

    /**
     * Retrieves all available calendars associated with user accounts on the device.
     */
    fun getAvailableCalendars(context: Context): List<DeviceCalendar> {
        if (!hasCalendarPermissions(context)) return emptyList()

        val list = mutableListOf<DeviceCalendar>()
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.IS_PRIMARY
        )

        try {
            val cursor = context.contentResolver.query(
                CalendarContract.Calendars.CONTENT_URI,
                projection,
                null,
                null,
                "${CalendarContract.Calendars.IS_PRIMARY} DESC, ${CalendarContract.Calendars.CALENDAR_DISPLAY_NAME} ASC"
            )

            cursor?.use {
                val idIdx = it.getColumnIndexOrThrow(CalendarContract.Calendars._ID)
                val nameIdx = it.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME)
                val acctIdx = it.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_NAME)
                val primIdx = it.getColumnIndexOrThrow(CalendarContract.Calendars.IS_PRIMARY)

                while (it.moveToNext()) {
                    val id = it.getLong(idIdx)
                    val name = it.getString(nameIdx) ?: "Default Calendar"
                    val acct = it.getString(acctIdx) ?: ""
                    val isPrimary = it.getInt(primIdx) == 1
                    list.add(DeviceCalendar(id, name, acct, isPrimary))
                }
            }
        } catch (_: Exception) {
            // Fail gracefully if security or content provider issue
        }

        return list
    }

    /**
     * Resolves the primary or first writable calendar ID.
     */
    fun getDefaultCalendarId(context: Context): Long? {
        val calendars = getAvailableCalendars(context)
        return calendars.firstOrNull { it.isPrimary }?.id
            ?: calendars.firstOrNull()?.id
    }

    /**
     * Exports a single EthioCal event to the Android System CalendarProvider.
     */
    fun syncEventToDeviceCalendar(
        context: Context,
        event: EventEntity,
        targetCalendarId: Long? = null
    ): Long? {
        if (!hasCalendarPermissions(context)) return null

        val calId = targetCalendarId ?: getDefaultCalendarId(context) ?: return null
        val timeZone = TimeZone.getDefault().id

        // Calculate Gregorian start and end time
        val startCal = Calendar.getInstance().apply {
            set(Calendar.YEAR, event.gregorianYear)
            set(Calendar.MONTH, event.gregorianMonth - 1)
            set(Calendar.DAY_OF_MONTH, event.gregorianDay)
            set(Calendar.HOUR_OF_DAY, if (event.isAllDay) 9 else event.hour)
            set(Calendar.MINUTE, if (event.isAllDay) 0 else event.minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val endCal = (startCal.clone() as Calendar).apply {
            if (event.isAllDay) {
                set(Calendar.HOUR_OF_DAY, 18)
            } else {
                add(Calendar.HOUR_OF_DAY, 1)
            }
        }

        val monthName = LocaleStrings.getMonthName(event.ethiopianMonth, AppLanguage.AMHARIC)
        val ethDateDesc = "$monthName ${event.ethiopianDay}፣ ${event.ethiopianYear} ዓ.ም"
        val timeDesc = if (event.isAllDay) "ሙሉ ቀን (All Day)" else String.format(Locale.US, "%02d:%02d", event.hour, event.minute)

        val fullDescription = buildString {
            append("🇪🇹 የኢትዮጵያ ቀን: $ethDateDesc\n")
            append("⏰ ሰዓት: $timeDesc\n")
            append("📌 ምድብ: ${event.category}\n")
            if (event.description.isNotBlank()) {
                append("\n${event.description}\n")
            }
            append("\n[EthioCal Pro - Synced Event]")
        }

        val values = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, calId)
            put(CalendarContract.Events.TITLE, "🇪🇹 ${event.title}")
            put(CalendarContract.Events.DESCRIPTION, fullDescription)
            put(CalendarContract.Events.EVENT_LOCATION, "Ethiopia")
            put(CalendarContract.Events.DTSTART, startCal.timeInMillis)
            put(CalendarContract.Events.DTEND, endCal.timeInMillis)
            put(CalendarContract.Events.ALL_DAY, if (event.isAllDay) 1 else 0)
            put(CalendarContract.Events.EVENT_TIMEZONE, timeZone)
            put(CalendarContract.Events.STATUS, CalendarContract.Events.STATUS_CONFIRMED)
        }

        return try {
            val uri = context.contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
            val eventId = uri?.lastPathSegment?.toLongOrNull()

            if (eventId != null && event.reminderMinutesBefore >= 0) {
                // Add reminder
                val reminderValues = ContentValues().apply {
                    put(CalendarContract.Reminders.EVENT_ID, eventId)
                    put(CalendarContract.Reminders.MINUTES, event.reminderMinutesBefore)
                    put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
                }
                context.contentResolver.insert(CalendarContract.Reminders.CONTENT_URI, reminderValues)
            }

            eventId
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Synchronizes a list of EthioCal events to the Android System Calendar.
     */
    fun syncAllEventsToDevice(context: Context, events: List<EventEntity>): SyncResult {
        if (!hasCalendarPermissions(context)) {
            return SyncResult(0, events.size, "የካላንደር ፈቃድ አልተሰጠም (Calendar permissions not granted)")
        }

        val calId = getDefaultCalendarId(context)
            ?: return SyncResult(0, events.size, "ምንም የሚገኝ የስልክ ካላንደር አልተገኘም (No device calendar found)")

        var success = 0
        var fail = 0

        for (event in events) {
            val id = syncEventToDeviceCalendar(context, event, calId)
            if (id != null) {
                success++
            } else {
                fail++
            }
        }

        return SyncResult(
            successCount = success,
            failCount = fail,
            message = if (fail == 0) "$success ማስታወሻዎች በተሳካ ሁኔታ ወደ ስልክ ካላንደር ተመሳስለዋል" else "$success ተመሳስለዋል፣ $fail አልተሳኩም"
        )
    }

    /**
     * Imports upcoming events from the Android device calendar and converts them
     * to Ethiopian Calendar events.
     */
    fun importEventsFromDeviceCalendar(context: Context): List<EventEntity> {
        if (!hasCalendarPermissions(context)) return emptyList()

        val imported = mutableListOf<EventEntity>()
        val now = System.currentTimeMillis()
        val oneYearAhead = now + (365L * 24 * 60 * 60 * 1000)

        val projection = arrayOf(
            CalendarContract.Events._ID,
            CalendarContract.Events.TITLE,
            CalendarContract.Events.DESCRIPTION,
            CalendarContract.Events.DTSTART,
            CalendarContract.Events.ALL_DAY
        )

        val selection = "${CalendarContract.Events.DTSTART} >= ? AND ${CalendarContract.Events.DTSTART} <= ?"
        val selectionArgs = arrayOf(now.toString(), oneYearAhead.toString())

        try {
            val cursor = context.contentResolver.query(
                CalendarContract.Events.CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                "${CalendarContract.Events.DTSTART} ASC"
            )

            cursor?.use {
                val titleIdx = it.getColumnIndexOrThrow(CalendarContract.Events.TITLE)
                val descIdx = it.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION)
                val dtIdx = it.getColumnIndexOrThrow(CalendarContract.Events.DTSTART)
                val allDayIdx = it.getColumnIndexOrThrow(CalendarContract.Events.ALL_DAY)

                while (it.moveToNext()) {
                    val rawTitle = it.getString(titleIdx) ?: "Untitled Event"
                    // Skip events that were already created by EthioCal
                    if (rawTitle.startsWith("🇪🇹") && it.getString(descIdx)?.contains("[EthioCal Pro") == true) {
                        continue
                    }

                    val title = rawTitle
                    val desc = it.getString(descIdx) ?: ""
                    val dtStart = it.getLong(dtIdx)
                    val isAllDay = it.getInt(allDayIdx) == 1

                    val cal = Calendar.getInstance().apply { timeInMillis = dtStart }
                    val gYear = cal.get(Calendar.YEAR)
                    val gMonth = cal.get(Calendar.MONTH) + 1
                    val gDay = cal.get(Calendar.DAY_OF_MONTH)
                    val hour = cal.get(Calendar.HOUR_OF_DAY)
                    val minute = cal.get(Calendar.MINUTE)

                    val ethDate = EthiopianCalendarEngine.toEthiopian(GregorianDate(gYear, gMonth, gDay))

                    imported.add(
                        EventEntity(
                            id = 0L,
                            title = title,
                            description = desc,
                            category = "MEETING",
                            ethiopianYear = ethDate.year,
                            ethiopianMonth = ethDate.month,
                            ethiopianDay = ethDate.day,
                            gregorianYear = gYear,
                            gregorianMonth = gMonth,
                            gregorianDay = gDay,
                            hour = hour,
                            minute = minute,
                            isAllDay = isAllDay,
                            recurrence = "NONE",
                            reminderMinutesBefore = 15,
                            colorHex = "#0284C7"
                        )
                    )
                }
            }
        } catch (_: Exception) {
            // Return whatever was imported before error
        }

        return imported
    }
}
