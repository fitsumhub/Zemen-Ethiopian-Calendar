package com.example

import com.example.calendar.engine.BahireHasabCalculator
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.EthiopianTimeConverter
import com.example.calendar.engine.GeezNumberFormatter
import com.example.calendar.engine.GregorianDate
import com.example.calendar.engine.HolidayEngine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class EthiopianCalendarEngineTest {

    @Test
    fun testEthiopianMillenniumConversion() {
        // Ethiopian Millennium began on Meskerem 1, 2000 E.C. which was September 12, 2007 G.C.
        val ethMillennium = EthiopianDate(2000, 1, 1)
        val gregResult = EthiopianCalendarEngine.toGregorian(ethMillennium)
        assertEquals(2007, gregResult.year)
        assertEquals(9, gregResult.month)
        assertEquals(12, gregResult.day)

        // Reverse check
        val ethBack = EthiopianCalendarEngine.toEthiopian(gregResult)
        assertEquals(ethMillennium, ethBack)
    }

    @Test
    fun testPagumeLeapYear() {
        // 2015 E.C. was a leap year (Luke year, 2015 % 4 == 3) with 6 days of Pagume.
        // Pagume 6, 2015 E.C. was September 11, 2023 G.C.
        assertTrue(EthiopianDate.isLeapYear(2015))
        val pagume6 = EthiopianDate(2015, 13, 6)
        val gregResult = EthiopianCalendarEngine.toGregorian(pagume6)
        assertEquals(2023, gregResult.year)
        assertEquals(9, gregResult.month)
        assertEquals(11, gregResult.day)

        // Following day: Meskerem 1, 2016 E.C. was September 12, 2023 G.C.
        val meskerem1_2016 = EthiopianDate(2016, 1, 1)
        val gregNext = EthiopianCalendarEngine.toGregorian(meskerem1_2016)
        assertEquals(2023, gregNext.year)
        assertEquals(9, gregNext.month)
        assertEquals(12, gregNext.day)
    }

    @Test
    fun testPagumeNonLeapYear() {
        // 2016 E.C. was not a leap year. Pagume had 5 days.
        // Pagume 5, 2016 E.C. was September 10, 2024 G.C.
        assertFalse(EthiopianDate.isLeapYear(2016))
        val pagume5 = EthiopianDate(2016, 13, 5)
        val gregResult = EthiopianCalendarEngine.toGregorian(pagume5)
        assertEquals(2024, gregResult.year)
        assertEquals(9, gregResult.month)
        assertEquals(10, gregResult.day)

        // Meskerem 1, 2017 was September 11, 2024 G.C.
        val meskerem1_2017 = EthiopianDate(2017, 1, 1)
        val gregNext = EthiopianCalendarEngine.toGregorian(meskerem1_2017)
        assertEquals(2024, gregNext.year)
        assertEquals(9, gregNext.month)
        assertEquals(11, gregNext.day)
    }

    @Test
    fun testOctober132026Conversion() {
        // October 13, 2026 G.C. -> Tikimt 3, 2019 E.C.
        val gregDate = GregorianDate(2026, 10, 13)
        val ethDate = EthiopianCalendarEngine.toEthiopian(gregDate)
        assertEquals(2019, ethDate.year)
        assertEquals(2, ethDate.month) // Tikimt
        assertEquals(3, ethDate.day)

        // Reverse check
        val backToGreg = EthiopianCalendarEngine.toGregorian(ethDate)
        assertEquals(gregDate, backToGreg)
    }

    @Test
    fun testGeezNumerals() {
        assertEquals("፩", GeezNumberFormatter.toGeez(1))
        assertEquals("፭", GeezNumberFormatter.toGeez(5))
        assertEquals("፲", GeezNumberFormatter.toGeez(10))
        assertEquals("፲፩", GeezNumberFormatter.toGeez(11))
        assertEquals("፳፭", GeezNumberFormatter.toGeez(25))
        assertEquals("፴", GeezNumberFormatter.toGeez(30))
        assertEquals("፻", GeezNumberFormatter.toGeez(100))

        assertEquals(1, GeezNumberFormatter.fromGeez("፩"))
        assertEquals(25, GeezNumberFormatter.fromGeez("፳፭"))
        assertEquals(30, GeezNumberFormatter.fromGeez("፴"))
    }

    @Test
    fun testEthiopianTimeConverter() {
        // 6:00 AM (Gregorian) = 12:00 daytime (Ethiopian)
        val ethMorning = EthiopianTimeConverter.gregorianToEthiopian(6, 0)
        assertEquals(12, ethMorning.hour)
        assertEquals(0, ethMorning.minute)
        assertTrue(ethMorning.isDaytime)

        // 7:00 AM (Gregorian) = 1:00 morning (Ethiopian)
        val eth7am = EthiopianTimeConverter.gregorianToEthiopian(7, 0)
        assertEquals(1, eth7am.hour)
        assertTrue(eth7am.isDaytime)

        // 12:00 PM (Noon Gregorian) = 6:00 midday (Ethiopian)
        val ethNoon = EthiopianTimeConverter.gregorianToEthiopian(12, 0)
        assertEquals(6, ethNoon.hour)
        assertTrue(ethNoon.isDaytime)

        // 6:00 PM (Sunset Gregorian) = 12:00 night (Ethiopian)
        val ethSunset = EthiopianTimeConverter.gregorianToEthiopian(18, 0)
        assertEquals(12, ethSunset.hour)
        assertFalse(ethSunset.isDaytime)

        // Invert back: Ethiopian 1:00 AM daytime -> Gregorian 7:00 AM
        val gregBack = EthiopianTimeConverter.ethiopianToGregorian(1, 0, isDaytime = true)
        assertEquals(7, gregBack.hour24)
    }

    @Test
    fun testBahireHasabComputus() {
        val result2016 = BahireHasabCalculator.calculate(2016)
        assertEquals(2016, result2016.ethiopianYear)
        assertEquals(7516, result2016.ameteAlem)
        // 7516 % 4 == 0 -> Evangelist John
        assertEquals(BahireHasabCalculator.Evangelist.JOHN, result2016.evangelist)

        // All movable feasts should be generated
        assertEquals(11, result2016.movableFeasts.size)
        val easter = result2016.movableFeasts.firstOrNull { it.nameEnglish.contains("Easter") }
        assertNotNull(easter)
    }

    @Test
    fun testHolidayEngine() {
        val holidays = HolidayEngine.getHolidaysForYear(2017)
        assertTrue(holidays.isNotEmpty())
        assertTrue(holidays.any { it.titleAmharic.contains("እንቁጣጣሽ") })
        assertTrue(holidays.any { it.titleAmharic.contains("መስቀል") })
        assertTrue(holidays.any { it.titleAmharic.contains("ገና") })
        assertTrue(holidays.any { it.titleAmharic.contains("ጥምቀት") })
        assertTrue(holidays.any { it.titleAmharic.contains("ዓድዋ") })
    }
}
