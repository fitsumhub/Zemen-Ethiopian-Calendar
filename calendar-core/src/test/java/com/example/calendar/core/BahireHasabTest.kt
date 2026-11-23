package com.example.calendar.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Rigorous mathematical verification of the Bahire Hasab (Computus) algorithms
 * in :calendar-core across canonical years (2015, 2016, 2017, 2018).
 */
class BahireHasabTest {

    @Test
    fun testAmeteAlemAndEvangelistCycle() {
        // 2015 E.C. (Luke / ሉቃስ - Leap Year)
        assertEquals(7515, BahireHasab.ameteAlem(2015))
        assertEquals(LeapYearCalculator.Evangelist.LUKE, BahireHasab.evangelist(2015))
        assertTrue(BahireHasab.evangelist(2015).isLeapYear)

        // 2016 E.C. (John / ዮሐንስ)
        assertEquals(7516, BahireHasab.ameteAlem(2016))
        assertEquals(LeapYearCalculator.Evangelist.JOHN, BahireHasab.evangelist(2016))
        assertFalse(BahireHasab.evangelist(2016).isLeapYear)

        // 2017 E.C. (Matthew / ማቴዎስ)
        assertEquals(7517, BahireHasab.ameteAlem(2017))
        assertEquals(LeapYearCalculator.Evangelist.MATTHEW, BahireHasab.evangelist(2017))
        assertFalse(BahireHasab.evangelist(2017).isLeapYear)

        // 2018 E.C. (Mark / ማርቆስ)
        assertEquals(7518, BahireHasab.ameteAlem(2018))
        assertEquals(LeapYearCalculator.Evangelist.MARK, BahireHasab.evangelist(2018))
        assertFalse(BahireHasab.evangelist(2018).isLeapYear)
    }

    @Test
    fun testComputusMathematicalProperties2017() {
        // Year 2017 E.C. canonical values:
        // Amete Alem = 2017 + 5500 = 7517
        // Medeb = 7517 % 19 = 12
        // Wenber = 12 - 1 = 11
        // Abekte = (11 * 11) % 30 = 121 % 30 = 1
        // Metqi = 30 - 1 = 29 (in Meskerem since > 14)
        assertEquals(11, BahireHasab.wenber(2017))
        assertEquals(1, BahireHasab.abeqte(2017))
        assertEquals(29, BahireHasab.metqi(2017))
        assertEquals(1, BahireHasab.metqiMonth(2017)) // Meskerem
        assertEquals(EthiopianDate(2017, 1, 29), BahireHasab.metqiDate(2017))

        // Nineveh: Yakatit 3, 2017 E.C.
        val nenewe = BahireHasab.nenewe(2017)
        assertEquals(EthiopianDate(2017, 6, 3), nenewe)

        // Fasika: Miazia 12, 2017 E.C. (April 20, 2025 G.C.)
        val fasika = BahireHasab.fasika(2017)
        assertEquals(EthiopianDate(2017, 8, 12), fasika)

        // Great Lent starts: Yakatit 17, 2017 E.C.
        val abiyTsom = BahireHasab.abiyTsom(2017)
        assertEquals(EthiopianDate(2017, 6, 17), abiyTsom)

        // Good Friday: Miazia 10, 2017 E.C.
        val siklet = BahireHasab.siklet(2017)
        assertEquals(EthiopianDate(2017, 8, 10), siklet)
    }

    @Test
    fun testComputusMathematicalProperties2016() {
        // Year 2016 E.C. canonical values:
        // Amete Alem = 7516
        // Medeb = 7516 % 19 = 11
        // Wenber = 10
        // Abekte = (10 * 11) % 30 = 20
        // Metqi = 30 - 20 = 10 (in Tikimt since <= 14)
        assertEquals(10, BahireHasab.wenber(2016))
        assertEquals(20, BahireHasab.abeqte(2016))
        assertEquals(10, BahireHasab.metqi(2016))
        assertEquals(2, BahireHasab.metqiMonth(2016)) // Tikimt
        assertEquals(EthiopianDate(2016, 2, 10), BahireHasab.metqiDate(2016))

        // Nineveh: Yakatit 18, 2016 E.C. (Feb 26, 2024 G.C.)
        val nenewe = BahireHasab.nenewe(2016)
        assertEquals(EthiopianDate(2016, 6, 18), nenewe)

        // Fasika: Miazia 27, 2016 E.C. (May 5, 2024 G.C.)
        val fasika = BahireHasab.fasika(2016)
        assertEquals(EthiopianDate(2016, 8, 27), fasika)
    }

    @Test
    fun testComputusMathematicalProperties2015() {
        // Year 2015 E.C. canonical values:
        // Amete Alem = 7515
        // Wenber = 9
        // Abekte = (9 * 11) % 30 = 9
        // Metqi = 30 - 9 = 21 (in Meskerem)
        assertEquals(9, BahireHasab.wenber(2015))
        assertEquals(9, BahireHasab.abeqte(2015))
        assertEquals(21, BahireHasab.metqi(2015))
        assertEquals(1, BahireHasab.metqiMonth(2015))

        // Nineveh: Tir 29, 2015 E.C. (Feb 6, 2023 G.C.)
        val nenewe = BahireHasab.nenewe(2015)
        assertEquals(EthiopianDate(2015, 5, 29), nenewe)

        // Fasika: Miazia 8, 2015 E.C. (April 16, 2023 G.C.)
        val fasika = BahireHasab.fasika(2015)
        assertEquals(EthiopianDate(2015, 8, 8), fasika)
    }

    @Test
    fun testCanonicalDayOfWeekPropertiesForAllFeastsAcrossCenturies() {
        // Canonical invariants in Ethiopian Orthodox computus:
        // 1. Nineveh ALWAYS starts on a Monday (dow = 1)
        // 2. Great Lent ALWAYS starts on a Monday (dow = 1)
        // 3. Debre Zeit ALWAYS falls on a Sunday (dow = 7)
        // 4. Hosanna ALWAYS falls on a Sunday (dow = 7)
        // 5. Siklet ALWAYS falls on a Friday (dow = 5)
        // 6. Fasika (Easter) ALWAYS falls on a Sunday (dow = 7)
        // 7. Rikbe Kahnat ALWAYS falls on a Wednesday (dow = 3)
        // 8. Ascension (Erget) ALWAYS falls on a Thursday (dow = 4)
        // 9. Pentecost (Paraclete) ALWAYS falls on a Sunday (dow = 7)
        // 10. Apostles' Fast ALWAYS starts on a Monday (dow = 1)
        // 11. Fast of Salvation ALWAYS starts on a Wednesday (dow = 3)

        for (year in 2000..2050) {
            val nenewe = BahireHasab.nenewe(year)
            assertEquals("Nineveh must be Monday in $year", 1, EthiopianDateConverter.getDayOfWeek(nenewe))

            val abiyTsom = BahireHasab.abiyTsom(year)
            assertEquals("Great Lent must be Monday in $year", 1, EthiopianDateConverter.getDayOfWeek(abiyTsom))

            val debreZeit = BahireHasab.debreZeit(year)
            assertEquals("Debre Zeit must be Sunday in $year", 7, EthiopianDateConverter.getDayOfWeek(debreZeit))

            val hosanna = BahireHasab.hosanna(year)
            assertEquals("Hosanna must be Sunday in $year", 7, EthiopianDateConverter.getDayOfWeek(hosanna))

            val siklet = BahireHasab.siklet(year)
            assertEquals("Good Friday must be Friday in $year", 5, EthiopianDateConverter.getDayOfWeek(siklet))

            val fasika = BahireHasab.fasika(year)
            assertEquals("Fasika must be Sunday in $year", 7, EthiopianDateConverter.getDayOfWeek(fasika))

            val rikbeKahnat = BahireHasab.rikbeKahnat(year)
            assertEquals("Rikbe Kahnat must be Wednesday in $year", 3, EthiopianDateConverter.getDayOfWeek(rikbeKahnat))

            val erget = BahireHasab.erget(year)
            assertEquals("Erget must be Thursday in $year", 4, EthiopianDateConverter.getDayOfWeek(erget))

            val paraclete = BahireHasab.paraclete(year)
            assertEquals("Pentecost must be Sunday in $year", 7, EthiopianDateConverter.getDayOfWeek(paraclete))

            val hawaryat = BahireHasab.tsomeHawaryat(year)
            assertEquals("Apostles' Fast must be Monday in $year", 1, EthiopianDateConverter.getDayOfWeek(hawaryat))

            val dihnet = BahireHasab.tsomeDihnet(year)
            assertEquals("Fast of Salvation must be Wednesday in $year", 3, EthiopianDateConverter.getDayOfWeek(dihnet))
        }
    }

    @Test
    fun testFastingPeriodDetectors() {
        // Fast of Nineveh 2017: Yakatit 3, 4, 5
        assertTrue(BahireHasab.isNinevehFast(EthiopianDate(2017, 6, 3)))
        assertTrue(BahireHasab.isNinevehFast(EthiopianDate(2017, 6, 4)))
        assertTrue(BahireHasab.isNinevehFast(EthiopianDate(2017, 6, 5)))
        assertFalse(BahireHasab.isNinevehFast(EthiopianDate(2017, 6, 6)))

        // Great Lent 2017: Yakatit 17 through Miazia 11
        assertTrue(BahireHasab.isGreatLent(EthiopianDate(2017, 6, 17)))
        assertTrue(BahireHasab.isGreatLent(EthiopianDate(2017, 7, 15)))
        assertTrue(BahireHasab.isGreatLent(EthiopianDate(2017, 8, 11))) // Holy Saturday
        assertFalse(BahireHasab.isGreatLent(EthiopianDate(2017, 8, 12))) // Easter Day

        // Fifty Days of Joy (Easter to Pentecost)
        assertTrue(BahireHasab.isFiftyDaysOfJoy(EthiopianDate(2017, 8, 12))) // Easter
        assertTrue(BahireHasab.isFiftyDaysOfJoy(EthiopianDate(2017, 9, 1)))
        assertTrue(BahireHasab.isFiftyDaysOfJoy(EthiopianDate(2017, 10, 1))) // Pentecost
        assertFalse(BahireHasab.isFiftyDaysOfJoy(EthiopianDate(2017, 10, 2))) // Day after Pentecost
    }
}
