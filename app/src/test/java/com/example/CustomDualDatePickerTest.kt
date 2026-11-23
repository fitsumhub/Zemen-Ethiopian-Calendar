package com.example

import com.example.calendar.core.EthiopianDate
import com.example.calendar.core.GregorianDate
import com.example.calendar.core.LeapYearCalculator
import com.example.calendar.domain.EthiopianCalendarDomain
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.HolidayEngine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar

/**
 * Automated tests for the Custom Dual Calendar Date Picker calculations,
 * format toggling, and date synchronization between Ethiopian and Gregorian systems.
 */
class CustomDualDatePickerTest {

    private val domain = EthiopianCalendarDomain.INSTANCE

    @Test
    fun testSeamlessFormatToggleDateSynchronization() {
        // 1. Start with Ethiopian New Year: Meskerem 1, 2017 E.C.
        val ethDate1 = EthiopianDate(2017, 1, 1)
        val gregDate1 = EthiopianCalendarEngine.toGregorian(ethDate1)

        assertEquals("Meskerem 1, 2017 should correspond to Sept 11, 2024", 2024, gregDate1.year)
        assertEquals(9, gregDate1.month)
        assertEquals(11, gregDate1.day)

        // Seamless toggle back
        val ethBack1 = EthiopianCalendarEngine.toEthiopian(gregDate1)
        assertEquals(ethDate1, ethBack1)

        // 2. Start with Gregorian Christmas / Ethiopian Genna: January 7, 2025 G.C.
        val gregGenna = GregorianDate(2025, 1, 7)
        val ethGenna = EthiopianCalendarEngine.toEthiopian(gregGenna)

        assertEquals("January 7, 2025 should correspond to Tahsas 29, 2017", 2017, ethGenna.year)
        assertEquals(4, ethGenna.month) // Tahsas
        assertEquals(29, ethGenna.day)

        val gregBack = EthiopianCalendarEngine.toGregorian(ethGenna)
        assertEquals(gregGenna, gregBack)
    }

    @Test
    fun testPagumeBoundaryAndLeapYearInDatePicker() {
        // Non-leap year Pagume (2016 E.C.)
        val maxDaysNonLeap = domain.getDaysInMonth(2016, 13)
        assertEquals("Pagume 2016 should have 5 days", 5, maxDaysNonLeap)

        // Leap year Pagume (2015 E.C. - Luke)
        val maxDaysLeap = domain.getDaysInMonth(2015, 13)
        assertEquals("Pagume 2015 should have 6 days", 6, maxDaysLeap)

        // Pagume 6, 2015 converts cleanly to Sept 11, 2023
        val pagume6 = EthiopianDate(2015, 13, 6)
        val gregP6 = EthiopianCalendarEngine.toGregorian(pagume6)
        assertEquals(2023, gregP6.year)
        assertEquals(9, gregP6.month)
        assertEquals(11, gregP6.day)
    }

    @Test
    fun testGregorianMonthMaxDaysValidation() {
        fun getGregorianMaxDays(year: Int, month: Int): Int {
            return when (month) {
                1, 3, 5, 7, 8, 10, 12 -> 31
                4, 6, 9, 11 -> 30
                2 -> if (LeapYearCalculator.isGregorianLeapYear(year)) 29 else 28
                else -> 30
            }
        }

        assertEquals(31, getGregorianMaxDays(2024, 1))  // Jan
        assertEquals(29, getGregorianMaxDays(2024, 2))  // Feb leap
        assertEquals(28, getGregorianMaxDays(2025, 2))  // Feb non-leap
        assertEquals(31, getGregorianMaxDays(2024, 3))  // Mar
        assertEquals(30, getGregorianMaxDays(2024, 4))  // Apr
        assertEquals(31, getGregorianMaxDays(2024, 12)) // Dec
    }

    @Test
    fun testHolidaysDetectionOnPickedDate() {
        val holidays2017 = HolidayEngine.getHolidaysForYear(2017)

        // Pick Meskerem 17 (Finding of the True Cross / Meskel)
        val meskel = holidays2017.find { it.ethiopianDate.month == 1 && it.ethiopianDate.day == 17 }
        assertNotNull("Meskel should be detected on Meskerem 17", meskel)
        assertTrue(meskel!!.titleAmharic.contains("መስቀል"))

        // Pick Tir 11 (Epiphany / Timket)
        val timket = holidays2017.find { it.ethiopianDate.month == 5 && it.ethiopianDate.day == 11 }
        assertNotNull("Timket should be detected on Tir 11", timket)
        assertTrue(timket!!.titleAmharic.contains("ጥምቀት"))
    }

    @Test
    fun testDayOfWeekAlignment() {
        // Meskerem 1, 2017 E.C. was a Wednesday (1=Mon, 2=Tue, 3=Wed)
        val dow = EthiopianCalendarEngine.getDayOfWeek(EthiopianDate(2017, 1, 1))
        assertEquals("Meskerem 1, 2017 E.C. is Wednesday (day 3)", 3, dow)

        // Gregorian Sep 11, 2024 was also Wednesday
        val cal = Calendar.getInstance().apply {
            set(2024, Calendar.SEPTEMBER, 11)
        }
        assertEquals(Calendar.WEDNESDAY, cal.get(Calendar.DAY_OF_WEEK))
    }
}
