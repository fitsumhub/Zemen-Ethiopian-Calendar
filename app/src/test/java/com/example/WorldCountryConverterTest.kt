package com.example

import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.GregorianDate
import com.example.calendar.engine.WorldCountryEngine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class WorldCountryConverterTest {

    @Test
    fun testEuropeanCalendarFormatsAndCalculations() {
        // Enkutatash 2017: Meskerem 1, 2017 E.C. = Sep 11, 2024 G.C.
        val ethDate = EthiopianDate(2017, 1, 1)
        val gregDate = GregorianDate(2024, 9, 11)
        val jdn = EthiopianCalendarEngine.ethiopianToJdn(ethDate)

        val result = WorldCountryEngine.computeEuropeanAndWorldCalendarDetails(ethDate, gregDate, jdn)

        // Formats
        assertEquals("11.09.2024", result.gregorianFormattedEu)
        assertEquals("11/09/2024", result.gregorianFormattedUk)
        assertEquals("11. September 2024", result.gregorianFormattedDe)
        assertEquals("09/11/2024", result.gregorianFormattedUs)
        assertEquals("2024-09-11", result.iso8601)

        // Julian Calendar should be 13 days behind Gregorian in 21st century
        // Sep 11 - 13 days = Aug 29
        assertEquals(2024, result.julianYear)
        assertEquals(8, result.julianMonth)
        assertEquals(29, result.julianDay)

        // Coptic calendar should be 1 Thout (Tut) 1741 A.M. (2017 - 276 = 1741)
        assertEquals(1741, result.copticYear)
        assertEquals(1, result.copticDay)

        // Season & Quarter in Europe
        // Sep 11 is European Summer (summer ends Sep 22)
        assertEquals("Summer (Sommer / Été)", result.europeanSeasonEn)
        assertEquals("Q3 (Jul–Sep)", result.europeanQuarter)
    }

    @Test
    fun testEuropeanWinterSeasonAndYearOffset() {
        // Ethiopian Christmas (Genna): Tahsas 29, 2017 E.C. = Jan 7, 2025 G.C.
        val ethDate = EthiopianDate(2017, 4, 29)
        val gregDate = GregorianDate(2025, 1, 7)
        val jdn = EthiopianCalendarEngine.ethiopianToJdn(ethDate)

        val result = WorldCountryEngine.computeEuropeanAndWorldCalendarDetails(ethDate, gregDate, jdn)

        // Jan 7 is European Winter
        assertEquals("Winter (Winter / Hiver)", result.europeanSeasonEn)
        assertEquals("Q1 (Jan–Mar)", result.europeanQuarter)
        assertTrue(result.yearOffsetExplanation.contains("8 years gap"))
    }

    @Test
    fun testWorldTimeConversionsFromAddisAbaba() {
        // Suppose it is 12:00 PM (Midday 12:00) in Addis Ababa EAT (UTC+3)
        // London in winter (GMT UTC+0) should be 09:00 AM (3 hours behind)
        // Berlin in winter (CET UTC+1) should be 10:00 AM (2 hours behind)
        // Dubai (GST UTC+4) should be 01:00 PM (1 hour ahead)
        val results = WorldCountryEngine.convertAddisAbabaTimeToWorldCities(
            addisHour24 = 12,
            addisMinute = 0,
            referenceYear = 2026,
            referenceMonth = 1,
            referenceDay = 15
        )

        val london = results.firstOrNull { it.city.id == "lon" }
        assertNotNull("London should exist in city list", london)
        assertEquals(9, london!!.hour24)
        assertEquals(0, london.minute)
        assertEquals(-3.0, london.differenceFromAddisHours, 0.1)

        val berlin = results.firstOrNull { it.city.id == "ber" }
        assertNotNull("Berlin should exist in city list", berlin)
        assertEquals(10, berlin!!.hour24)
        assertEquals(0, berlin.minute)
        assertEquals(-2.0, berlin.differenceFromAddisHours, 0.1)

        val dubai = results.firstOrNull { it.city.id == "dxb" }
        assertNotNull("Dubai should exist in city list", dubai)
        assertEquals(13, dubai!!.hour24)
        assertEquals(0, dubai.minute)
        assertEquals(1.0, dubai.differenceFromAddisHours, 0.1)
    }

    @Test
    fun testReverseWorldCityTimeToAddisAbaba() {
        // If it is 10:00 in Berlin (CET UTC+1 in winter), what time is it in Addis Ababa (UTC+3)?
        // Should be 12:00 in Addis Ababa
        val (addisH, addisM) = WorldCountryEngine.convertWorldCityTimeToAddisAbaba(
            cityId = "ber",
            hour24 = 10,
            minute = 30,
            referenceYear = 2026,
            referenceMonth = 1,
            referenceDay = 15
        )
        assertEquals(12, addisH)
        assertEquals(30, addisM)
    }

    @Test
    fun testCountryProfilesIntegrity() {
        assertTrue("Country profiles must not be empty", WorldCountryEngine.COUNTRY_PROFILES.isNotEmpty())
        val germany = WorldCountryEngine.COUNTRY_PROFILES.find { it.id == "de" }
        assertNotNull("Germany profile must exist", germany)
        assertTrue(germany!!.dialCode == "+49")
        assertTrue(germany.currencySymbol.contains("€"))

        val uk = WorldCountryEngine.COUNTRY_PROFILES.find { it.id == "uk" }
        assertNotNull("UK profile must exist", uk)
        assertTrue(uk!!.dialCode == "+44")
        assertTrue(uk.currencySymbol.contains("£"))
    }
}
