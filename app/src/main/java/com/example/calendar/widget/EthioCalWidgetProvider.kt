package com.example.calendar.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.example.MainActivity
import com.example.R
import com.example.calendar.data.UserPreferencesRepository
import com.example.calendar.engine.BahireHasabCalculator
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianTimeConverter
import com.example.calendar.engine.GeezNumberFormatter
import com.example.calendar.engine.HolidayEngine
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.runBlocking
import java.util.Calendar
import java.util.Locale

/**
 * Dual-Calendar Home Screen Widget Provider supporting:
 * - Simultaneous Ethiopian & Gregorian current date display
 * - Dual numeral display (Standard & Ge'ez numerals)
 * - Ethiopian 12-Hour Clock (daytime/nighttime cycle)
 * - Orthodox fasting / non-fasting status badge
 * - Upcoming holiday & monthly commemorative saint display
 * - Automatic midnight rollover scheduling & user language preference sync
 * - Direct deep-link shortcuts to Calendar, Clock, and Event Creation
 */
class EthioCalWidgetProvider : AppWidgetProvider() {

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleMidnightUpdate(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelMidnightUpdateIfNoWidgets(context)
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
        scheduleMidnightUpdate(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        if (action == Intent.ACTION_TIME_CHANGED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_DATE_CHANGED ||
            action == ACTION_UPDATE_ETHIOCAL_WIDGET
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)

            val mainWidget = ComponentName(context, EthioCalWidgetProvider::class.java)
            val mainIds = appWidgetManager.getAppWidgetIds(mainWidget)
            for (id in mainIds) {
                updateAppWidget(context, appWidgetManager, id)
            }

            val compactWidget = ComponentName(context, EthioCalCompactWidgetProvider::class.java)
            val compactIds = appWidgetManager.getAppWidgetIds(compactWidget)
            for (id in compactIds) {
                EthioCalCompactWidgetProvider.updateAppWidget(context, appWidgetManager, id)
            }

            if (mainIds.isNotEmpty() || compactIds.isNotEmpty()) {
                scheduleMidnightUpdate(context)
            }
        }
    }

    companion object {
        const val ACTION_UPDATE_ETHIOCAL_WIDGET = "com.example.calendar.ACTION_UPDATE_ETHIOCAL_WIDGET"
        private const val MIDNIGHT_ALARM_REQUEST_CODE = 301

        private val GREGORIAN_MONTHS_SHORT = listOf(
            "Jan", "Feb", "Mar", "Apr", "May", "Jun",
            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
        )

        fun gregorianMonthShort(month: Int): String =
            GREGORIAN_MONTHS_SHORT[(month - 1).coerceIn(0, 11)]

        fun resolveLanguage(context: Context): AppLanguage {
            return try {
                val settings = runBlocking {
                    UserPreferencesRepository(context).userSettingsFlow.firstOrNull()
                }
                when (settings?.language) {
                    "AMHARIC" -> AppLanguage.AMHARIC
                    "OROMO" -> AppLanguage.OROMO
                    "TIGRINYA" -> AppLanguage.TIGRINYA
                    "FRENCH" -> AppLanguage.FRENCH
                    "ENGLISH" -> AppLanguage.ENGLISH
                    else -> AppLanguage.ENGLISH
                }
            } catch (_: Exception) {
                AppLanguage.ENGLISH
            }
        }

        fun scheduleMidnightUpdate(context: Context) {
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
                val nextMidnight = Calendar.getInstance().apply {
                    add(Calendar.DAY_OF_YEAR, 1)
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 5)
                    set(Calendar.MILLISECOND, 0)
                }
                val intent = Intent(context, EthioCalWidgetProvider::class.java).apply {
                    action = ACTION_UPDATE_ETHIOCAL_WIDGET
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    MIDNIGHT_ALARM_REQUEST_CODE,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                alarmManager.set(AlarmManager.RTC, nextMidnight.timeInMillis, pendingIntent)
            } catch (_: Exception) {
                // Best-effort midnight rollover alarm
            }
        }

        fun cancelMidnightUpdateIfNoWidgets(context: Context) {
            try {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val mainCount = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, EthioCalWidgetProvider::class.java)
                ).size
                val compactCount = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, EthioCalCompactWidgetProvider::class.java)
                ).size
                if (mainCount == 0 && compactCount == 0) {
                    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
                    val intent = Intent(context, EthioCalWidgetProvider::class.java).apply {
                        action = ACTION_UPDATE_ETHIOCAL_WIDGET
                    }
                    val pendingIntent = PendingIntent.getBroadcast(
                        context,
                        MIDNIGHT_ALARM_REQUEST_CODE,
                        intent,
                        PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
                    )
                    if (pendingIntent != null) {
                        alarmManager.cancel(pendingIntent)
                    }
                }
            } catch (_: Exception) {
                // Ignore cleanup failure
            }
        }

        fun updateAllWidgets(context: Context) {
            val intent = Intent(context, EthioCalWidgetProvider::class.java).apply {
                action = ACTION_UPDATE_ETHIOCAL_WIDGET
            }
            context.sendBroadcast(intent)
        }

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val lang = resolveLanguage(context)
            val isGeezScript = lang == AppLanguage.AMHARIC || lang == AppLanguage.TIGRINYA
            val ethDate = EthiopianCalendarEngine.todayEthiopian()
            val gregDate = EthiopianCalendarEngine.todayGregorian()
            val dow = EthiopianCalendarEngine.getDayOfWeek(ethDate)

            val views = RemoteViews(context.packageName, R.layout.widget_ethiocal)

            // Ethiopian Day (Standard + Ge'ez numerals)
            views.setTextViewText(R.id.widget_eth_day, ethDate.day.toString())
            views.setTextViewText(R.id.widget_geez_day, GeezNumberFormatter.toGeez(ethDate.day))

            // Ethiopian Month & Year
            val monthName = LocaleStrings.getMonthName(ethDate.month, lang)
            val eraSuffix = if (isGeezScript) "ዓ.ም" else "E.C."
            views.setTextViewText(R.id.widget_eth_month_year, "$monthName ${ethDate.year} $eraSuffix")

            // Localized Weekday Name in Header
            val weekdayName = LocaleStrings.getWeekdayLong(dow, lang)
            views.setTextViewText(R.id.widget_weekday, weekdayName)

            // Quick Add button label
            views.setTextViewText(
                R.id.widget_btn_add_event,
                if (isGeezScript) "+ አዲስ" else "+ Add"
            )

            // Real-time Ethiopian 12-hour clock
            val nowCal = Calendar.getInstance()
            val gHour = nowCal.get(Calendar.HOUR_OF_DAY)
            val gMinute = nowCal.get(Calendar.MINUTE)
            val ethTime = EthiopianTimeConverter.gregorianToEthiopian(gHour, gMinute)
            val clockText = if (isGeezScript) {
                val periodLabel = if (ethTime.isDaytime) "ቀን" else "ሌሊት"
                String.format(
                    Locale.US,
                    "⏰ %d:%02d %s • %s",
                    ethTime.hour,
                    ethTime.minute,
                    periodLabel,
                    ethTime.period.amharic
                )
            } else {
                val periodLabel = if (ethTime.isDaytime) "Day" else "Night"
                String.format(
                    Locale.US,
                    "⏰ %d:%02d %s (%s)",
                    ethTime.hour,
                    ethTime.minute,
                    periodLabel,
                    ethTime.period.english
                )
            }
            views.setTextViewText(R.id.widget_eth_clock, clockText)

            // Gregorian Companion Badge
            val gregMonth = gregorianMonthShort(gregDate.month)
            val gregDowShort = LocaleStrings.getWeekdayShort(dow, AppLanguage.ENGLISH)
            views.setTextViewText(R.id.widget_greg_label, "🌍 G.C.")
            views.setTextViewText(R.id.widget_greg_date, "$gregMonth ${gregDate.day}")
            views.setTextViewText(R.id.widget_greg_sub, "$gregDowShort, ${gregDate.year}")

            // Fasting status badge
            val isFast = BahireHasabCalculator.isGreatLent(ethDate) ||
                BahireHasabCalculator.isApostlesFast(ethDate) ||
                BahireHasabCalculator.isNinevehFast(ethDate) ||
                BahireHasabCalculator.isWeeklyFastDay(ethDate)

            val fastingText = if (isGeezScript) {
                if (isFast) "🌿 ጾም" else "🥩 ፍስክ"
            } else {
                if (isFast) "🌿 Fasting" else "🍽️ Non-Fast"
            }
            views.setTextViewText(R.id.widget_fasting_status, fastingText)

            // Upcoming holiday or monthly saint
            val holidays = HolidayEngine.getHolidaysForYear(ethDate.year)
            val todayHoliday = holidays.firstOrNull { it.ethiopianDate == ethDate }
            val nextHoliday = holidays.firstOrNull { it.ethiopianDate > ethDate }
            val saintObservance = HolidayEngine.MONTHLY_SAINTS.firstOrNull { it.day == ethDate.day }

            val statusText = when {
                todayHoliday != null -> {
                    val title = holidayTitle(todayHoliday, lang)
                    if (isGeezScript) "🎉 ዛሬ: $title" else "🎉 Today: $title"
                }
                saintObservance != null -> {
                    val saintName = saintName(saintObservance, lang)
                    if (isGeezScript) "✨ ጽላት: $saintName" else "✨ Saint: $saintName"
                }
                nextHoliday != null -> {
                    val daysLeft = EthiopianCalendarEngine.daysBetween(ethDate, nextHoliday.ethiopianDate)
                    val title = holidayTitle(nextHoliday, lang)
                    if (isGeezScript) "ቀጣይ: $title ($daysLeft ቀን)" else "Next: $title (${daysLeft}d)"
                }
                else -> "🇪🇹 EthioCal Pro"
            }
            views.setTextViewText(R.id.widget_holiday, statusText)

            // Click on widget root -> Open Calendar screen
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("navigate_to", "CALENDAR")
            }
            val pendingAppIntent = PendingIntent.getActivity(
                context,
                0,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingAppIntent)

            // Click on clock -> Open Ethiopian Clock Modal in app
            val clockIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("navigate_to", "CLOCK")
            }
            val pendingClockIntent = PendingIntent.getActivity(
                context,
                102,
                clockIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_clock_container, pendingClockIntent)

            // Click on "+ Add / + አዲስ" -> Open Events screen directly
            val addEventIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("navigate_to", "ADD_EVENT")
            }
            val pendingAddIntent = PendingIntent.getActivity(
                context,
                101,
                addEventIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_add_event, pendingAddIntent)

            // Click on refresh icon -> Broadcast to update widget immediately
            val refreshIntent = Intent(context, EthioCalWidgetProvider::class.java).apply {
                action = ACTION_UPDATE_ETHIOCAL_WIDGET
            }
            val pendingRefreshIntent = PendingIntent.getBroadcast(
                context,
                200,
                refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_refresh, pendingRefreshIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun holidayTitle(holiday: HolidayEngine.Holiday, lang: AppLanguage): String = when (lang) {
            AppLanguage.AMHARIC -> holiday.titleAmharic
            AppLanguage.OROMO -> holiday.titleOromo
            AppLanguage.TIGRINYA -> holiday.titleTigrinya
            AppLanguage.ENGLISH, AppLanguage.FRENCH -> holiday.titleEnglish
        }

        private fun saintName(saint: HolidayEngine.MonthlySaintDay, lang: AppLanguage): String = when (lang) {
            AppLanguage.AMHARIC -> saint.nameAmharic
            AppLanguage.OROMO -> saint.nameOromo
            AppLanguage.TIGRINYA -> saint.nameTigrinya
            AppLanguage.ENGLISH, AppLanguage.FRENCH -> saint.nameEnglish
        }
    }
}
