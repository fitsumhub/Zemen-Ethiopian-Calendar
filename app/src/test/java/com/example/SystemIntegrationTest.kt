package com.example

import android.appwidget.AppWidgetManager
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.example.calendar.data.AndroidCalendarSyncManager
import com.example.calendar.data.EventEntity
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianTimeConverter
import com.example.calendar.engine.GeezNumberFormatter
import com.example.calendar.widget.EthioCalWidgetProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.util.Calendar

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class SystemIntegrationTest {

    private lateinit var context: Context

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
    }

    @Test
    fun `EthiopianTimeConverter calculates 12-hour cycle correctly`() {
        // 6:00 AM Gregorian is Ethiopian 12:00 morning/daytime
        val ethTimeMorning = EthiopianTimeConverter.gregorianToEthiopian(6, 0)
        assertEquals(12, ethTimeMorning.hour)
        assertEquals(0, ethTimeMorning.minute)
        assertTrue(ethTimeMorning.isDaytime)

        // 7:30 AM Gregorian is Ethiopian 1:30 morning
        val ethTime730 = EthiopianTimeConverter.gregorianToEthiopian(7, 30)
        assertEquals(1, ethTime730.hour)
        assertEquals(30, ethTime730.minute)
        assertTrue(ethTime730.isDaytime)

        // 12:00 PM Gregorian is Ethiopian 6:00 midday
        val ethTimeNoon = EthiopianTimeConverter.gregorianToEthiopian(12, 0)
        assertEquals(6, ethTimeNoon.hour)
        assertEquals(0, ethTimeNoon.minute)
        assertTrue(ethTimeNoon.isDaytime)

        // 6:00 PM Gregorian is Ethiopian 12:00 night
        val ethTimeNight = EthiopianTimeConverter.gregorianToEthiopian(18, 0)
        assertEquals(12, ethTimeNight.hour)
        assertEquals(0, ethTimeNight.minute)
        assertTrue(!ethTimeNight.isDaytime)
    }

    @Test
    fun `GeezNumberFormatter formats days correctly`() {
        assertEquals("፩", GeezNumberFormatter.toGeez(1))
        assertEquals("፭", GeezNumberFormatter.toGeez(5))
        assertEquals("፱", GeezNumberFormatter.toGeez(9))
        assertEquals("፲", GeezNumberFormatter.toGeez(10))
        assertEquals("፲፭", GeezNumberFormatter.toGeez(15))
        assertEquals("፳፩", GeezNumberFormatter.toGeez(21))
        assertEquals("፴", GeezNumberFormatter.toGeez(30))
    }

    @Test
    fun `EthioCalWidgetProvider update executes without crash`() {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val shadowAppWidgetManager = org.robolectric.Shadows.shadowOf(appWidgetManager)
        val appWidgetId = shadowAppWidgetManager.createWidget(EthioCalWidgetProvider::class.java, R.layout.widget_ethiocal)
        EthioCalWidgetProvider.updateAppWidget(context, appWidgetManager, appWidgetId)
        val view = shadowAppWidgetManager.getViewFor(appWidgetId)
        assertNotNull(view)
    }

    @Test
    fun `AndroidCalendarSyncManager checks permissions and handles missing gracefully`() {
        // In unit test environment without granted calendar permissions
        val hasPerms = AndroidCalendarSyncManager.hasCalendarPermissions(context)
        // Check that safe query doesn't crash
        val calendars = AndroidCalendarSyncManager.getAvailableCalendars(context)
        assertNotNull(calendars)

        val sampleEvent = EventEntity(
            id = 55L,
            title = "Lalibela Pilgrimage",
            description = "Annual celebration",
            category = "RELIGIOUS",
            ethiopianYear = 2019,
            ethiopianMonth = 4,
            ethiopianDay = 29,
            gregorianYear = 2027,
            gregorianMonth = 1,
            gregorianDay = 7,
            hour = 8,
            minute = 30,
            isAllDay = false,
            recurrence = "NONE",
            reminderMinutesBefore = 60
        )

        val result = AndroidCalendarSyncManager.syncAllEventsToDevice(context, listOf(sampleEvent))
        assertNotNull(result)
    }
}
