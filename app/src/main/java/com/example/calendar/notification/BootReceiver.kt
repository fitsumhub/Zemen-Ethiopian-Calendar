package com.example.calendar.notification

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.example.calendar.data.AppDatabase
import com.example.calendar.data.UserPreferencesRepository
import com.example.calendar.widget.EthioCalWidgetProvider
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.launch

/**
 * BroadcastReceiver triggered when the device boots, system time or timezone changes,
 * or when the application is updated. Restores all active AlarmManager alarms.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_TIME_CHANGED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == android.app.AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED) {

            val pendingResult = goAsync()
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val prefsRepo = UserPreferencesRepository(context)
                    val settings = prefsRepo.userSettingsFlow.firstOrNull() ?: UserPreferencesRepository.UserSettings()
                    if (settings.notificationsEnabled) {
                        val db = AppDatabase.getDatabase(context)
                        val events = db.eventDao().getAllEvents().firstOrNull() ?: emptyList()
                        NotificationScheduler.rescheduleAllActiveEvents(context, events)
                    }
                    EthioCalWidgetProvider.updateAllWidgets(context)
                } catch (_: Exception) {
                    // Fail gracefully
                } finally {
                    pendingResult.finish()
                }
            }
        }
    }
}
