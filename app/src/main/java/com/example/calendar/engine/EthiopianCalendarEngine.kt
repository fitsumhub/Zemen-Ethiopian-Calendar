package com.example.calendar.engine

import com.example.calendar.domain.EthiopianCalendarDomain
import java.util.Calendar

/**
 * High precision Ethiopian <-> Gregorian calendar conversion engine.
 * Delegates core calendar logic, month definitions, and astronomical algorithms
 * to the domain-layer [EthiopianCalendarDomain].
 */
object EthiopianCalendarEngine {

    const val ETHIOPIAN_EPOCH_JDN = EthiopianCalendarDomain.ETHIOPIAN_EPOCH_JDN

    private val domain = EthiopianCalendarDomain.INSTANCE

    /**
     * Converts an Ethiopian date to its Julian Day Number.
     */
    fun ethiopianToJdn(date: EthiopianDate): Long {
        return domain.ethiopianToJulianDay(date)
    }

    fun ethiopianToJdn(year: Int, month: Int, day: Int): Long {
        return domain.ethiopianToJulianDay(year, month, day)
    }

    /**
     * Converts a Julian Day Number to an Ethiopian date.
     */
    fun jdnToEthiopian(jdn: Long): EthiopianDate {
        return domain.julianDayToEthiopian(jdn)
    }

    /**
     * Converts a Gregorian date to its Julian Day Number.
     */
    fun gregorianToJdn(date: GregorianDate): Long {
        return domain.gregorianToJulianDay(date)
    }

    fun gregorianToJdn(year: Int, month: Int, day: Int): Long {
        return domain.gregorianToJulianDay(year, month, day)
    }

    /**
     * Converts a Julian Day Number to a Gregorian date.
     */
    fun jdnToGregorian(jdn: Long): GregorianDate {
        return domain.julianDayToGregorian(jdn)
    }

    /**
     * Converts an Ethiopian date to Gregorian date.
     */
    fun toGregorian(ethiopianDate: EthiopianDate): GregorianDate {
        return domain.toGregorian(ethiopianDate)
    }

    /**
     * Converts a Gregorian date to Ethiopian date.
     */
    fun toEthiopian(gregorianDate: GregorianDate): EthiopianDate {
        return domain.toEthiopian(gregorianDate)
    }

    /**
     * Returns today's Ethiopian date based on system clock.
     */
    fun todayEthiopian(): EthiopianDate {
        val cal = Calendar.getInstance()
        val gDate = GregorianDate(
            cal.get(Calendar.YEAR),
            cal.get(Calendar.MONTH) + 1,
            cal.get(Calendar.DAY_OF_MONTH)
        )
        return toEthiopian(gDate)
    }

    /**
     * Returns today's Gregorian date based on system clock.
     */
    fun todayGregorian(): GregorianDate {
        val cal = Calendar.getInstance()
        return GregorianDate(
            cal.get(Calendar.YEAR),
            cal.get(Calendar.MONTH) + 1,
            cal.get(Calendar.DAY_OF_MONTH)
        )
    }

    /**
     * Returns the day of the week for an Ethiopian date.
     * 1 = Monday (ሰኞ), 2 = Tuesday (ማክሰኞ), ..., 6 = Saturday (ቅዳሜ), 7 = Sunday (እሑድ).
     */
    fun getDayOfWeek(ethiopianDate: EthiopianDate): Int {
        val jdn = ethiopianToJdn(ethiopianDate)
        // JDN mod 7: 0 = Monday, 1 = Tuesday, 2 = Wednesday, 3 = Thursday, 4 = Friday, 5 = Saturday, 6 = Sunday
        val dow0 = (jdn % 7).toInt()
        return dow0 + 1
    }

    /**
     * Returns the day of the week for a Gregorian date (1 = Monday .. 7 = Sunday).
     */
    fun getDayOfWeek(gregorianDate: GregorianDate): Int {
        val jdn = gregorianToJdn(gregorianDate)
        val dow0 = (jdn % 7).toInt()
        return dow0 + 1
    }

    /**
     * Calculates the number of days between two Ethiopian dates.
     */
    fun daysBetween(from: EthiopianDate, to: EthiopianDate): Long {
        return ethiopianToJdn(to) - ethiopianToJdn(from)
    }

    /**
     * Calculates the number of days between two Gregorian dates.
     */
    fun daysBetween(from: GregorianDate, to: GregorianDate): Long {
        return gregorianToJdn(to) - gregorianToJdn(from)
    }

    /**
     * Returns the Ethiopian evangelist of the year:
     * 1 = Matthew (ማቴዎስ)
     * 2 = Mark (ማርቆስ)
     * 3 = Luke (ሉቃስ - Leap Year!)
     * 0 = John (ዮሐንስ)
     */
    fun getEvangelist(year: Int): Int {
        val ameteAlem = year + 5500
        return ameteAlem % 4
    }

    data class DateDifference(
        val totalDays: Long,
        val totalWeeks: Long,
        val remainingDays: Long,
        val ethiopianYears: Int,
        val ethiopianMonths: Int,
        val ethiopianDays: Int,
        val gregorianYears: Int,
        val gregorianMonths: Int,
        val gregorianDays: Int
    )

    fun calculateDifference(from: EthiopianDate, to: EthiopianDate): DateDifference {
        val diffDays = daysBetween(from, to)
        val absDays = kotlin.math.abs(diffDays)
        val weeks = absDays / 7
        val remDays = absDays % 7

        // Approximate years/months/days in Ethiopian calendar
        val (earlier, later) = if (from <= to) Pair(from, to) else Pair(to, from)
        var eYears = later.year - earlier.year
        var eMonths = later.month - earlier.month
        var eDays = later.day - earlier.day

        if (eDays < 0) {
            eMonths -= 1
            eDays += 30
        }
        if (eMonths < 0) {
            eYears -= 1
            eMonths += 12
        }

        // Gregorian difference
        val gFrom = toGregorian(earlier)
        val gTo = toGregorian(later)
        var gYears = gTo.year - gFrom.year
        var gMonths = gTo.month - gFrom.month
        var gDays = gTo.day - gFrom.day
        if (gDays < 0) {
            gMonths -= 1
            val prevMonth = if (gTo.month == 1) 12 else gTo.month - 1
            val prevYear = if (gTo.month == 1) gTo.year - 1 else gTo.year
            gDays += GregorianDate.daysInMonth(prevYear, prevMonth)
        }
        if (gMonths < 0) {
            gYears -= 1
            gMonths += 12
        }

        return DateDifference(
            totalDays = diffDays,
            totalWeeks = weeks,
            remainingDays = remDays,
            ethiopianYears = kotlin.math.max(0, eYears),
            ethiopianMonths = kotlin.math.max(0, eMonths),
            ethiopianDays = kotlin.math.max(0, eDays),
            gregorianYears = kotlin.math.max(0, gYears),
            gregorianMonths = kotlin.math.max(0, gMonths),
            gregorianDays = kotlin.math.max(0, gDays)
        )
    }
}
