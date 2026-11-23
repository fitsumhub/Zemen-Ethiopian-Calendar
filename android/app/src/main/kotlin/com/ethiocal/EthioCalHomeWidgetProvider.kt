package com.ethiocal

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.RemoteViews

/**
 * Samsung One UI–hardened luxury home widget provider for Zemen Ethiopian Calendar.
 *
 * Always inflates the canonical layout [R.layout.widget_ethiocal_home] matching
 * android:initialLayout and android:previewLayout to prevent "Couldn't add widget"
 * parcel mismatches.
 */
class EthioCalHomeWidgetProvider : AppWidgetProvider() {

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        refreshAll(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, id)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?,
    ) {
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        // Always call super so APPWIDGET_* lifecycle is handled.
        try {
            super.onReceive(context, intent)
        } catch (t: Throwable) {
            Log.e(TAG, "super.onReceive failed", t)
        }
        val action = intent.action ?: return
        if (action == AppWidgetManager.ACTION_APPWIDGET_UPDATE ||
            action == Intent.ACTION_DATE_CHANGED ||
            action == Intent.ACTION_TIME_CHANGED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == ACTION_REFRESH ||
            action == ACTION_PINNED
        ) {
            refreshAll(context)
        }
    }

    companion object {
        const val ACTION_REFRESH = "com.ethiocal.ACTION_REFRESH_HOME_WIDGET"
        const val ACTION_PINNED = "com.ethiocal.ACTION_WIDGET_PINNED"
        private const val TAG = "ZemenHomeWidget"
        private const val WIDGET_PREFS = "zemen_home_widget"
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"

        fun savePayload(context: Context, raw: Map<*, *>) {
            val editor = context.getSharedPreferences(WIDGET_PREFS, Context.MODE_PRIVATE).edit()
            for ((key, value) in raw) {
                if (key !is String) continue
                editor.putString(key, value?.toString().orEmpty())
            }
            editor.commit()
        }

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, EthioCalHomeWidgetProvider::class.java),
            )
            for (id in ids) {
                updateAppWidget(context, manager, id)
            }
        }

        fun widgetCount(context: Context): Int {
            val manager = AppWidgetManager.getInstance(context)
            return manager.getAppWidgetIds(
                ComponentName(context, EthioCalHomeWidgetProvider::class.java),
            ).size
        }

        fun requestPin(context: Context): String {
            val manager = AppWidgetManager.getInstance(context)
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                return "legacy_manual"
            }
            if (!manager.isRequestPinAppWidgetSupported) {
                return "unsupported"
            }
            // Pre-warm provider so One UI bind gets a fast onUpdate.
            try {
                refreshAll(context)
            } catch (t: Throwable) {
                Log.w(TAG, "pre-pin refresh skipped", t)
            }
            val provider = ComponentName(context, EthioCalHomeWidgetProvider::class.java)
            val pinnedCallback = PendingIntent.getBroadcast(
                context,
                9911,
                Intent(context, EthioCalHomeWidgetProvider::class.java).setAction(ACTION_PINNED),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val previewExtras = try {
                val previewViews = buildViews(context, manager, 0)
                Bundle().apply {
                    putParcelable(AppWidgetManager.EXTRA_APPWIDGET_PREVIEW, previewViews)
                }
            } catch (t: Throwable) {
                Log.w(TAG, "preview creation skipped", t)
                null
            }
            return try {
                val success = manager.requestPinAppWidget(provider, previewExtras, pinnedCallback)
                if (success) "pin_requested" else "pin_failed"
            } catch (t: Throwable) {
                Log.e(TAG, "requestPinAppWidget failed", t)
                "pin_failed"
            }
        }

        private fun widgetPrefs(context: Context): SharedPreferences =
            context.getSharedPreferences(WIDGET_PREFS, Context.MODE_PRIVATE)

        private fun flutterPrefs(context: Context): SharedPreferences =
            context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)

        private fun str(
            widget: SharedPreferences,
            flutter: SharedPreferences,
            key: String,
            fallback: String = "",
        ): String {
            return widget.getString(key, null)
                ?: flutter.getString("flutter.$key", null)
                ?: fallback
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            // Pass 1: full luxury content on responsive layout matching options.
            try {
                val views = buildViews(context, appWidgetManager, appWidgetId)
                appWidgetManager.updateAppWidget(appWidgetId, views)
                return
            } catch (t: Throwable) {
                Log.e(TAG, "full update failed id=$appWidgetId", t)
            }
            // Pass 2: static XML only so bind can still succeed on ultra-strict launchers.
            try {
                val bare = RemoteViews(context.packageName, R.layout.widget_ethiocal_home)
                appWidgetManager.updateAppWidget(appWidgetId, bare)
            } catch (t: Throwable) {
                Log.e(TAG, "bare update failed id=$appWidgetId", t)
            }
        }

        private fun buildViews(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ): RemoteViews {
            val options = try {
                if (appWidgetId > 0) appWidgetManager.getAppWidgetOptions(appWidgetId) else null
            } catch (t: Throwable) {
                null
            }
            val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 0
            val minWidth = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 0

            val layoutRes = when {
                minHeight in 1..75 -> R.layout.widget_ethiocal_home_small
                minWidth >= 250 && minHeight >= 160 -> R.layout.widget_ethiocal_home_large
                minWidth >= 210 && minHeight < 160 -> R.layout.widget_ethiocal_home_medium
                else -> R.layout.widget_ethiocal_home
            }

            val views = RemoteViews(context.packageName, layoutRes)

            val today = try {
                EthiopianDateMath.todayEthiopia()
            } catch (t: Throwable) {
                Log.e(TAG, "date math failed", t)
                EthiopianDateMath.EthDate(2017, 3, 14)
            }

            val widget = widgetPrefs(context)
            val flutter = flutterPrefs(context)

            val payloadDay = str(widget, flutter, "widget_eth_d", "")
            val payloadMonth = str(widget, flutter, "widget_month", "")
            val payloadYear = str(widget, flutter, "widget_eth_y", "")
            val payloadWeekday = str(widget, flutter, "widget_weekday", "")
            val payloadGreg = str(widget, flutter, "widget_greg", "")
            val payloadEvangelist = str(widget, flutter, "widget_evangelist", "")

            val geez = str(widget, flutter, "widget_geez", "")
            val showGeez = str(widget, flutter, "widget_show_geez", "1") == "1"
            val showSaint = str(widget, flutter, "widget_show_saint", "1") == "1"
            val saint = str(widget, flutter, "widget_saint", "")
            val upcomingAm = str(widget, flutter, "widget_upcoming_am", "")
            val upcomingEn = str(widget, flutter, "widget_upcoming_en", "")
            val upcomingDays = str(widget, flutter, "widget_upcoming_days", "0").toIntOrNull() ?: 0
            val kind = str(widget, flutter, "widget_kind", "0").toIntOrNull() ?: 0
            val themeFamily = str(widget, flutter, "widget_theme_family", "noirGold")
            val hasPayload = payloadDay.isNotEmpty()

            // Check if the cached payload matches current day
            val isFreshToday = hasPayload && payloadDay == today.day.toString()

            val displayDay = if (isFreshToday) payloadDay else today.day.toString()
            val displayMonth = if (isFreshToday && payloadMonth.isNotEmpty()) {
                payloadMonth
            } else {
                try { EthiopianDateMath.monthNameAm(today.month) } catch (_: Throwable) { "—" }
            }
            val numericYear = if (isFreshToday && payloadYear.isNotEmpty()) {
                payloadYear.toIntOrNull() ?: today.year
            } else {
                today.year
            }
            val evangelist = if (isFreshToday && payloadEvangelist.isNotEmpty()) {
                payloadEvangelist
            } else {
                try {
                    EthiopianDateMath.evangelistAm(numericYear)
                } catch (_: Throwable) {
                    ""
                }
            }
            val displayYear = "$numericYear ዓ.ም"
            val displayWeekday = if (isFreshToday && payloadWeekday.isNotEmpty()) {
                payloadWeekday
            } else {
                try { EthiopianDateMath.weekdayNameAm(today) } catch (_: Throwable) { "" }
            }
            val displayGreg = if (isFreshToday && payloadGreg.isNotEmpty()) {
                payloadGreg
            } else {
                try { EthiopianDateMath.gregorianLabel() } catch (_: Throwable) { "" }
            }
            val resolvedGeez = if (geez.isNotEmpty()) {
                geez
            } else {
                EthiopianDateMath.toGeez(today.day)
            }
            val resolvedSaint = if (saint.isNotEmpty()) {
                saint
            } else {
                try { EthiopianDateMath.canonicalSaintAm(displayDay.toIntOrNull() ?: today.day) } catch (_: Throwable) { "" }
            }

            // Apply selected theme family colors and background
            applyThemeColors(views, themeFamily)

            // Populate text elements
            views.setTextViewText(R.id.widget_home_brand, "ዘመን · ZEMEN")
            views.setTextViewText(R.id.widget_home_day, displayDay)
            views.setTextViewText(R.id.widget_home_month, displayMonth)
            views.setTextViewText(R.id.widget_home_year, displayYear)
            views.setTextViewText(R.id.widget_home_weekday, displayWeekday)
            views.setTextViewText(R.id.widget_home_greg, displayGreg)

            // Evangelist Chip
            if (evangelist.isNotEmpty()) {
                views.setTextViewText(R.id.widget_home_evangelist, evangelist)
                views.setViewVisibility(R.id.widget_home_evangelist, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_home_evangelist, View.GONE)
            }

            // Ge'ez Numeral Pill
            val showGeezView = showGeez && resolvedGeez.isNotEmpty()
            views.setTextViewText(R.id.widget_home_geez, if (showGeezView) resolvedGeez else "")
            views.setViewVisibility(
                R.id.widget_home_geez,
                if (showGeezView) View.VISIBLE else View.GONE,
            )

            // Daily Saint / Fasting / Feast Headline
            val holidayLine = if (hasPayload) {
                buildHolidayLine(
                    kind = kind,
                    showSaint = showSaint,
                    saint = resolvedSaint,
                    upcomingAm = upcomingAm,
                    upcomingEn = upcomingEn,
                    upcomingDays = upcomingDays,
                    ethTime = str(widget, flutter, "widget_time_eth", ""),
                    gregTime = str(widget, flutter, "widget_time_greg", ""),
                    daysGenna = str(widget, flutter, "widget_days_genna", "0"),
                    isFasting = str(widget, flutter, "widget_fasting", "0") == "1",
                    fastingReason = str(widget, flutter, "widget_fasting_reason", ""),
                    geez = resolvedGeez,
                )
            } else {
                if (showSaint && resolvedSaint.isNotEmpty()) resolvedSaint else ""
            }
            if (holidayLine.isNotEmpty()) {
                views.setTextViewText(R.id.widget_home_headline, holidayLine)
                views.setViewVisibility(R.id.widget_home_headline, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_home_headline, View.GONE)
            }

            // Bind Tap Targets (Deep linking & Refresh action)
            try {
                bindInteractions(context, views, appWidgetId)
            } catch (t: Throwable) {
                Log.w(TAG, "interactive click binding skipped", t)
            }
            return views
        }

        private fun applyThemeColors(views: RemoteViews, family: String) {
            try {
                val bgRes = when (family) {
                    "coralStudio" -> R.drawable.widget_bg_coral
                    "emeraldHeritage" -> R.drawable.widget_bg_emerald
                    "parchmentClassic" -> R.drawable.widget_bg_parchment
                    "minimalModern" -> R.drawable.widget_bg_minimal
                    else -> R.drawable.widget_bg_noir
                }
                views.setInt(R.id.widget_home_root, "setBackgroundResource", bgRes)

                when (family) {
                    "coralStudio" -> {
                        views.setTextColor(R.id.widget_home_brand, Color.parseColor("#E57373"))
                        views.setTextColor(R.id.widget_home_day, Color.parseColor("#E57373"))
                        views.setTextColor(R.id.widget_home_month, Color.parseColor("#111827"))
                        views.setTextColor(R.id.widget_home_year, Color.parseColor("#EF5350"))
                        views.setTextColor(R.id.widget_home_weekday, Color.parseColor("#4B5563"))
                        views.setTextColor(R.id.widget_home_greg, Color.parseColor("#6B7280"))
                        views.setTextColor(R.id.widget_home_geez, Color.parseColor("#E57373"))
                        views.setTextColor(R.id.widget_home_evangelist, Color.parseColor("#EF5350"))
                    }
                    "emeraldHeritage" -> {
                        views.setTextColor(R.id.widget_home_brand, Color.parseColor("#7DDEB3"))
                        views.setTextColor(R.id.widget_home_day, Color.parseColor("#7DDEB3"))
                        views.setTextColor(R.id.widget_home_month, Color.parseColor("#FFFFFF"))
                        views.setTextColor(R.id.widget_home_year, Color.parseColor("#B8F0D4"))
                        views.setTextColor(R.id.widget_home_weekday, Color.parseColor("#9AD9BC"))
                        views.setTextColor(R.id.widget_home_greg, Color.parseColor("#9AD9BC"))
                        views.setTextColor(R.id.widget_home_geez, Color.parseColor("#FFFFFF"))
                        views.setTextColor(R.id.widget_home_evangelist, Color.parseColor("#B8F0D4"))
                    }
                    "parchmentClassic" -> {
                        views.setTextColor(R.id.widget_home_brand, Color.parseColor("#8B6914"))
                        views.setTextColor(R.id.widget_home_day, Color.parseColor("#241910"))
                        views.setTextColor(R.id.widget_home_month, Color.parseColor("#241910"))
                        views.setTextColor(R.id.widget_home_year, Color.parseColor("#A67C52"))
                        views.setTextColor(R.id.widget_home_weekday, Color.parseColor("#4A3520"))
                        views.setTextColor(R.id.widget_home_greg, Color.parseColor("#6B4E2E"))
                        views.setTextColor(R.id.widget_home_geez, Color.parseColor("#241910"))
                        views.setTextColor(R.id.widget_home_evangelist, Color.parseColor("#8B6914"))
                    }
                    "minimalModern" -> {
                        views.setTextColor(R.id.widget_home_brand, Color.parseColor("#E8E6E1"))
                        views.setTextColor(R.id.widget_home_day, Color.parseColor("#F4F2EE"))
                        views.setTextColor(R.id.widget_home_month, Color.parseColor("#F4F2EE"))
                        views.setTextColor(R.id.widget_home_year, Color.parseColor("#D0CBC2"))
                        views.setTextColor(R.id.widget_home_weekday, Color.parseColor("#8B919C"))
                        views.setTextColor(R.id.widget_home_greg, Color.parseColor("#8B919C"))
                        views.setTextColor(R.id.widget_home_geez, Color.parseColor("#F4F2EE"))
                        views.setTextColor(R.id.widget_home_evangelist, Color.parseColor("#D0CBC2"))
                    }
                    else -> {
                        views.setTextColor(R.id.widget_home_brand, Color.parseColor("#D4AF74"))
                        views.setTextColor(R.id.widget_home_day, Color.parseColor("#D4AF74"))
                        views.setTextColor(R.id.widget_home_month, Color.parseColor("#FAF6EF"))
                        views.setTextColor(R.id.widget_home_year, Color.parseColor("#C8A96B"))
                        views.setTextColor(R.id.widget_home_weekday, Color.parseColor("#9AA3B2"))
                        views.setTextColor(R.id.widget_home_greg, Color.parseColor("#9AA3B2"))
                        views.setTextColor(R.id.widget_home_geez, Color.parseColor("#F0DFB8"))
                        views.setTextColor(R.id.widget_home_evangelist, Color.parseColor("#EAD3AB"))
                    }
                }
            } catch (t: Throwable) {
                Log.w(TAG, "theme coloring skipped", t)
            }
        }

        private fun buildHolidayLine(
            kind: Int,
            showSaint: Boolean,
            saint: String,
            upcomingAm: String,
            upcomingEn: String,
            upcomingDays: Int,
            ethTime: String = "",
            gregTime: String = "",
            daysGenna: String = "0",
            isFasting: Boolean = false,
            fastingReason: String = "",
            geez: String = "",
        ): String {
            when (kind) {
                3 -> return "ገና · $daysGenna ቀን"
                5, 13 -> if (saint.isNotEmpty()) return saint
                6 -> {
                    val line = listOf(ethTime, gregTime)
                        .filter { it.isNotBlank() }
                        .joinToString(" · ")
                    if (line.isNotEmpty()) return line
                }
                7 -> {
                    val title = upcomingAm.ifEmpty { upcomingEn }
                    if (title.isNotEmpty()) {
                        return if (upcomingDays <= 0) title else "$title · $upcomingDays ቀን"
                    }
                }
                8 -> return "EC + GC"
                11 -> if (geez.isNotEmpty()) return "ግዕዝ · $geez"
                12 -> return if (isFasting) {
                    fastingReason.ifEmpty { "ጾም" }
                } else {
                    "ፍስክ"
                }
            }
            if (upcomingAm.isNotEmpty() || upcomingEn.isNotEmpty()) {
                val title = upcomingAm.ifEmpty { upcomingEn }
                return if (upcomingDays <= 0) title else "$title · $upcomingDays ቀን"
            }
            if (showSaint && saint.isNotEmpty()) return saint
            return ""
        }

        private fun bindInteractions(context: Context, views: RemoteViews, appWidgetId: Int) {
            val baseId = if (appWidgetId > 0) appWidgetId else 991
            // 1. Root card click -> Opens app to Calendar
            val calendarIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("navigate_to", "CALENDAR")
            }
            val calendarPending = PendingIntent.getActivity(
                context,
                baseId * 10,
                calendarIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_home_root, calendarPending)

            // 2. Refresh icon click -> Sends broadcast to immediately refresh widget
            val refreshIntent = Intent(context, EthioCalHomeWidgetProvider::class.java).apply {
                action = ACTION_REFRESH
            }
            val refreshPending = PendingIntent.getBroadcast(
                context,
                baseId * 10 + 1,
                refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_home_refresh, refreshPending)

            // 3. Saint / Holiday headline click -> Opens app to Holidays tab
            val holidayIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("navigate_to", "HOLIDAYS")
            }
            val holidayPending = PendingIntent.getActivity(
                context,
                baseId * 10 + 2,
                holidayIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_home_headline, holidayPending)

            // 4. Gregorian date click -> Opens app to Converter tab
            val converterIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("navigate_to", "CONVERTER")
            }
            val converterPending = PendingIntent.getActivity(
                context,
                baseId * 10 + 3,
                converterIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_home_greg, converterPending)
        }
    }
}
