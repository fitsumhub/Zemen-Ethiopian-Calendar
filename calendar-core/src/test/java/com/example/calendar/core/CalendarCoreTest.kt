package com.example.calendar.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CalendarCoreTest {

    // ==========================================
    // 1. MONTH DEFINITIONS TEST
    // ==========================================
    @Test
    fun testAllThirteenMonthsDefinitions() {
        val months = EthiopianMonth.entries
        assertEquals(13, months.size)

        assertEquals("መስከረም", EthiopianMonth.MESKEREM.amharicName)
        assertEquals("Meskerem", EthiopianMonth.MESKEREM.englishName)
        assertEquals(1, EthiopianMonth.MESKEREM.number)
        assertEquals(30, EthiopianMonth.MESKEREM.daysInMonth(isLeapYear = false))
        assertEquals(30, EthiopianMonth.MESKEREM.daysInMonth(isLeapYear = true))

        assertEquals("ጳጉሜ", EthiopianMonth.PAGUME.amharicName)
        assertEquals("Pagume", EthiopianMonth.PAGUME.englishName)
        assertEquals(13, EthiopianMonth.PAGUME.number)
        assertEquals(5, EthiopianMonth.PAGUME.daysInMonth(isLeapYear = false))
        assertEquals(6, EthiopianMonth.PAGUME.daysInMonth(isLeapYear = true))

        for (m in 1..12) {
            val month = EthiopianMonth.fromNumber(m)
            assertEquals(30, month.daysInMonth(false))
            assertEquals(30, month.daysInMonth(true))
        }
    }

    // ==========================================
    // 2. LEAP YEAR CALCULATIONS TEST
    // ==========================================
    @Test
    fun testEthiopianLeapYearCycle() {
        // Ethiopian leap years have year % 4 == 3 (Luke year)
        assertTrue(LeapYearCalculator.isEthiopianLeapYear(1999))
        assertTrue(LeapYearCalculator.isEthiopianLeapYear(2003))
        assertTrue(LeapYearCalculator.isEthiopianLeapYear(2007))
        assertTrue(LeapYearCalculator.isEthiopianLeapYear(2011))
        assertTrue(LeapYearCalculator.isEthiopianLeapYear(2015))
        assertTrue(LeapYearCalculator.isEthiopianLeapYear(2019))
        assertTrue(LeapYearCalculator.isEthiopianLeapYear(2023))

        // Non-leap years
        assertFalse(LeapYearCalculator.isEthiopianLeapYear(2016))
        assertFalse(LeapYearCalculator.isEthiopianLeapYear(2017))
        assertFalse(LeapYearCalculator.isEthiopianLeapYear(2018))

        // Evangelist verification
        assertEquals(LeapYearCalculator.Evangelist.LUKE, LeapYearCalculator.getEvangelist(2015))
        assertTrue(LeapYearCalculator.getEvangelist(2015).isLeapYear)
        assertEquals(LeapYearCalculator.Evangelist.JOHN, LeapYearCalculator.getEvangelist(2016))
        assertEquals(LeapYearCalculator.Evangelist.MATTHEW, LeapYearCalculator.getEvangelist(2017))
        assertEquals(LeapYearCalculator.Evangelist.MARK, LeapYearCalculator.getEvangelist(2018))
        assertEquals(LeapYearCalculator.Evangelist.LUKE, LeapYearCalculator.getEvangelist(2019))

        // Year days
        assertEquals(366, LeapYearCalculator.getEthiopianYearDays(2015))
        assertEquals(365, LeapYearCalculator.getEthiopianYearDays(2016))
        assertEquals(365, LeapYearCalculator.getEthiopianYearDays(2017))
    }

    // ==========================================
    // 3. DATE CONVERSION ALGORITHMS TEST
    // ==========================================
    @Test
    fun testKnownCanonicalDateConversions() {
        // Enkutatash 2017 E.C. -> Sept 11, 2024 G.C.
        val enk2017 = EthiopianDate(2017, 1, 1)
        val gregEnk2017 = EthiopianDateConverter.toGregorian(enk2017)
        assertEquals(GregorianDate(2024, 9, 11), gregEnk2017)

        // Round-trip back to Ethiopian
        val roundTrip2017 = EthiopianDateConverter.toEthiopian(gregEnk2017)
        assertEquals(enk2017, roundTrip2017)

        // Pagume 6 in 2015 leap year -> Sept 11, 2023 G.C.
        val pagume6 = EthiopianDate(2015, 13, 6)
        val gregPagume6 = EthiopianDateConverter.toGregorian(pagume6)
        assertEquals(GregorianDate(2023, 9, 11), gregPagume6)
        assertEquals(pagume6, EthiopianDateConverter.toEthiopian(gregPagume6))

        // Meskerem 1 after Pagume 6 -> Sept 12, 2023 G.C.
        val enk2016 = EthiopianDate(2016, 1, 1)
        val gregEnk2016 = EthiopianDateConverter.toGregorian(enk2016)
        assertEquals(GregorianDate(2023, 9, 12), gregEnk2016)
        assertEquals(enk2016, EthiopianDateConverter.toEthiopian(gregEnk2016))

        // Genna 2016 E.C. (Tahsas 29) -> Jan 8, 2024 G.C. (following 2015 leap year)
        val genna2016 = EthiopianDate(2016, 4, 29)
        val gregGenna = EthiopianDateConverter.toGregorian(genna2016)
        assertEquals(GregorianDate(2024, 1, 8), gregGenna)
        assertEquals(genna2016, EthiopianDateConverter.toEthiopian(gregGenna))
    }

    @Test
    fun testContinuousRoundTripConversionsAcross100Years() {
        for (year in 2010..2040) {
            val maxPagume = if (LeapYearCalculator.isEthiopianLeapYear(year)) 6 else 5
            for (month in 1..13) {
                val sampleDays = if (month == 13) {
                    (1..maxPagume).toList()
                } else {
                    listOf(1, 15, 30)
                }
                for (day in sampleDays) {
                    val original = EthiopianDate(year, month, day)
                    val gregorian = EthiopianDateConverter.toGregorian(original)
                    val reconstructed = EthiopianDateConverter.toEthiopian(gregorian)
                    assertEquals("Round-trip failed for $original", original, reconstructed)
                }
            }
        }
    }

    // ==========================================
    // 4. GE'EZ NUMERAL SUPPORT TEST
    // ==========================================
    @Test
    fun testGeezNumeralEncodingAndDecoding() {
        val testPairs = listOf(
            1 to "፩",
            2 to "፪",
            5 to "፭",
            9 to "፱",
            10 to "፲",
            11 to "፲፩",
            20 to "፳",
            25 to "፳፭",
            30 to "፴",
            100 to "፻",
            200 to "፪፻",
            2017 to "፳፻፲፯"
        )

        for ((num, geez) in testPairs) {
            assertEquals("toGeez failed for $num", geez, GeezNumeral.toGeez(num))
            assertTrue("isGeez failed for $geez", GeezNumeral.isGeez(geez))
            assertEquals("fromGeez failed for $geez", num, GeezNumeral.fromGeez(geez))
        }

        assertFalse(GeezNumeral.isGeez("123"))
        assertFalse(GeezNumeral.isGeez("ABC"))
    }

    // ==========================================
    // 5. BAHIRE HASAB COMPUTUS TEST
    // ==========================================
    @Test
    fun testBahireHasabCalculation() {
        val result2017 = BahireHasab.calculate(2017)
        assertEquals(2017, result2017.ethiopianYear)
        assertEquals(7517, result2017.ameteAlem)
        assertEquals(LeapYearCalculator.Evangelist.MATTHEW, result2017.evangelist)
        assertTrue(result2017.movableFeasts.isNotEmpty())

        val result2018 = BahireHasab.calculate(2018)
        assertEquals(2018, result2018.ethiopianYear)
        assertEquals(LeapYearCalculator.Evangelist.MARK, result2018.evangelist)
    }

    // ==========================================
    // 6. ETHIOPIAN TIMEKEEPING TEST
    // ==========================================
    @Test
    fun testEthiopianTimeConverter() {
        // 6:00 AM Gregorian -> 12:00 morning Ethiopian (ቀን)
        val t6am = EthiopianTimeConverter.gregorianToEthiopian(6, 0)
        assertEquals(12, t6am.hour)
        assertTrue(t6am.isDaytime)

        // 12:00 PM Gregorian -> 6:00 midday Ethiopian (ቀን)
        val t12pm = EthiopianTimeConverter.gregorianToEthiopian(12, 0)
        assertEquals(6, t12pm.hour)
        assertTrue(t12pm.isDaytime)

        // 6:00 PM Gregorian -> 12:00 evening Ethiopian (ሌሊት)
        val t6pm = EthiopianTimeConverter.gregorianToEthiopian(18, 0)
        assertEquals(12, t6pm.hour)
        assertFalse(t6pm.isDaytime)

        // Round-trip back to Gregorian
        val gTimeBack = EthiopianTimeConverter.ethiopianToGregorian(6, 0, isDaytime = true)
        assertEquals(12, gTimeBack.hour24)
        assertEquals(0, gTimeBack.minute)
    }
}
