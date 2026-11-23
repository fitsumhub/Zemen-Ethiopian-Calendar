package com.example.calendar.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.example.MainActivity
import com.example.R
import com.example.calendar.engine.BahireHasabCalculator
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.GeezNumberFormatter
import com.example.calendar.localization.AppLanguage
import com.example.calendar.localization.LocaleStrings

/**
 * Compact 2x1 Dual-Calendar Home Screen Widget Provider
 * Displays today's current date in both Ethiopian and Gregorian calendar formats.
 */
class EthioCalCompactWidgetProvider : AppWidgetProvider() {

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        EthioCalWidgetProvider.scheduleMidnightUpdate(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        EthioCalWidgetProvider.cancelMidnightUpdateIfNoWidgets(context)
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
        EthioCalWidgetProvider.scheduleMidnightUpdate(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == Intent.ACTION_TIME_CHANGED ||
            intent.action == Intent.ACTION_TIMEZONE_CHANGED ||
            intent.action == Intent.ACTION_DATE_CHANGED ||
            intent.action == EthioCalWidgetProvider.ACTION_UPDATE_ETHIOCAL_WIDGET
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, EthioCalCompactWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (id in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, id)
            }
            if (appWidgetIds.isNotEmpty()) {
                EthioCalWidgetProvider.scheduleMidnightUpdate(context)
            }
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val lang = EthioCalWidgetProvider.resolveLanguage(context)
            val isGeezScript = lang == AppLanguage.AMHARIC || lang == AppLanguage.TIGRINYA
            val ethDate = EthiopianCalendarEngine.todayEthiopian()
            val gregDate = EthiopianCalendarEngine.todayGregorian()
            val dow = EthiopianCalendarEngine.getDayOfWeek(ethDate)

            val views = RemoteViews(context.packageName, R.layout.widget_ethiocal_compact)

            val monthName = LocaleStrings.getMonthName(ethDate.month, lang)
            val weekdayName = LocaleStrings.getWeekdayLong(dow, lang)
            val eraSuffix = if (isGeezScript) "ዓ.ም" else "E.C."

            views.setTextViewText(R.id.widget_compact_month, "🇪🇹 $monthName")
            views.setTextViewText(R.id.widget_compact_weekday, weekdayName)

            views.setTextViewText(R.id.widget_compact_day, ethDate.day.toString())
            views.setTextViewText(R.id.widget_compact_geez, GeezNumberFormatter.toGeez(ethDate.day))
            views.setTextViewText(R.id.widget_compact_year, "${ethDate.year} $eraSuffix")

            val gregMonth = EthioCalWidgetProvider.gregorianMonthShort(gregDate.month)
            views.setTextViewText(
                R.id.widget_compact_greg_date,
                "🌍 $gregMonth ${gregDate.day}, ${gregDate.year}"
            )

            val isFast = BahireHasabCalculator.isGreatLent(ethDate) ||
                BahireHasabCalculator.isApostlesFast(ethDate) ||
                BahireHasabCalculator.isNinevehFast(ethDate) ||
                BahireHasabCalculator.isWeeklyFastDay(ethDate)
            val fastingText = if (isGeezScript) {
                if (isFast) "🌿 ጾም" else "🥩 ፍስክ"
            } else {
                if (isFast) "🌿 Fast" else "🍽️ Reg"
            }
            views.setTextViewText(R.id.widget_compact_fasting, fastingText)

            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("navigate_to", "CALENDAR")
            }
            val pendingAppIntent = PendingIntent.getActivity(
                context,
                110,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_compact_root, pendingAppIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
