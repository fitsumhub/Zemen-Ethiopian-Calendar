package com.example

import android.app.AlarmManager
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.TextView
import androidx.test.core.app.ApplicationProvider
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.GeezNumberFormatter
import com.example.calendar.widget.EthioCalCompactWidgetProvider
import com.example.calendar.widget.EthioCalWidgetProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class EthioCalWidgetProviderTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    @Test
    fun testWidgetProviderInstantiatesAndReceivesUpdate() {
        val provider = EthioCalWidgetProvider()
        val intent = Intent(EthioCalWidgetProvider.ACTION_UPDATE_ETHIOCAL_WIDGET)
        provider.onReceive(context, intent)
    }

    @Test
    fun testCompactWidgetProviderInstantiatesAndReceivesUpdate() {
        val provider = EthioCalCompactWidgetProvider()
        val intent = Intent(EthioCalWidgetProvider.ACTION_UPDATE_ETHIOCAL_WIDGET)
        provider.onReceive(context, intent)
    }

    @Test
    fun testFullWidgetDisplaysBothEthiopianAndGregorianDates() {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        assertNotNull(appWidgetManager)

        val shadowManager = shadowOf(appWidgetManager)
        val fullWidgetId = shadowManager.createWidget(
            EthioCalWidgetProvider::class.java,
            R.layout.widget_ethiocal
        )

        EthioCalWidgetProvider.updateAppWidget(context, appWidgetManager, fullWidgetId)

        val fullView = shadowManager.getViewFor(fullWidgetId)
        assertNotNull(fullView)

        val ethDate = EthiopianCalendarEngine.todayEthiopian()
        val gregDate = EthiopianCalendarEngine.todayGregorian()
        val gregMonthShort = EthioCalWidgetProvider.gregorianMonthShort(gregDate.month)

        val ethDayTv = fullView.findViewById<TextView>(R.id.widget_eth_day)
        val geezDayTv = fullView.findViewById<TextView>(R.id.widget_geez_day)
        val ethMonthYearTv = fullView.findViewById<TextView>(R.id.widget_eth_month_year)
        val gregDateTv = fullView.findViewById<TextView>(R.id.widget_greg_date)
        val gregSubTv = fullView.findViewById<TextView>(R.id.widget_greg_sub)

        assertEquals(ethDate.day.toString(), ethDayTv.text.toString())
        assertEquals(GeezNumberFormatter.toGeez(ethDate.day), geezDayTv.text.toString())
        assertTrue(ethMonthYearTv.text.toString().contains(ethDate.year.toString()))
        assertEquals("$gregMonthShort ${gregDate.day}", gregDateTv.text.toString())
        assertTrue(gregSubTv.text.toString().contains(gregDate.year.toString()))
    }

    @Test
    fun testCompactWidgetDisplaysBothEthiopianAndGregorianDates() {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        assertNotNull(appWidgetManager)

        val shadowManager = shadowOf(appWidgetManager)
        val compactWidgetId = shadowManager.createWidget(
            EthioCalCompactWidgetProvider::class.java,
            R.layout.widget_ethiocal_compact
        )

        EthioCalCompactWidgetProvider.updateAppWidget(context, appWidgetManager, compactWidgetId)

        val compactView = shadowManager.getViewFor(compactWidgetId)
        assertNotNull(compactView)

        val ethDate = EthiopianCalendarEngine.todayEthiopian()
        val gregDate = EthiopianCalendarEngine.todayGregorian()
        val gregMonthShort = EthioCalWidgetProvider.gregorianMonthShort(gregDate.month)

        val dayTv = compactView.findViewById<TextView>(R.id.widget_compact_day)
        val geezTv = compactView.findViewById<TextView>(R.id.widget_compact_geez)
        val yearTv = compactView.findViewById<TextView>(R.id.widget_compact_year)
        val gregTv = compactView.findViewById<TextView>(R.id.widget_compact_greg_date)

        assertEquals(ethDate.day.toString(), dayTv.text.toString())
        assertEquals(GeezNumberFormatter.toGeez(ethDate.day), geezTv.text.toString())
        assertTrue(yearTv.text.toString().contains(ethDate.year.toString()))
        assertTrue(gregTv.text.toString().contains(gregMonthShort))
        assertTrue(gregTv.text.toString().contains(gregDate.day.toString()))
        assertTrue(gregTv.text.toString().contains(gregDate.year.toString()))
    }

    @Test
    fun testMidnightScheduleAndDateChangedBroadcast() {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val shadowAlarmManager = shadowOf(alarmManager)

        EthioCalWidgetProvider.scheduleMidnightUpdate(context)
        assertTrue(shadowAlarmManager.scheduledAlarms.isNotEmpty())

        val provider = EthioCalWidgetProvider()
        provider.onReceive(context, Intent(Intent.ACTION_DATE_CHANGED))
        EthioCalWidgetProvider.updateAllWidgets(context)
    }

    @Test
    fun testGregorianMonthShortFormatting() {
        assertEquals("Jan", EthioCalWidgetProvider.gregorianMonthShort(1))
        assertEquals("Sep", EthioCalWidgetProvider.gregorianMonthShort(9))
        assertEquals("Nov", EthioCalWidgetProvider.gregorianMonthShort(11))
        assertEquals("Dec", EthioCalWidgetProvider.gregorianMonthShort(12))
    }
}
