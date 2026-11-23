package com.example

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.example.calendar.core.BahireHasab
import com.example.calendar.core.EthiopianDate
import com.example.calendar.core.EthiopianSeason
import com.example.calendar.core.EthiopianTimeConverter
import com.example.calendar.core.GeezNumeral
import com.example.calendar.core.GregorianDate
import com.example.calendar.core.LeapYearCalculator
import com.example.calendar.data.AppDatabase
import com.example.calendar.data.EventDao
import com.example.calendar.data.EventEntity
import com.example.calendar.domain.EthiopianCalendarDomain
import com.example.calendar.engine.EthiopianCalendarEngine
import com.example.calendar.engine.HolidayEngine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.IOException

/**
 * Comprehensive automated functionality test suite for EthioCal Pro:
 * 1. Date conversion accuracy & bidirectional roundtrips
 * 2. Ethiopian time conversion (Standard <-> Ethiopian 12h)
 * 3. Ge'ez numeral conversion & parsing
 * 4. Bahire Hasab (Computus) feast and fast calculations
 * 5. HolidayEngine national, religious, and cultural events
 * 6. Age & date difference calculations
 * 7. Room Database & EventDao persistence
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class ConverterAndAppFunctionalityTest {

    private lateinit var database: AppDatabase
    private lateinit var eventDao: EventDao

    @Before
    fun createDb() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = Room.inMemoryDatabaseBuilder(context, AppDatabase::class.java)
            .allowMainThreadQueries()
            .build()
        eventDao = database.eventDao()
    }

    @After
    @Throws(IOException::class)
    fun closeDb() {
        database.close()
    }

    // -------------------------------------------------------------
    // 1. DATE CONVERTER FUNCTIONALITY TESTS
    // -------------------------------------------------------------
    @Test
    fun testDateConverterBidirectionalRoundTrip() {
        val sampleDates = listOf(
            EthiopianDate(2000, 1, 1),   // Millennium: Sep 12, 2007
            EthiopianDate(2015, 13, 6),  // Leap Pagume 6: Sep 11, 2023
            EthiopianDate(2016, 1, 1),   // Sep 12, 2023
            EthiopianDate(2016, 13, 5),  // Sep 10, 2024
            EthiopianDate(2017, 1, 1),   // Sep 11, 2024
            EthiopianDate(2017, 6, 23),  // Yekatit 23 (Adwa Victory)
            EthiopianDate(2018, 5, 15)   // Sample future date
        )

        for (eth in sampleDates) {
            val greg = EthiopianCalendarEngine.toGregorian(eth)
            val convertedBack = EthiopianCalendarEngine.toEthiopian(greg)
            assertEquals("Roundtrip mismatch for $eth", eth, convertedBack)
        }
    }

    @Test
    fun testPagumeLeapRules() {
        // Luke years are leap years in the 4-year cycle
        assertTrue("2015 should be leap year (Luke)", LeapYearCalculator.isEthiopianLeapYear(2015))
        assertFalse("2016 should not be leap year (John)", LeapYearCalculator.isEthiopianLeapYear(2016))
        assertFalse("2017 should not be leap year (Matthew)", LeapYearCalculator.isEthiopianLeapYear(2017))
        assertFalse("2018 should not be leap year (Mark)", LeapYearCalculator.isEthiopianLeapYear(2018))
        assertTrue("2019 should be leap year (Luke)", LeapYearCalculator.isEthiopianLeapYear(2019))

        val domain = EthiopianCalendarDomain.INSTANCE
        assertEquals(6, domain.getDaysInMonth(2015, 13))
        assertEquals(5, domain.getDaysInMonth(2016, 13))
        assertEquals(30, domain.getDaysInMonth(2017, 1))
    }

    @Test
    fun testEthiopianSeasons() {
        assertEquals(EthiopianSeason.METSEW_MEHER, EthiopianSeason.fromEthiopianDate(1, 28))
        assertEquals(EthiopianSeason.BEGA, EthiopianSeason.fromEthiopianDate(5, 10))
        assertEquals(EthiopianSeason.TSEDAY_BELG, EthiopianSeason.fromEthiopianDate(8, 15))
        assertEquals(EthiopianSeason.KIREMT, EthiopianSeason.fromEthiopianDate(11, 20))
    }

    // -------------------------------------------------------------
    // 2. TIME CONVERTER FUNCTIONALITY TESTS
    // -------------------------------------------------------------
    @Test
    fun testEthiopianTimeConverterBoundaries() {
        // 06:00 G.C. -> 12:00 daytime Ethiopian (ጥዋት / Dawn)
        val dawn = EthiopianTimeConverter.gregorianToEthiopian(6, 0)
        assertEquals(12, dawn.hour)
        assertEquals(0, dawn.minute)
        assertTrue(dawn.isDaytime)
        assertEquals("ጧት", dawn.period.amharic)

        // 12:00 G.C. -> 06:00 daytime Ethiopian (ከሰዓት / Midday)
        val noon = EthiopianTimeConverter.gregorianToEthiopian(12, 0)
        assertEquals(6, noon.hour)
        assertEquals(0, noon.minute)
        assertTrue(noon.isDaytime)
        assertEquals("ቀትር", noon.period.amharic)

        // 18:00 G.C. -> 12:00 nighttime Ethiopian (ምሽት / Sunset)
        val sunset = EthiopianTimeConverter.gregorianToEthiopian(18, 0)
        assertEquals(12, sunset.hour)
        assertEquals(0, sunset.minute)
        assertFalse(sunset.isDaytime)
        assertEquals("ምሽት", sunset.period.amharic)

        // 00:00 G.C. -> 06:00 nighttime Ethiopian (ሌሊት / Midnight)
        val midnight = EthiopianTimeConverter.gregorianToEthiopian(0, 0)
        assertEquals(6, midnight.hour)
        assertEquals(0, midnight.minute)
        assertFalse(midnight.isDaytime)
        assertEquals("እኩለ ሌሊት", midnight.period.amharic)
    }

    @Test
    fun testEthiopianTimeToGregorianReverse() {
        // Reverse 12:00 daytime -> 06:00 G.C.
        val gregDawn = EthiopianTimeConverter.ethiopianToGregorian(12, 0, isDaytime = true)
        assertEquals(6, gregDawn.hour24)
        assertEquals(0, gregDawn.minute)

        // Reverse 06:00 daytime -> 12:00 G.C.
        val gregNoon = EthiopianTimeConverter.ethiopianToGregorian(6, 0, isDaytime = true)
        assertEquals(12, gregNoon.hour24)
        assertEquals(0, gregNoon.minute)

        // Reverse 12:00 nighttime -> 18:00 G.C.
        val gregSunset = EthiopianTimeConverter.ethiopianToGregorian(12, 0, isDaytime = false)
        assertEquals(18, gregSunset.hour24)
        assertEquals(0, gregSunset.minute)

        // Reverse 06:00 nighttime -> 00:00 G.C.
        val gregMidnight = EthiopianTimeConverter.ethiopianToGregorian(6, 0, isDaytime = false)
        assertEquals(0, gregMidnight.hour24)
        assertEquals(0, gregMidnight.minute)

        // Custom time: 02:45 daytime Ethiopian -> 08:45 G.C.
        val gregCustom = EthiopianTimeConverter.ethiopianToGregorian(2, 45, isDaytime = true)
        assertEquals(8, gregCustom.hour24)
        assertEquals(45, gregCustom.minute)
    }

    // -------------------------------------------------------------
    // 3. GE'EZ NUMERAL CONVERTER FUNCTIONALITY TESTS
    // -------------------------------------------------------------
    @Test
    fun testGeezNumeralConversion() {
        assertEquals("፩", GeezNumeral.toGeez(1))
        assertEquals("፪", GeezNumeral.toGeez(2))
        assertEquals("፱", GeezNumeral.toGeez(9))
        assertEquals("፲", GeezNumeral.toGeez(10))
        assertEquals("፲፩", GeezNumeral.toGeez(11))
        assertEquals("፳", GeezNumeral.toGeez(20))
        assertEquals("፳፭", GeezNumeral.toGeez(25))
        assertEquals("፺፱", GeezNumeral.toGeez(99))
        assertEquals("፻", GeezNumeral.toGeez(100))
        assertEquals("፻፩", GeezNumeral.toGeez(101))
        assertEquals("፪፻", GeezNumeral.toGeez(200))
        assertEquals("፱፻፺፱", GeezNumeral.toGeez(999))
        assertEquals("፲፻", GeezNumeral.toGeez(1000))
        assertEquals("፳፻", GeezNumeral.toGeez(2000))
        assertEquals("፳፻፲፯", GeezNumeral.toGeez(2017))
        assertEquals("፲፱፻፺፱", GeezNumeral.toGeez(1999))
        assertEquals("፼", GeezNumeral.toGeez(10000))
    }

    @Test
    fun testGeezNumeralParsing() {
        assertEquals(1, GeezNumeral.fromGeez("፩"))
        assertEquals(10, GeezNumeral.fromGeez("፲"))
        assertEquals(25, GeezNumeral.fromGeez("፳፭"))
        assertEquals(100, GeezNumeral.fromGeez("፻"))
        assertEquals(2017, GeezNumeral.fromGeez("፳፻፲፯"))
        assertEquals(1999, GeezNumeral.fromGeez("፲፱፻፺፱"))
    }

    // -------------------------------------------------------------
    // 4. BAHIRE HASAB (COMPUTUS) LITURGICAL FUNCTIONALITY TESTS
    // -------------------------------------------------------------
    @Test
    fun testBahireHasab2017Computus() {
        val year = 2017
        assertEquals(7517, BahireHasab.ameteAlem(year))
        assertEquals(11, BahireHasab.wenber(year))
        assertEquals(1, BahireHasab.abeqte(year))
        assertEquals(29, BahireHasab.metqi(year))
        assertEquals(1, BahireHasab.metqiMonth(year)) // Meskerem

        // Movable feast dates in 2017 E.C.
        val nenewe = BahireHasab.nenewe(year)
        val abiyTsom = BahireHasab.abiyTsom(year)
        val debreZeit = BahireHasab.debreZeit(year)
        val hosanna = BahireHasab.hosanna(year)
        val siklet = BahireHasab.siklet(year)
        val fasika = BahireHasab.fasika(year)
        val rikbeKahnat = BahireHasab.rikbeKahnat(year)
        val erget = BahireHasab.erget(year)
        val paraclete = BahireHasab.paraclete(year)

        // Nineveh Fast: Yakatit 3, 2017 E.C.
        assertEquals(EthiopianDate(2017, 6, 3), nenewe)
        // Great Lent starts: Yakatit 17, 2017 E.C. (14 days after Nineveh)
        assertEquals(EthiopianDate(2017, 6, 17), abiyTsom)
        // Easter: Miazia 12, 2017 E.C.
        assertEquals(EthiopianDate(2017, 8, 12), fasika)

        // Strict chronological progression assertion
        val jdnNenewe = EthiopianCalendarEngine.ethiopianToJdn(nenewe)
        val jdnAbiyTsom = EthiopianCalendarEngine.ethiopianToJdn(abiyTsom)
        val jdnDebreZeit = EthiopianCalendarEngine.ethiopianToJdn(debreZeit)
        val jdnHosanna = EthiopianCalendarEngine.ethiopianToJdn(hosanna)
        val jdnSiklet = EthiopianCalendarEngine.ethiopianToJdn(siklet)
        val jdnFasika = EthiopianCalendarEngine.ethiopianToJdn(fasika)
        val jdnRikbe = EthiopianCalendarEngine.ethiopianToJdn(rikbeKahnat)
        val jdnErget = EthiopianCalendarEngine.ethiopianToJdn(erget)
        val jdnParaclete = EthiopianCalendarEngine.ethiopianToJdn(paraclete)

        assertTrue(jdnNenewe < jdnAbiyTsom)
        assertTrue(jdnAbiyTsom < jdnDebreZeit)
        assertTrue(jdnDebreZeit < jdnHosanna)
        assertTrue(jdnHosanna < jdnSiklet)
        assertTrue(jdnSiklet < jdnFasika)
        assertTrue(jdnFasika < jdnRikbe)
        assertTrue(jdnRikbe < jdnErget)
        assertTrue(jdnErget < jdnParaclete)
    }

    // -------------------------------------------------------------
    // 5. HOLIDAY ENGINE FUNCTIONALITY TESTS
    // -------------------------------------------------------------
    @Test
    fun testNationalAndReligiousHolidays() {
        val holidays2017 = HolidayEngine.getHolidaysForYear(2017)
        assertTrue("Year 2017 should have multiple registered holidays", holidays2017.isNotEmpty())

        val enkutatash = holidays2017.find { it.ethiopianDate.month == 1 && it.ethiopianDate.day == 1 }
        assertNotNull("Enkutatash should be present on Meskerem 1", enkutatash)
        assertTrue(enkutatash!!.isPublicHoliday)

        val meskel = holidays2017.find { it.ethiopianDate.month == 1 && it.ethiopianDate.day == 17 }
        assertNotNull("Meskel should be present on Meskerem 17", meskel)

        val timket = holidays2017.find { it.ethiopianDate.month == 5 && it.ethiopianDate.day == 11 }
        assertNotNull("Timket should be present on Tir 11", timket)

        val adwa = holidays2017.find { it.ethiopianDate.month == 6 && it.ethiopianDate.day == 23 }
        assertNotNull("Adwa victory should be present on Yekatit 23", adwa)
    }

    // -------------------------------------------------------------
    // 6. AGE & DATE DIFFERENCE LOGIC TESTS
    // -------------------------------------------------------------
    @Test
    fun testDateDifferenceComputation() {
        val start = EthiopianDate(2016, 1, 1)
        val end = EthiopianDate(2016, 2, 1)
        val jdnStart = EthiopianCalendarEngine.ethiopianToJdn(start)
        val jdnEnd = EthiopianCalendarEngine.ethiopianToJdn(end)

        val diffDays = (jdnEnd - jdnStart).toInt()
        assertEquals("Difference between Meskerem 1 and Tikimt 1 must be exactly 30 days", 30, diffDays)

        val fullWeeks = diffDays / 7
        val remDays = diffDays % 7
        assertEquals(4, fullWeeks)
        assertEquals(2, remDays)
    }

    // -------------------------------------------------------------
    // 7. EVENT PERSISTENCE & ROOM DAO TESTS
    // -------------------------------------------------------------
    @Test
    fun testEventPersistenceLifecycle() = runBlocking {
        val testEvent = EventEntity(
            title = "Enkutatash Celebration",
            description = "Family gathering for Ethiopian New Year",
            category = "CULTURAL",
            ethiopianYear = 2017,
            ethiopianMonth = 1,
            ethiopianDay = 1,
            gregorianYear = 2024,
            gregorianMonth = 9,
            gregorianDay = 11,
            hour = 10,
            minute = 0,
            isAllDay = true
        )

        // 1. Insert Event
        val id = eventDao.insertEvent(testEvent)
        assertTrue("Event ID should be auto-generated > 0", id > 0)

        // 2. Fetch by Day
        val eventsOnDay = eventDao.getEventsForEthiopianDay(2017, 1, 1).first()
        assertEquals(1, eventsOnDay.size)
        assertEquals("Enkutatash Celebration", eventsOnDay[0].title)

        // 3. Search Event
        val searchResults = eventDao.searchEvents("Enkutatash").first()
        assertEquals(1, searchResults.size)
        assertEquals(id, searchResults[0].id)

        // 4. Update Event
        val updated = eventsOnDay[0].copy(isCompleted = true, title = "Enkutatash 2017 Done")
        eventDao.updateEvent(updated)
        val refreshed = eventDao.getEventById(id)
        assertNotNull(refreshed)
        assertTrue(refreshed!!.isCompleted)
        assertEquals("Enkutatash 2017 Done", refreshed.title)

        // 5. Delete Event
        eventDao.deleteEventById(id)
        val afterDelete = eventDao.getEventById(id)
        assertEquals(null, afterDelete)
    }
}
