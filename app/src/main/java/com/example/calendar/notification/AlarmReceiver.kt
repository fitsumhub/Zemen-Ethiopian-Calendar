package com.example.calendar.notification

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import androidx.core.app.NotificationCompat
import androidx.core.graphics.toColorInt
import com.example.MainActivity
import com.example.R
import com.example.calendar.data.AppDatabase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * BroadcastReceiver triggered by Android AlarmManager when a scheduled event reminder fires.
 * Handles displaying heads-up notifications, snoozing reminders, marking events complete
 * from notification actions, and rescheduling recurring events.
 */
class AlarmReceiver : BroadcastReceiver() {

    companion object {
        const val CHANNEL_ID = NotificationScheduler.CHANNEL_ID
        const val CHANNEL_NAME = NotificationScheduler.CHANNEL_NAME
        const val ACTION_TRIGGER_REMINDER = NotificationScheduler.ACTION_TRIGGER_REMINDER
        const val ACTION_MARK_COMPLETED = NotificationScheduler.ACTION_MARK_COMPLETED
        const val ACTION_SNOOZE_REMINDER = NotificationScheduler.ACTION_SNOOZE_REMINDER
        const val ACTION_TEST_REMINDER = NotificationScheduler.ACTION_TEST_REMINDER
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: ACTION_TRIGGER_REMINDER

        // Handle Mark Completed action directly from notification action button
        if (action == ACTION_MARK_COMPLETED) {
            val eventId = intent.getLongExtra(NotificationScheduler.EXTRA_EVENT_ID, -1L)
            if (eventId != -1L) {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                notificationManager?.cancel(NotificationScheduler.getNotificationId(eventId))

                val pendingResult = goAsync()
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val db = AppDatabase.getDatabase(context)
                        val event = db.eventDao().getEventById(eventId)
                        if (event != null) {
                            db.eventDao().updateEvent(event.copy(isCompleted = true))
                            NotificationScheduler.cancelEventReminder(context, eventId)
                        }
                    } finally {
                        pendingResult.finish()
                    }
                }
            }
            return
        }

        // Handle Snooze action (default 10 minutes)
        if (action == ACTION_SNOOZE_REMINDER) {
            val eventId = intent.getLongExtra(NotificationScheduler.EXTRA_EVENT_ID, 0L)
            val title = intent.getStringExtra(NotificationScheduler.EXTRA_EVENT_TITLE) ?: "የቀን መቁጠሪያ ማሳሰቢያ"
            val desc = intent.getStringExtra(NotificationScheduler.EXTRA_EVENT_DESC) ?: ""
            val category = intent.getStringExtra(NotificationScheduler.EXTRA_EVENT_CATEGORY) ?: "TASK"
            val ethDate = intent.getStringExtra(NotificationScheduler.EXTRA_EVENT_ETHIOPIAN_DATE) ?: ""
            val timeStr = intent.getStringExtra(NotificationScheduler.EXTRA_EVENT_TIME) ?: ""
            val colorHex = intent.getStringExtra(NotificationScheduler.EXTRA_EVENT_COLOR) ?: "#E6A817"
            val isAllDay = intent.getBooleanExtra(NotificationScheduler.EXTRA_IS_ALL_DAY, true)
            val snoozeMins = intent.getIntExtra(NotificationScheduler.EXTRA_SNOOZE_MINUTES, 10)

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.cancel(NotificationScheduler.getNotificationId(eventId))

            NotificationScheduler.scheduleSnoozeReminder(
                context = context,
                eventId = eventId,
                title = title,
                desc = desc,
                category = category,
                ethDate = ethDate,
                timeStr = timeStr,
                colorHex = colorHex,
                isAllDay = isAllDay,
                snoozeMinutes = snoozeMins
            )
            return
        }

        // Handle Test Reminder triggered via AlarmManager
        if (action == ACTION_TEST_REMINDER) {
            showTestNotification(context)
            return
        }

        // Trigger Event Reminder
        val eventId = intent.getLongExtra(NotificationScheduler.EXTRA_EVENT_ID, 0L)
        val title = intent.getStringExtra(NotificationScheduler.EXTRA_EVENT_TITLE) ?: "የቀን መቁጠሪያ ማሳሰቢያ"
        val desc = intent.getStringExtra(NotificationScheduler.EXTRA_EVENT_DESC) ?: ""
        val category = intent.getStringExtra(NotificationScheduler.EXTRA_EVENT_CATEGORY) ?: "TASK"
        val ethDate = intent.getStringExtra(NotificationScheduler.EXTRA_EVENT_ETHIOPIAN_DATE) ?: ""
        val timeStr = intent.getStringExtra(NotificationScheduler.EXTRA_EVENT_TIME) ?: ""
        val colorHex = intent.getStringExtra(NotificationScheduler.EXTRA_EVENT_COLOR) ?: "#E6A817"
        val isAllDay = intent.getBooleanExtra(NotificationScheduler.EXTRA_IS_ALL_DAY, true)

        showEventNotification(
            context = context,
            eventId = eventId,
            title = title,
            desc = desc,
            category = category,
            ethDate = ethDate,
            timeStr = timeStr,
            colorHex = colorHex,
            isAllDay = isAllDay
        )

        // Reschedule recurring events if applicable
        if (eventId > 0L) {
            val pendingResult = goAsync()
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val db = AppDatabase.getDatabase(context)
                    val event = db.eventDao().getEventById(eventId)
                    if (event != null && !event.isCompleted && event.recurrence != "NONE") {
                        NotificationScheduler.scheduleEventReminder(context, event)
                    }
                } finally {
                    pendingResult.finish()
                }
            }
        }
    }

    private fun showEventNotification(
        context: Context,
        eventId: Long,
        title: String,
        desc: String,
        category: String,
        ethDate: String,
        timeStr: String,
        colorHex: String,
        isAllDay: Boolean
    ) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        NotificationScheduler.initNotificationChannel(context)

        val parsedColor = try {
            colorHex.toColorInt()
        } catch (_: Exception) {
            "#E6A817".toColorInt()
        }

        val categoryIcon = getCategoryEmoji(category)
        val categoryLabel = getCategoryLabel(category)

        // Intent to open app directly to events
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("navigate_to", "EVENTS")
            putExtra("event_id", eventId)
        }
        val openPendingIntent = PendingIntent.getActivity(
            context,
            NotificationScheduler.getRequestCode(eventId),
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Intent to snooze for 10 minutes
        val snoozeIntent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_SNOOZE_REMINDER
            putExtra(NotificationScheduler.EXTRA_EVENT_ID, eventId)
            putExtra(NotificationScheduler.EXTRA_EVENT_TITLE, title)
            putExtra(NotificationScheduler.EXTRA_EVENT_DESC, desc)
            putExtra(NotificationScheduler.EXTRA_EVENT_CATEGORY, category)
            putExtra(NotificationScheduler.EXTRA_EVENT_ETHIOPIAN_DATE, ethDate)
            putExtra(NotificationScheduler.EXTRA_EVENT_TIME, timeStr)
            putExtra(NotificationScheduler.EXTRA_EVENT_COLOR, colorHex)
            putExtra(NotificationScheduler.EXTRA_IS_ALL_DAY, isAllDay)
            putExtra(NotificationScheduler.EXTRA_SNOOZE_MINUTES, 10)
        }
        val snoozePendingIntent = PendingIntent.getBroadcast(
            context,
            NotificationScheduler.getRequestCode(eventId) + 300000,
            snoozeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Intent to mark completed from notification
        val markDoneIntent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_MARK_COMPLETED
            putExtra(NotificationScheduler.EXTRA_EVENT_ID, eventId)
        }
        val markDonePendingIntent = PendingIntent.getBroadcast(
            context,
            NotificationScheduler.getRequestCode(eventId) + 500000,
            markDoneIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val contentText = buildString {
            if (ethDate.isNotBlank()) append("📅 $ethDate")
            if (timeStr.isNotBlank()) append(" • ⏰ $timeStr")
        }.ifEmpty { desc }

        val bigText = buildString {
            append("📌 ምድብ (Category): $categoryLabel\n")
            if (ethDate.isNotBlank()) append("📅 ቀን (Date): $ethDate\n")
            append("⏰ ሰዓት (Time): ${if (isAllDay && timeStr.isBlank()) "ሙሉ ቀን (All Day)" else timeStr}\n")
            if (desc.isNotBlank()) {
                append("\n📝 $desc")
            }
        }

        val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(parsedColor)
            .setContentTitle("$categoryIcon $title")
            .setContentText(contentText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(bigText))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_EVENT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setSound(defaultSoundUri)
            .setVibrate(longArrayOf(0, 300, 200, 300))
            .setContentIntent(openPendingIntent)
            .setAutoCancel(true)
            .addAction(
                android.R.drawable.ic_lock_idle_alarm,
                "Snooze 10m (10ደ አቆይ)",
                snoozePendingIntent
            )
            .addAction(
                android.R.drawable.checkbox_on_background,
                "Done (ተጠናቋል)",
                markDonePendingIntent
            )
            .build()

        notificationManager.notify(NotificationScheduler.getNotificationId(eventId), notification)
    }

    private fun showTestNotification(context: Context) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        NotificationScheduler.initNotificationChannel(context)

        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("navigate_to", "EVENTS")
        }
        val openPendingIntent = PendingIntent.getActivity(
            context,
            999998,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor("#E6A817".toColorInt())
            .setContentTitle("🇪🇹 EthioCal Pro Reminder Test")
            .setContentText("AlarmManager reminder alerts are working successfully!")
            .setStyle(
                NotificationCompat.BigTextStyle().bigText(
                    "🔔 Reminder System Tested Successfully!\n\n" +
                    "Your scheduled Ethiopian calendar events, meetings, and holiday alerts will arrive on time via AlarmManager."
                )
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setSound(defaultSoundUri)
            .setContentIntent(openPendingIntent)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(999999, notification)
    }

    private fun getCategoryEmoji(category: String): String {
        return when (category) {
            "TASK" -> "✅"
            "MEETING" -> "💼"
            "BIRTHDAY" -> "🎂"
            "EXAM" -> "📚"
            "ANNIVERSARY" -> "💍"
            "RELIGIOUS" -> "⛪"
            "CULTURAL" -> "🇪🇹"
            "HOLIDAY" -> "🎉"
            else -> "📌"
        }
    }

    private fun getCategoryLabel(category: String): String {
        return when (category) {
            "TASK" -> "Task (ተግባር)"
            "MEETING" -> "Meeting (ስብሰባ)"
            "BIRTHDAY" -> "Birthday (ልደት)"
            "EXAM" -> "Exam (ፈተና)"
            "ANNIVERSARY" -> "Anniversary (መታሰቢያ)"
            "RELIGIOUS" -> "Religious (ሃይማኖታዊ)"
            "CULTURAL" -> "Cultural (ባህላዊ)"
            "HOLIDAY" -> "Holiday (በዓል)"
            else -> "Other (ሌላ)"
        }
    }
}
