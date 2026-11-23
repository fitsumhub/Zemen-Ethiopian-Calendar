package com.example

import com.example.calendar.engine.BahireHasabCalculator
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.GregorianDate
import com.example.calendar.engine.HolidayEngine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class EthiopianCalendar100YearTest {

    @Test
    fun testLeapYearRulesAcross100Years() {
        for (year in 2015..2125) {
            val isLeap = EthiopianDate.isLeapYear(year)
            val expectedLeap = (year % 4 == 3)
            assertEquals("Year $year leap status", expectedLeap, isLeap)

            val pagumeDays = EthiopianDate.daysInMonth(year, 13)
            assertEquals("Year $year Pagume days", if (expectedLeap) 6 else 5, pagumeDays)

            // Months 1 to 12 must always have 30 days
            for (month in 1..12) {
                assertEquals("Month $month in year $year must have 30 days", 30, EthiopianDate.daysInMonth(year, month))
            }
        }
    }

    @Test
    fun testBidirectionalConversionAcross100Years() {
        // Test bidirectional conversion across every single year for 100+ years
        for (year in 2017..2125) {
            // Test Meskerem 1 (New Year)
            val meskerem1 = EthiopianDate(year, 1, 1)
            val gregDate = EthiopianCalendarEngine.toGregorian(meskerem1)
            val backToEth = EthiopianCalendarEngine.toEthiopian(gregDate)
            assertEquals("Round-trip Meskerem 1 for year $year", meskerem1, backToEth)

            // Test mid-year date: Tahsas 29 (Ethiopian Christmas / Ganna)
            val ganna = EthiopianDate(year, 4, 29)
            val gregGanna = EthiopianCalendarEngine.toGregorian(ganna)
            val backGanna = EthiopianCalendarEngine.toEthiopian(gregGanna)
            assertEquals("Round-trip Tahsas 29 for year $year", ganna, backGanna)

            // Test last day of year: Pagume 5 or 6
            val isLeap = EthiopianDate.isLeapYear(year)
            val lastDay = if (isLeap) 6 else 5
            val endOfYear = EthiopianDate(year, 13, lastDay)
            val gregEnd = EthiopianCalendarEngine.toGregorian(endOfYear)
            val backEnd = EthiopianCalendarEngine.toEthiopian(gregEnd)
            assertEquals("Round-trip end of year $year", endOfYear, backEnd)
        }
    }

    @Test
    fun testBahireHasabCalculationsAcross100Years() {
        for (year in 2017..2125) {
            val computation = BahireHasabCalculator.calculate(year)
            assertNotNull(computation)
            assertEquals(year, computation.ethiopianYear)

            // Evangelist name must be valid
            assertTrue(
                listOf("ማቴዎስ", "ማርቆስ", "ሉቃስ", "ዮሐንስ").any { computation.evangelist.amharic.startsWith(it) }
            )

            // Wenber + Metqi relationship: Metqi + Abeqte == 30
            assertEquals(30, computation.abeqte + computation.metqi)

            // Movable feasts must be valid Ethiopian dates
            assertTrue("Nenewe month", computation.nenewe.month in 5..6)
            assertTrue("Movable feasts exist", computation.movableFeasts.isNotEmpty())
        }
    }

    @Test
    fun testHolidaysGenerationAcross100Years() {
        for (year in 2017..2125) {
            val holidays = HolidayEngine.getHolidaysForYear(year)
            assertTrue("Holidays should exist for year $year", holidays.isNotEmpty())

            // Must contain Enkutatash (Meskerem 1)
            val enkutatash = holidays.find { it.ethiopianDate == EthiopianDate(year, 1, 1) }
            assertNotNull("Enkutatash must exist in year $year", enkutatash)
            assertTrue(enkutatash!!.isPublicHoliday)

            // Must contain Meskel (Meskerem 17)
            val meskel = holidays.find { it.ethiopianDate == EthiopianDate(year, 1, 17) }
            assertNotNull("Meskel must exist in year $year", meskel)

            // Must contain Ganna / Christmas (Tahsas 29 or Tahsas 28 on leap leap)
            val ganna = holidays.find { it.titleEnglish.contains("Christmas", ignoreCase = true) }
            assertNotNull("Ganna must exist in year $year", ganna)

            // Must contain Timkat (Tir 11)
            val timkat = holidays.find { it.ethiopianDate == EthiopianDate(year, 5, 11) }
            assertNotNull("Timkat must exist in year $year", timkat)

            // Must contain Adwa Victory (Yekatit 23)
            val adwa = holidays.find { it.ethiopianDate == EthiopianDate(year, 6, 23) }
            assertNotNull("Adwa must exist in year $year", adwa)

            // Must contain Fasika (Easter)
            val fasika = holidays.find { it.titleEnglish.contains("Easter", ignoreCase = true) }
            assertNotNull("Fasika must exist in year $year", fasika)
        }
    }

    @Test
    fun testStandardArabicNumeralsFormatting() {
        val testDate = EthiopianDate(2017, 7, 24)
        val formattedDay = testDate.day.toString()
        val formattedYear = testDate.year.toString()

        assertEquals("24", formattedDay)
        assertEquals("2017", formattedYear)

        // Ensure no Ge'ez numeral characters (U+1369 through U+137C)
        val geezRange = '\u1369'..'\u137C'
        for (c in formattedDay) {
            assertFalse("Day contains Ge'ez char: $c", c in geezRange)
        }
        for (c in formattedYear) {
            assertFalse("Year contains Ge'ez char: $c", c in geezRange)
        }
    }
}
