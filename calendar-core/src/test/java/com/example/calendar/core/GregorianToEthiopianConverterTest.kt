package com.example.calendar.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar

/**
 * Comprehensive automated tests for [GregorianToEthiopianConverter].
 * Verifies accuracy across centuries, leap year boundaries, holiday recognition,
 * Ge'ez formatting, season mapping, and string parsing.
 */
class GregorianToEthiopianConverterTest {

    private val converter = GregorianToEthiopianConverter.INSTANCE

    @Test
    fun testStandardGregorianToEthiopianConversions() {
        // September 11, 2024 -> Meskerem 1, 2017 E.C. (Enkutatash / Ethiopian New Year)
        val res1 = converter.convert(2024, 9, 11)
        assertEquals(2017, res1.ethiopianDate.year)
        assertEquals(1, res1.ethiopianDate.month)
        assertEquals(1, res1.ethiopianDate.day)
        assertEquals("Wednesday", res1.dayOfWeekEnglish)
        assertEquals("ረቡዕ", res1.dayOfWeekAmharic)
        assertEquals("፩", res1.geezDay)
        assertEquals("፳፻፲፯", res1.geezYear)
        assertEquals("ዘመነ ማቴዎስ", res1.evangelistAmharic)
        assertEquals("Year of Matthew", res1.evangelistEnglish)
        assertNotNull(res1.majorHolidayAmharic)
        assertTrue(res1.majorHolidayAmharic!!.contains("እንቁጣጣሽ"))

        // January 7, 2025 -> Tahsas 29, 2017 E.C. (Genna / Ethiopian Christmas)
        val resGenna = converter.convert(2025, 1, 7)
        assertEquals(2017, resGenna.ethiopianDate.year)
        assertEquals(4, resGenna.ethiopianDate.month)
        assertEquals(29, resGenna.ethiopianDate.day)
        assertEquals("ማክሰኞ", resGenna.dayOfWeekAmharic)
        assertNotNull(resGenna.majorHolidayAmharic)
        assertTrue(resGenna.majorHolidayAmharic!!.contains("ገና"))

        // January 19, 2025 -> Tir 11, 2017 E.C. (Timket / Epiphany)
        val resTimket = converter.convert(2025, 1, 19)
        assertEquals(2017, resTimket.ethiopianDate.year)
        assertEquals(5, resTimket.ethiopianDate.month)
        assertEquals(11, resTimket.ethiopianDate.day)
        assertEquals("እሑድ", resTimket.dayOfWeekAmharic)
        assertNotNull(resTimket.majorHolidayAmharic)
        assertTrue(resTimket.majorHolidayAmharic!!.contains("ጥምቀት"))
    }

    @Test
    fun testEthiopianMillenniumConversion() {
        // September 12, 2007 -> Meskerem 1, 2000 E.C. (Ethiopian Millennium)
        // Note: 1999 E.C. was leap year (Pagume had 6 days), hence New Year fell on Sept 12
        val resMillennium = converter.convert(2007, 9, 12)
        assertEquals(2000, resMillennium.ethiopianDate.year)
        assertEquals(1, resMillennium.ethiopianDate.month)
        assertEquals(1, resMillennium.ethiopianDate.day)
        assertEquals("፳፻", resMillennium.geezYear)
        assertEquals("Wednesday", resMillennium.dayOfWeekEnglish)
    }

    @Test
    fun testLeapYearConversions() {
        // February 29, 2024 (Leap Day) -> Yekatit 21, 2016 E.C.
        val resLeapDay = converter.convert(2024, 2, 29)
        assertEquals(2016, resLeapDay.ethiopianDate.year)
        assertEquals(6, resLeapDay.ethiopianDate.month) // Yekatit
        assertEquals(21, resLeapDay.ethiopianDate.day)
        assertEquals("Thursday", resLeapDay.dayOfWeekEnglish)
        assertTrue(resLeapDay.isLeapYearGregorian)

        // September 12, 2023 -> Meskerem 1, 2016 E.C. (2015 E.C. had Pagume 6)
        val resPostLeap = converter.convert(2023, 9, 12)
        assertEquals(2016, resPostLeap.ethiopianDate.year)
        assertEquals(1, resPostLeap.ethiopianDate.month)
        assertEquals(1, resPostLeap.ethiopianDate.day)
    }

    @Test
    fun testCalendarAndDateOverloads() {
        val cal = Calendar.getInstance()
        cal.set(2024, Calendar.SEPTEMBER, 11)
        val res = converter.convert(cal)
        assertEquals(2017, res.ethiopianDate.year)
        assertEquals(1, res.ethiopianDate.month)
        assertEquals(1, res.ethiopianDate.day)

        val date = cal.time
        val resFromDate = converter.convert(date)
        assertEquals(res.ethiopianDate, resFromDate.ethiopianDate)
    }

    @Test
    fun testDateStringParsing() {
        val parsed1 = converter.parseAndConvert("2024-09-11")
        assertTrue(parsed1.isSuccess)
        assertEquals(EthiopianDate(2017, 1, 1), parsed1.getOrNull()?.ethiopianDate)

        val parsedSlash = converter.parseAndConvert("2025/01/07")
        assertTrue(parsedSlash.isSuccess)
        assertEquals(EthiopianDate(2017, 4, 29), parsedSlash.getOrNull()?.ethiopianDate)

        // Invalid dates
        val invalidFormat = converter.parseAndConvert("not-a-date")
        assertTrue(invalidFormat.isFailure)

        val invalidDate = converter.parseAndConvert("2023-02-29") // 2023 is not a leap year
        assertTrue(invalidDate.isFailure)
    }

    @Test
    fun testDateValidationAndBoundaries() {
        assertTrue(converter.isValidGregorianDate(2024, 2, 29))
        assertFalse(converter.isValidGregorianDate(2023, 2, 29)) // Non leap year
        assertFalse(converter.isValidGregorianDate(2024, 4, 31)) // April has 30 days
        assertFalse(converter.isValidGregorianDate(2024, 13, 1)) // No 13th month in Gregorian
        assertFalse(converter.isValidGregorianDate(2024, 0, 1))
        assertFalse(converter.isValidGregorianDate(2024, 5, 0))

        assertEquals(31, converter.getDaysInMonth(2024, 1))
        assertEquals(29, converter.getDaysInMonth(2024, 2))
        assertEquals(28, converter.getDaysInMonth(2025, 2))
        assertEquals(30, converter.getDaysInMonth(2024, 4))

        assertNull(converter.convertOrNull(2023, 2, 29))
        assertNotNull(converter.convertOrNull(2024, 2, 29))
    }

    @Test
    fun testSeasonsAndEvangelists() {
        // Meskerem 10 (Sept 20) -> Kiremt (Rainy season until Meskerem 25)
        val resSep = converter.convert(2024, 9, 20)
        assertEquals("ክረምት", resSep.seasonAmharic)

        // Tikimt 15 (Oct 25) -> Metsew Meher (Autumn / Harvest)
        val resOct = converter.convert(2024, 10, 25)
        assertEquals("መፀው (መኸር)", resOct.seasonAmharic)

        // Yekatit -> Bega (Dry / Summer)
        val resFeb = converter.convert(2024, 2, 15)
        assertEquals("በጋ", resFeb.seasonAmharic)

        // 2017 E.C. = Matthew (ማቴዎስ)
        // 2018 E.C. = Mark (ማርቆስ)
        // 2019 E.C. = Luke (ሉቃስ)
        // 2020 E.C. = John (ዮሐንስ)
        val res2017 = converter.convert(2024, 9, 11)
        assertEquals("ዘመነ ማቴዎስ", res2017.evangelistAmharic)

        val res2018 = converter.convert(2025, 9, 11)
        assertEquals("ዘመነ ማርቆስ", res2018.evangelistAmharic)
    }
}
