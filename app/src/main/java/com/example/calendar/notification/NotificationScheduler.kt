package com.example.calendar.notification

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.graphics.toColorInt
import com.example.calendar.data.EventEntity
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.EthiopianTimeConverter
import com.example.calendar.engine.GregorianDate
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import java.util.Calendar
import java.util.Locale

/**
 * Manages scheduling, updating, snoozing, and cancelling local event reminders using
 * the Android AlarmManager API, supporting exact alarms, device sleep/idle wakeups,
 * recurring events, custom alert times, and system reboot restoration.
 */
object NotificationScheduler {

    const val CHANNEL_ID = "ethiocal_reminders_channel"
    const val CHANNEL_NAME = "Ethiopian Calendar Reminders"

    const val ACTION_TRIGGER_REMINDER = "com.example.calendar.ACTION_TRIGGER_REMINDER"
    const val ACTION_MARK_COMPLETED = "com.example.calendar.ACTION_MARK_COMPLETED"
    const val ACTION_SNOOZE_REMINDER = "com.example.calendar.ACTION_SNOOZE_REMINDER"
    const val ACTION_TEST_REMINDER = "com.example.calendar.ACTION_TEST_REMINDER"

    const val EXTRA_EVENT_ID = "extra_event_id"
    const val EXTRA_EVENT_TITLE = "extra_event_title"
    const val EXTRA_EVENT_DESC = "extra_event_desc"
    const val EXTRA_EVENT_CATEGORY = "extra_event_category"
    const val EXTRA_EVENT_COLOR = "extra_event_color"
    const val EXTRA_EVENT_ETHIOPIAN_DATE = "extra_event_ethiopian_date"
    const val EXTRA_EVENT_TIME = "extra_event_time"
    const val EXTRA_IS_ALL_DAY = "extra_is_all_day"
    const val EXTRA_RECURRENCE = "extra_recurrence"
    const val EXTRA_SNOOZE_MINUTES = "extra_snooze_minutes"

    /**
     * Initializes the notification channel on Android 8.0 (API 26) and above.
     */
    fun initNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for Ethiopian Calendar events, tasks, and holiday reminders"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 300, 200, 300)
                enableLights(true)
                lightColor = "#E6A817".toColorInt()
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * Checks whether exact alarms can be scheduled on Android 12 (API 31) and above.
     */
    fun canScheduleExactAlarms(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            alarmManager?.canScheduleExactAlarms() ?: false
        } else {
            true
        }
    }

    /**
     * Stable, non-colliding integer request code for PendingIntents based on event ID.
     */
    fun getRequestCode(eventId: Long): Int {
        return (eventId and 0x7FFFFFFF).toInt().let { if (it == 0) 1001 else it }
    }

    fun getNotificationId(eventId: Long): Int = getRequestCode(eventId)

    /**
     * Calculates the next upcoming trigger timestamp in UTC/epoch millis for an event,
     * taking into account its custom alert time (hour/minute), reminder offset, and recurrence rule.
     */
    fun calculateNextTriggerTime(event: EventEntity, nowMillis: Long = System.currentTimeMillis()): Long? {
        if (event.reminderMinutesBefore < 0 || event.isCompleted) return null

        val targetHour = if (event.hour in 0..23) event.hour else 9
        val targetMinute = if (event.minute in 0..59) event.minute else 0
        val offsetMins = event.reminderMinutesBefore

        return when (event.recurrence) {
            "NONE" -> {
                val cal = Calendar.getInstance().apply {
                    set(Calendar.YEAR, event.gregorianYear)
                    set(Calendar.MONTH, event.gregorianMonth - 1)
                    set(Calendar.DAY_OF_MONTH, event.gregorianDay)
                    set(Calendar.HOUR_OF_DAY, targetHour)
                    set(Calendar.MINUTE, targetMinute)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                    add(Calendar.MINUTE, -offsetMins)
                }
                val trigger = cal.timeInMillis
                if (trigger > nowMillis) trigger else null
            }
            "DAILY" -> {
                // Step day by day from today until (occurrence - offset) > nowMillis
                val maxDaysLookahead = (offsetMins / 1440) + 3
                for (dayShift in 0..maxDaysLookahead) {
                    val cal = Calendar.getInstance().apply {
                        timeInMillis = nowMillis
                        add(Calendar.DAY_OF_YEAR, dayShift)
                        set(Calendar.HOUR_OF_DAY, targetHour)
                        set(Calendar.MINUTE, targetMinute)
                        set(Calendar.SECOND, 0)
                        set(Calendar.MILLISECOND, 0)
                        add(Calendar.MINUTE, -offsetMins)
                    }
                    if (cal.timeInMillis > nowMillis) {
                        return cal.timeInMillis
                    }
                }
                null
            }
            "WEEKLY" -> {
                val origCal = Calendar.getInstance().apply {
                    set(Calendar.YEAR, event.gregorianYear)
                    set(Calendar.MONTH, event.gregorianMonth - 1)
                    set(Calendar.DAY_OF_MONTH, event.gregorianDay)
                }
                val targetDow = origCal.get(Calendar.DAY_OF_WEEK)

                // Find base candidate occurrence day (do NOT subtract offset before computing weekday delta)
                val baseEventCal = Calendar.getInstance().apply {
                    timeInMillis = nowMillis
                    set(Calendar.HOUR_OF_DAY, targetHour)
                    set(Calendar.MINUTE, targetMinute)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                val initialDaysToAdd = (targetDow - baseEventCal.get(Calendar.DAY_OF_WEEK) + 7) % 7
                baseEventCal.add(Calendar.DAY_OF_YEAR, initialDaysToAdd)

                val maxWeeksLookahead = (offsetMins / (1440 * 7)) + 4
                for (weekShift in 0..maxWeeksLookahead) {
                    val candidate = (baseEventCal.clone() as Calendar).apply {
                        add(Calendar.WEEK_OF_YEAR, weekShift)
                        add(Calendar.MINUTE, -offsetMins)
                    }
                    if (candidate.timeInMillis > nowMillis) {
                        return candidate.timeInMillis
                    }
                }
                null
            }
            "MONTHLY_ETHIOPIAN" -> {
                val todayEth = EthiopianCalendarEngine.todayEthiopian()
                var testYear = todayEth.year
                var testMonth = todayEth.month
                for (step in 0..24) {
                    val maxDays = EthiopianDate.daysInMonth(testYear, testMonth)
                    val day = event.ethiopianDay.coerceIn(1, maxDays)
                    val gDate = EthiopianCalendarEngine.toGregorian(EthiopianDate(testYear, testMonth, day))
                    val cal = Calendar.getInstance().apply {
                        set(Calendar.YEAR, gDate.year)
                        set(Calendar.MONTH, gDate.month - 1)
                        set(Calendar.DAY_OF_MONTH, gDate.day)
                        set(Calendar.HOUR_OF_DAY, targetHour)
                        set(Calendar.MINUTE, targetMinute)
                        set(Calendar.SECOND, 0)
                        set(Calendar.MILLISECOND, 0)
                        add(Calendar.MINUTE, -offsetMins)
                    }
                    if (cal.timeInMillis > nowMillis) {
                        return cal.timeInMillis
                    }
                    testMonth++
                    if (testMonth > 13) {
                        testMonth = 1
                        testYear++
                    }
                }
                null
            }
            "MONTHLY_GREGORIAN" -> {
                val nowCal = Calendar.getInstance().apply { timeInMillis = nowMillis }
                val baseYear = nowCal.get(Calendar.YEAR)
                val baseMonth = nowCal.get(Calendar.MONTH)
                for (monthShift in 0..24) {
                    val cal = Calendar.getInstance().apply {
                        set(Calendar.YEAR, baseYear)
                        set(Calendar.MONTH, baseMonth)
                        set(Calendar.DAY_OF_MONTH, 1)
                        add(Calendar.MONTH, monthShift)
                        val maxDay = getActualMaximum(Calendar.DAY_OF_MONTH)
                        set(Calendar.DAY_OF_MONTH, event.gregorianDay.coerceIn(1, maxDay))
                        set(Calendar.HOUR_OF_DAY, targetHour)
                        set(Calendar.MINUTE, targetMinute)
                        set(Calendar.SECOND, 0)
                        set(Calendar.MILLISECOND, 0)
                        add(Calendar.MINUTE, -offsetMins)
                    }
                    if (cal.timeInMillis > nowMillis) {
                        return cal.timeInMillis
                    }
                }
                null
            }
            "YEARLY_ETHIOPIAN" -> {
                val todayEth = EthiopianCalendarEngine.todayEthiopian()
                var testYear = todayEth.year
                for (step in 0..5) {
                    val maxDays = EthiopianDate.daysInMonth(testYear, event.ethiopianMonth)
                    val day = event.ethiopianDay.coerceIn(1, maxDays)
                    val gDate = EthiopianCalendarEngine.toGregorian(EthiopianDate(testYear, event.ethiopianMonth, day))
                    val cal = Calendar.getInstance().apply {
                        set(Calendar.YEAR, gDate.year)
                        set(Calendar.MONTH, gDate.month - 1)
                        set(Calendar.DAY_OF_MONTH, gDate.day)
                        set(Calendar.HOUR_OF_DAY, targetHour)
                        set(Calendar.MINUTE, targetMinute)
                        set(Calendar.SECOND, 0)
                        set(Calendar.MILLISECOND, 0)
                        add(Calendar.MINUTE, -offsetMins)
                    }
                    if (cal.timeInMillis > nowMillis) {
                        return cal.timeInMillis
                    }
                    testYear++
                }
                null
            }
            "YEARLY_GREGORIAN" -> {
                val nowCal = Calendar.getInstance().apply { timeInMillis = nowMillis }
                var testYear = nowCal.get(Calendar.YEAR)
                for (step in 0..5) {
                    val cal = Calendar.getInstance().apply {
                        set(Calendar.YEAR, testYear)
                        set(Calendar.MONTH, event.gregorianMonth - 1)
                        set(Calendar.DAY_OF_MONTH, 1)
                        val maxDay = getActualMaximum(Calendar.DAY_OF_MONTH)
                        set(Calendar.DAY_OF_MONTH, event.gregorianDay.coerceIn(1, maxDay))
                        set(Calendar.HOUR_OF_DAY, targetHour)
                        set(Calendar.MINUTE, targetMinute)
                        set(Calendar.SECOND, 0)
                        set(Calendar.MILLISECOND, 0)
                        add(Calendar.MINUTE, -offsetMins)
                    }
                    if (cal.timeInMillis > nowMillis) {
                        return cal.timeInMillis
                    }
                    testYear++
                }
                null
            }
            else -> {
                val cal = Calendar.getInstance().apply {
                    set(Calendar.YEAR, event.gregorianYear)
                    set(Calendar.MONTH, event.gregorianMonth - 1)
                    set(Calendar.DAY_OF_MONTH, event.gregorianDay)
                    set(Calendar.HOUR_OF_DAY, targetHour)
                    set(Calendar.MINUTE, targetMinute)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                    add(Calendar.MINUTE, -offsetMins)
                }
                val trigger = cal.timeInMillis
                if (trigger > nowMillis) trigger else null
            }
        }
    }

    /**
     * Returns a formatted summary of the scheduled alert date & time (including Ethiopian clock)
     * for display in dialogs and event cards, or null if no future reminder is active.
     */
    fun formatScheduledAlertSummary(
        event: EventEntity,
        lang: AppLanguage = AppLanguage.AMHARIC,
        nowMillis: Long = System.currentTimeMillis()
    ): String? {
        val triggerMillis = calculateNextTriggerTime(event, nowMillis) ?: return null
        return formatTimestampSummary(triggerMillis, lang)
    }

    fun formatTimestampSummary(
        timestampMillis: Long,
        lang: AppLanguage = AppLanguage.AMHARIC
    ): String {
        val cal = Calendar.getInstance().apply { timeInMillis = timestampMillis }
        val gYear = cal.get(Calendar.YEAR)
        val gMonth = cal.get(Calendar.MONTH) + 1
        val gDay = cal.get(Calendar.DAY_OF_MONTH)
        val hour24 = cal.get(Calendar.HOUR_OF_DAY)
        val minute = cal.get(Calendar.MINUTE)

        val ethDate = EthiopianCalendarEngine.toEthiopian(GregorianDate(gYear, gMonth, gDay))
        val ethMonthName = LocaleStrings.getMonthName(ethDate.month, lang)
        val ethTime = EthiopianTimeConverter.gregorianToEthiopian(hour24, minute)
        val amPm = if (hour24 < 12) "AM" else "PM"
        val hour12 = when {
            hour24 == 0 -> 12
            hour24 > 12 -> hour24 - 12
            else -> hour24
        }
        val clockStr = String.format(Locale.US, "%d:%02d %s", hour12, minute, amPm)
        return "$ethMonthName ${ethDate.day} • $clockStr (${ethTime.period.amharic} ${ethTime.hour}:${String.format(Locale.US, "%02d", ethTime.minute)})"
    }

    /**
     * Formats a concise 12-hour alert clock string for badges (e.g., "08:45 AM").
     */
    fun formatClock12h(hour24: Int, minute: Int): String {
        val safeHour = hour24.coerceIn(0, 23)
        val safeMinute = minute.coerceIn(0, 59)
        val amPm = if (safeHour < 12) "AM" else "PM"
        val h12 = when {
            safeHour == 0 -> 12
            safeHour > 12 -> safeHour - 12
            else -> safeHour
        }
        return String.format(Locale.US, "%d:%02d %s", h12, safeMinute, amPm)
    }

    /**
     * Formats a human-readable reminder lead-time offset label (e.g. "At time", "15m", "3h", "2d").
     */
    fun formatReminderOffsetShort(minutesBefore: Int): String {
        return when {
            minutesBefore < 0 -> "Off"
            minutesBefore == 0 -> "በሰዓቱ"
            minutesBefore % 1440 == 0 -> "${minutesBefore / 1440}ቀ"
            minutesBefore % 60 == 0 -> "${minutesBefore / 60}ሰ"
            else -> "${minutesBefore}ደ"
        }
    }

    /**
     * Counts how many events currently have a future scheduled notification alert.
     */
    fun countActiveScheduledEvents(events: List<EventEntity>, nowMillis: Long = System.currentTimeMillis()): Int {
        return events.count { calculateNextTriggerTime(it, nowMillis) != null }
    }

    /**
     * Schedules a local notification alert using Android AlarmManager API.
     */
    fun scheduleEventReminder(context: Context, event: EventEntity) {
        if (event.reminderMinutesBefore < 0 || event.isCompleted) return

        val triggerTime = calculateNextTriggerTime(event) ?: return
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return

        initNotificationChannel(context)

        val monthEn = LocaleStrings.getMonthName(event.ethiopianMonth, AppLanguage.ENGLISH)
        val monthAm = LocaleStrings.getMonthName(event.ethiopianMonth, AppLanguage.AMHARIC)
        val formattedEthDate = "$monthEn ($monthAm) ${event.ethiopianDay}, ${event.ethiopianYear} E.C."
        val formattedTime = if (event.isAllDay) {
            "All Day (${formatClock12h(event.hour, event.minute)} Alert)"
        } else {
            val ethTime = EthiopianTimeConverter.gregorianToEthiopian(event.hour, event.minute)
            "${formatClock12h(event.hour, event.minute)} • ${ethTime.formatted()}"
        }

        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_TRIGGER_REMINDER
            putExtra(EXTRA_EVENT_ID, event.id)
            putExtra(EXTRA_EVENT_TITLE, event.title)
            putExtra(EXTRA_EVENT_DESC, event.description)
            putExtra(EXTRA_EVENT_CATEGORY, event.category)
            putExtra(EXTRA_EVENT_COLOR, event.colorHex)
            putExtra(EXTRA_EVENT_ETHIOPIAN_DATE, formattedEthDate)
            putExtra(EXTRA_EVENT_TIME, formattedTime)
            putExtra(EXTRA_IS_ALL_DAY, event.isAllDay)
            putExtra(EXTRA_RECURRENCE, event.recurrence)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            getRequestCode(event.id),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        scheduleAlarmAt(alarmManager, triggerTime, pendingIntent)
    }

    /**
     * Schedules a snoozed notification for [snoozeMinutes] from now.
     */
    fun scheduleSnoozeReminder(
        context: Context,
        eventId: Long,
        title: String,
        desc: String,
        category: String,
        ethDate: String,
        timeStr: String,
        colorHex: String,
        isAllDay: Boolean,
        snoozeMinutes: Int = 10
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        initNotificationChannel(context)

        val triggerTime = System.currentTimeMillis() + (snoozeMinutes * 60_000L)
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_TRIGGER_REMINDER
            putExtra(EXTRA_EVENT_ID, eventId)
            putExtra(EXTRA_EVENT_TITLE, title)
            putExtra(EXTRA_EVENT_DESC, desc)
            putExtra(EXTRA_EVENT_CATEGORY, category)
            putExtra(EXTRA_EVENT_COLOR, colorHex)
            putExtra(EXTRA_EVENT_ETHIOPIAN_DATE, ethDate)
            putExtra(EXTRA_EVENT_TIME, timeStr)
            putExtra(EXTRA_IS_ALL_DAY, isAllDay)
        }

        val requestCode = if (eventId > 0L) getRequestCode(eventId) else 888888
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        scheduleAlarmAt(alarmManager, triggerTime, pendingIntent)
    }

    /**
     * Cancels any scheduled AlarmManager reminder for the given event ID.
     */
    fun cancelEventReminder(context: Context, eventId: Long) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_TRIGGER_REMINDER
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            getRequestCode(eventId),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }

    /**
     * Re-registers all active, uncompleted events with reminders enabled.
     */
    fun rescheduleAllActiveEvents(context: Context, events: List<EventEntity>) {
        for (event in events) {
            if (!event.isCompleted && event.reminderMinutesBefore >= 0) {
                scheduleEventReminder(context, event)
            }
        }
    }

    /**
     * Cancels all scheduled alarms for a list of events.
     */
    fun cancelAllReminders(context: Context, events: List<EventEntity>) {
        for (event in events) {
            cancelEventReminder(context, event.id)
        }
    }

    /**
     * Schedules a test notification to fire via AlarmManager after [delaySeconds].
     */
    fun scheduleTestReminder(context: Context, delaySeconds: Long = 2) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        initNotificationChannel(context)
        val triggerTime = System.currentTimeMillis() + (delaySeconds * 1000)

        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_TEST_REMINDER
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            999999,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        scheduleAlarmAt(alarmManager, triggerTime, pendingIntent)
    }

    private fun scheduleAlarmAt(
        alarmManager: AlarmManager,
        triggerTime: Long,
        pendingIntent: PendingIntent
    ) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
                } else {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
                }
            } else {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
            }
        } catch (_: SecurityException) {
            try {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
            } catch (_: Exception) {
            }
        }
    }
}
