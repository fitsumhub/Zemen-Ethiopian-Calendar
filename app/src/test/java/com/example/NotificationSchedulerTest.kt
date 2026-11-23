package com.example

import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import com.example.calendar.data.EventEntity
import com.example.calendar.notification.AlarmReceiver
import com.example.calendar.notification.NotificationScheduler
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.util.Calendar

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class NotificationSchedulerTest {

    private lateinit var context: Context
    private lateinit var alarmManager: AlarmManager
    private lateinit var notificationManager: NotificationManager

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        NotificationScheduler.initNotificationChannel(context)
    }

    @Test
    fun `notification channel is created properly`() {
        val channel = notificationManager.getNotificationChannel(NotificationScheduler.CHANNEL_ID)
        assertNotNull(channel)
        assertEquals(NotificationScheduler.CHANNEL_NAME, channel.name)
        assertEquals(NotificationManager.IMPORTANCE_HIGH, channel.importance)
        assertTrue(channel.shouldVibrate())
    }

    @Test
    fun `calculateNextTriggerTime returns null for past non-recurring event`() {
        val pastEvent = EventEntity(
            id = 1L,
            title = "Past Event",
            ethiopianYear = 2016,
            ethiopianMonth = 1,
            ethiopianDay = 1,
            gregorianYear = 2023,
            gregorianMonth = 9,
            gregorianDay = 12,
            hour = 8,
            minute = 0,
            isAllDay = false,
            recurrence = "NONE",
            reminderMinutesBefore = 15
        )
        val trigger = NotificationScheduler.calculateNextTriggerTime(pastEvent, nowMillis = System.currentTimeMillis())
        assertNull(trigger)
    }

    @Test
    fun `calculateNextTriggerTime returns correct time for future event`() {
        val now = Calendar.getInstance()
        val futureCal = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 5)
            set(Calendar.HOUR_OF_DAY, 14)
            set(Calendar.MINUTE, 30)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val futureEvent = EventEntity(
            id = 2L,
            title = "Future Conference",
            ethiopianYear = 2019,
            ethiopianMonth = 2,
            ethiopianDay = 10,
            gregorianYear = futureCal.get(Calendar.YEAR),
            gregorianMonth = futureCal.get(Calendar.MONTH) + 1,
            gregorianDay = futureCal.get(Calendar.DAY_OF_MONTH),
            hour = 14,
            minute = 30,
            isAllDay = false,
            recurrence = "NONE",
            reminderMinutesBefore = 30
        )

        val trigger = NotificationScheduler.calculateNextTriggerTime(futureEvent, nowMillis = now.timeInMillis)
        assertNotNull(trigger)
        // Should be exactly 30 minutes before 14:30 = 14:00
        val expectedCal = Calendar.getInstance().apply {
            timeInMillis = futureCal.timeInMillis
            add(Calendar.MINUTE, -30)
        }
        assertEquals(expectedCal.timeInMillis, trigger)
    }

    @Test
    fun `calculateNextTriggerTime computes next occurrence for daily recurring event`() {
        val now = Calendar.getInstance()
        val dailyEvent = EventEntity(
            id = 3L,
            title = "Daily Prayer",
            ethiopianYear = 2018,
            ethiopianMonth = 1,
            ethiopianDay = 1,
            gregorianYear = 2025,
            gregorianMonth = 9,
            gregorianDay = 11,
            hour = 18,
            minute = 0,
            isAllDay = false,
            recurrence = "DAILY",
            reminderMinutesBefore = 15
        )

        val trigger = NotificationScheduler.calculateNextTriggerTime(dailyEvent, nowMillis = now.timeInMillis)
        assertNotNull(trigger)
        assertTrue("Trigger time must be in the future", trigger!! > now.timeInMillis)
    }

    @Test
    fun `scheduleEventReminder registers alarm with AlarmManager`() {
        val futureCal = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 2)
            set(Calendar.HOUR_OF_DAY, 10)
            set(Calendar.MINUTE, 0)
        }

        val event = EventEntity(
            id = 100L,
            title = "Meeting with Council",
            description = "Discuss Ethiopian new year events",
            category = "MEETING",
            ethiopianYear = 2019,
            ethiopianMonth = 2,
            ethiopianDay = 15,
            gregorianYear = futureCal.get(Calendar.YEAR),
            gregorianMonth = futureCal.get(Calendar.MONTH) + 1,
            gregorianDay = futureCal.get(Calendar.DAY_OF_MONTH),
            hour = 10,
            minute = 0,
            isAllDay = false,
            recurrence = "NONE",
            reminderMinutesBefore = 15
        )

        NotificationScheduler.scheduleEventReminder(context, event)

        val shadowAlarm = shadowOf(alarmManager)
        val scheduledAlarms = shadowAlarm.scheduledAlarms
        assertTrue("At least one alarm must be scheduled in AlarmManager", scheduledAlarms.isNotEmpty())

        @Suppress("DEPRECATION")
        val matchedAlarm = scheduledAlarms.firstOrNull { it.operation != null }
        assertNotNull("Scheduled alarm must have an operation PendingIntent", matchedAlarm)

        // Cancel test
        NotificationScheduler.cancelEventReminder(context, 100L)
    }

    @Test
    fun `AlarmReceiver shows notification when reminder triggers`() {
        val receiver = AlarmReceiver()
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = NotificationScheduler.ACTION_TRIGGER_REMINDER
            putExtra(NotificationScheduler.EXTRA_EVENT_ID, 42L)
            putExtra(NotificationScheduler.EXTRA_EVENT_TITLE, "የቡና ሰዓት (Coffee Time)")
            putExtra(NotificationScheduler.EXTRA_EVENT_DESC, "ከሰዓት 10 ሰዓት")
            putExtra(NotificationScheduler.EXTRA_EVENT_CATEGORY, "TASK")
            putExtra(NotificationScheduler.EXTRA_EVENT_ETHIOPIAN_DATE, "ጥቅምት 10፣ 2019 ዓ.ም")
            putExtra(NotificationScheduler.EXTRA_EVENT_TIME, "10:00")
            putExtra(NotificationScheduler.EXTRA_IS_ALL_DAY, false)
        }

        receiver.onReceive(context, intent)

        val shadowNotificationManager = shadowOf(notificationManager)
        val notifications = shadowNotificationManager.allNotifications
        assertTrue("NotificationManager must have posted a notification", notifications.isNotEmpty())

        val notification = notifications.first()
        assertNotNull(notification)
        val extras = notification.extras
        val title = extras.getString("android.title")
        assertNotNull(title)
        assertTrue("Notification title should contain event title", title!!.contains("የቡና ሰዓት"))
    }

    @Test
    fun `AlarmReceiver handles test reminder action`() {
        val receiver = AlarmReceiver()
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = NotificationScheduler.ACTION_TEST_REMINDER
        }

        receiver.onReceive(context, intent)

        val shadowNotificationManager = shadowOf(notificationManager)
        val testNotification = shadowNotificationManager.allNotifications.firstOrNull {
            it.extras.getString("android.title")?.contains("EthioCal Pro") == true
        }
        assertNotNull("Test notification must be posted", testNotification)
    }

    @Test
    fun `calculateNextTriggerTime supports custom reminder offsets like 45 mins and 2 days`() {
        val futureCal = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 10)
            set(Calendar.HOUR_OF_DAY, 15)
            set(Calendar.MINUTE, 15)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val nowMillis = Calendar.getInstance().timeInMillis

        val custom45Event = EventEntity(
            id = 201L,
            title = "Custom 45m",
            ethiopianYear = 2019,
            ethiopianMonth = 3,
            ethiopianDay = 5,
            gregorianYear = futureCal.get(Calendar.YEAR),
            gregorianMonth = futureCal.get(Calendar.MONTH) + 1,
            gregorianDay = futureCal.get(Calendar.DAY_OF_MONTH),
            hour = 15,
            minute = 15,
            isAllDay = false,
            recurrence = "NONE",
            reminderMinutesBefore = 45
        )
        val trigger45 = NotificationScheduler.calculateNextTriggerTime(custom45Event, nowMillis)
        assertEquals(futureCal.timeInMillis - 45 * 60_000L, trigger45)

        val custom2DaysEvent = custom45Event.copy(id = 202L, reminderMinutesBefore = 2880)
        val trigger2d = NotificationScheduler.calculateNextTriggerTime(custom2DaysEvent, nowMillis)
        assertEquals(futureCal.timeInMillis - 2880 * 60_000L, trigger2d)
    }

    @Test
    fun `calculateNextTriggerTime handles DAILY recurrence with 1 day advance reminder`() {
        val nowCal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 10)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val dailyEvent = EventEntity(
            id = 203L,
            title = "Daily 8 AM with 24h prior alert",
            ethiopianYear = 2019,
            ethiopianMonth = 1,
            ethiopianDay = 1,
            gregorianYear = nowCal.get(Calendar.YEAR),
            gregorianMonth = nowCal.get(Calendar.MONTH) + 1,
            gregorianDay = nowCal.get(Calendar.DAY_OF_MONTH),
            hour = 8,
            minute = 0,
            isAllDay = true,
            recurrence = "DAILY",
            reminderMinutesBefore = 1440
        )

        val trigger = NotificationScheduler.calculateNextTriggerTime(dailyEvent, nowCal.timeInMillis)
        assertNotNull(trigger)
        assertTrue("Daily 24h-prior trigger must be strictly in the future", trigger!! > nowCal.timeInMillis)
    }

    @Test
    fun `calculateNextTriggerTime handles WEEKLY recurrence crossing midnight`() {
        // Choose a fixed Wednesday 10:00 AM as "now"
        val nowCal = Calendar.getInstance().apply {
            set(2026, Calendar.NOVEMBER, 18, 10, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        // Weekly event on Thursday 00:10 with 30m reminder -> fires Wednesday 23:40
        val thursdayCal = (nowCal.clone() as Calendar).apply {
            add(Calendar.DAY_OF_YEAR, 1) // Thursday Nov 19
        }
        val weeklyEvent = EventEntity(
            id = 204L,
            title = "Midnight Weekly",
            ethiopianYear = 2019,
            ethiopianMonth = 3,
            ethiopianDay = 10,
            gregorianYear = thursdayCal.get(Calendar.YEAR),
            gregorianMonth = thursdayCal.get(Calendar.MONTH) + 1,
            gregorianDay = thursdayCal.get(Calendar.DAY_OF_MONTH),
            hour = 0,
            minute = 10,
            isAllDay = false,
            recurrence = "WEEKLY",
            reminderMinutesBefore = 30
        )

        val trigger = NotificationScheduler.calculateNextTriggerTime(weeklyEvent, nowCal.timeInMillis)
        assertNotNull(trigger)
        val triggerCal = Calendar.getInstance().apply { timeInMillis = trigger!! }
        assertEquals(Calendar.WEDNESDAY, triggerCal.get(Calendar.DAY_OF_WEEK))
        assertEquals(23, triggerCal.get(Calendar.HOUR_OF_DAY))
        assertEquals(40, triggerCal.get(Calendar.MINUTE))
    }

    @Test
    fun `AlarmReceiver handles snooze action by scheduling future alarm`() {
        val receiver = AlarmReceiver()
        val snoozeIntent = Intent(context, AlarmReceiver::class.java).apply {
            action = NotificationScheduler.ACTION_SNOOZE_REMINDER
            putExtra(NotificationScheduler.EXTRA_EVENT_ID, 77L)
            putExtra(NotificationScheduler.EXTRA_EVENT_TITLE, "Snoozed Event")
            putExtra(NotificationScheduler.EXTRA_SNOOZE_MINUTES, 10)
        }

        val before = System.currentTimeMillis()
        receiver.onReceive(context, snoozeIntent)

        val shadowAlarm = shadowOf(alarmManager)
        val snoozedAlarm = shadowAlarm.scheduledAlarms.lastOrNull()
        assertNotNull("Snoozed alarm should be scheduled", snoozedAlarm)
        @Suppress("DEPRECATION")
        assertTrue(
            "Snoozed alarm trigger should be ~10 minutes ahead",
            snoozedAlarm!!.triggerAtTime >= before + 9 * 60_000L
        )
    }

    @Test
    fun `clock and offset formatting helpers return expected strings`() {
        assertEquals("12:05 AM", NotificationScheduler.formatClock12h(0, 5))
        assertEquals("9:30 AM", NotificationScheduler.formatClock12h(9, 30))
        assertEquals("12:00 PM", NotificationScheduler.formatClock12h(12, 0))
        assertEquals("8:45 PM", NotificationScheduler.formatClock12h(20, 45))

        assertEquals("በሰዓቱ", NotificationScheduler.formatReminderOffsetShort(0))
        assertEquals("45ደ", NotificationScheduler.formatReminderOffsetShort(45))
        assertEquals("3ሰ", NotificationScheduler.formatReminderOffsetShort(180))
        assertEquals("2ቀ", NotificationScheduler.formatReminderOffsetShort(2880))
    }
}
