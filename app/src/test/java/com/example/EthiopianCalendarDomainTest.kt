package com.example

import com.example.calendar.domain.EthiopianCalendarDomain
import com.example.calendar.domain.EthiopianMonth
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.GregorianDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class EthiopianCalendarDomainTest {

    private lateinit var domain: EthiopianCalendarDomain

    @Before
    fun setUp() {
        domain = EthiopianCalendarDomain.INSTANCE
    }

    // ==========================================
    // 1. MONTH DEFINITIONS TESTS
    // ==========================================

    @Test
    fun testAllThirteenMonthsExist() {
        val months = domain.getAllMonths()
        assertEquals(13, months.size)
        assertEquals(EthiopianMonth.MESKEREM, months[0])
        assertEquals(EthiopianMonth.PAGUME, months[12])
    }

    @Test
    fun testMonthLengthsInCommonYear() {
        val commonYear = 2016
        assertFalse(domain.isLeapYear(commonYear))

        // Months 1 to 12 must all have 30 days
        for (m in 1..12) {
            assertEquals("Month $m should have 30 days", 30, domain.getDaysInMonth(commonYear, m))
        }

        // Pagume (month 13) must have 5 days in a common year
        assertEquals(5, domain.getDaysInMonth(commonYear, EthiopianMonth.PAGUME))
        assertEquals(365, domain.getDaysInYear(commonYear))
    }

    @Test
    fun testMonthLengthsInLeapYear() {
        val leapYear = 2015
        assertTrue(domain.isLeapYear(leapYear))

        // Months 1 to 12 have 30 days
        for (m in 1..12) {
            assertEquals(30, domain.getDaysInMonth(leapYear, m))
        }

        // Pagume (month 13) must have 6 days in a leap year
        assertEquals(6, domain.getDaysInMonth(leapYear, EthiopianMonth.PAGUME))
        assertEquals(366, domain.getDaysInYear(leapYear))
    }

    @Test
    fun testDateValidation() {
        // Valid regular date
        assertTrue(domain.isValidDate(2016, 1, 30))
        // Invalid day in regular month
        assertFalse(domain.isValidDate(2016, 1, 31))

        // Valid Pagume in common year (5 days)
        assertTrue(domain.isValidDate(2016, 13, 5))
        // Invalid 6th day in common year Pagume
        assertFalse(domain.isValidDate(2016, 13, 6))

        // Valid 6th day in leap year Pagume
        assertTrue(domain.isValidDate(2015, 13, 6))
        // Invalid 7th day
        assertFalse(domain.isValidDate(2015, 13, 7))

        // Invalid month
        assertFalse(domain.isValidDate(2016, 0, 10))
        assertFalse(domain.isValidDate(2016, 14, 1))
    }

    // ==========================================
    // 2. LEAP YEAR & EVANGELIST TESTS
    // ==========================================

    @Test
    fun testLeapYearRule() {
        // Years where (year % 4 == 3) are leap years (Luke years)
        assertTrue(domain.isLeapYear(1999))
        assertTrue(domain.isLeapYear(2003))
        assertTrue(domain.isLeapYear(2007))
        assertTrue(domain.isLeapYear(2011))
        assertTrue(domain.isLeapYear(2015))
        assertTrue(domain.isLeapYear(2019))
        assertTrue(domain.isLeapYear(2023))

        // Common years
        assertFalse(domain.isLeapYear(2014))
        assertFalse(domain.isLeapYear(2016))
        assertFalse(domain.isLeapYear(2017))
        assertFalse(domain.isLeapYear(2018))
    }

    @Test
    fun testEvangelistCycle() {
        assertEquals(EthiopianCalendarDomain.Evangelist.LUKE, domain.getEvangelist(2015))
        assertEquals(EthiopianCalendarDomain.Evangelist.JOHN, domain.getEvangelist(2016))
        assertEquals(EthiopianCalendarDomain.Evangelist.MATTHEW, domain.getEvangelist(2017))
        assertEquals(EthiopianCalendarDomain.Evangelist.MARK, domain.getEvangelist(2018))
        assertEquals(EthiopianCalendarDomain.Evangelist.LUKE, domain.getEvangelist(2019))
    }

    // ==========================================
    // 3. CONVERSION ALGORITHM TESTS
    // ==========================================

    @Test
    fun testEthiopianToGregorianMillennium() {
        // Meskerem 1, 2000 E.C. was September 12, 2007 G.C.
        val greg = domain.toGregorian(2000, 1, 1)
        assertEquals(2007, greg.year)
        assertEquals(9, greg.month)
        assertEquals(12, greg.day)

        // Round-trip
        val ethBack = domain.toEthiopian(greg)
        assertEquals(2000, ethBack.year)
        assertEquals(1, ethBack.month)
        assertEquals(1, ethBack.day)
    }

    @Test
    fun testPagumeLeapBoundaryConversion() {
        // 2015 E.C. Pagume 6 was September 11, 2023 G.C.
        val pagume6 = EthiopianDate(2015, 13, 6)
        val gregPagume6 = domain.toGregorian(pagume6)
        assertEquals(2023, gregPagume6.year)
        assertEquals(9, gregPagume6.month)
        assertEquals(11, gregPagume6.day)

        // The following day: Meskerem 1, 2016 E.C. was September 12, 2023 G.C.
        val meskerem1 = EthiopianDate(2016, 1, 1)
        val gregMeskerem1 = domain.toGregorian(meskerem1)
        assertEquals(2023, gregMeskerem1.year)
        assertEquals(9, gregMeskerem1.month)
        assertEquals(12, gregMeskerem1.day)

        // Reverse check
        assertEquals(pagume6, domain.toEthiopian(gregPagume6))
        assertEquals(meskerem1, domain.toEthiopian(gregMeskerem1))
    }

    @Test
    fun testCommonYearPagumeBoundaryConversion() {
        // 2016 E.C. Pagume 5 was September 10, 2024 G.C.
        val pagume5 = EthiopianDate(2016, 13, 5)
        val gregPagume5 = domain.toGregorian(pagume5)
        assertEquals(2024, gregPagume5.year)
        assertEquals(9, gregPagume5.month)
        assertEquals(10, gregPagume5.day)

        // The following day: Meskerem 1, 2017 E.C. was September 11, 2024 G.C.
        val meskerem1 = EthiopianDate(2017, 1, 1)
        val gregMeskerem1 = domain.toGregorian(meskerem1)
        assertEquals(2024, gregMeskerem1.year)
        assertEquals(9, gregMeskerem1.month)
        assertEquals(11, gregMeskerem1.day)
    }

    @Test
    fun testDayOfWeekAndArithmetic() {
        // Meskerem 1, 2000 (Sept 12, 2007) was a Wednesday (3)
        val ethDate = EthiopianDate(2000, 1, 1)
        assertEquals(3, domain.getDayOfWeek(ethDate))

        // Add 7 days -> Meskerem 8, 2000 (also Wednesday)
        val nextWeek = domain.addDays(ethDate, 7)
        assertEquals(8, nextWeek.day)
        assertEquals(3, domain.getDayOfWeek(nextWeek))

        // Subtract 1 day -> Pagume 6, 1999 (Tuesday, 2)
        val prevDay = domain.subtractDays(ethDate, 1)
        assertEquals(1999, prevDay.year)
        assertEquals(13, prevDay.month)
        assertEquals(6, prevDay.day)
        assertEquals(2, domain.getDayOfWeek(prevDay))

        // Difference in days
        assertEquals(7L, domain.daysBetween(ethDate, nextWeek))
        assertEquals(-1L, domain.daysBetween(ethDate, prevDay))
    }
}
