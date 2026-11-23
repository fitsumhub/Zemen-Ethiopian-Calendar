package com.example.calendar.domain

import com.example.calendar.core.EthiopianDateConverter
import com.example.calendar.core.LeapYearCalculator
import com.example.calendar.engine.EthiopianDate
import com.example.calendar.engine.GregorianDate

/**
 * Domain-layer facade for the Ethiopian calendar system, delegating to the :calendar-core module.
 *
 * Encapsulates:
 * 1. Month definitions for all 13 Ethiopian months (Meskerem to Pagume)
 * 2. Leap year calculations based on the traditional 4-year Evangelist cycle
 * 3. High-precision bidirectional conversion algorithm between Ethiopian and Gregorian calendars
 * 4. Calendar date validation and date arithmetic
 */
class EthiopianCalendarDomain {

    companion object {
        const val ETHIOPIAN_EPOCH_JDN = EthiopianDateConverter.ETHIOPIAN_EPOCH_JDN

        val INSTANCE: EthiopianCalendarDomain by lazy { EthiopianCalendarDomain() }
    }

    /**
     * Enumeration of the four Evangelists representing the 4-year cycle.
     */
    enum class Evangelist(val index: Int, val amharicName: String, val englishName: String, val isLeapYear: Boolean) {
        JOHN(0, "ዘመነ ዮሐንስ", "Year of John", false),
        MATTHEW(1, "ዘመነ ማቴዎስ", "Year of Matthew", false),
        MARK(2, "ዘመነ ማርቆስ", "Year of Mark", false),
        LUKE(3, "ዘመነ ሉቃስ", "Year of Luke", true);

        companion object {
            fun fromYear(ethiopianYear: Int): Evangelist {
                val coreEvangelist = LeapYearCalculator.getEvangelist(ethiopianYear)
                return when (coreEvangelist) {
                    LeapYearCalculator.Evangelist.JOHN -> JOHN
                    LeapYearCalculator.Evangelist.MATTHEW -> MATTHEW
                    LeapYearCalculator.Evangelist.MARK -> MARK
                    LeapYearCalculator.Evangelist.LUKE -> LUKE
                }
            }
        }
    }

    // ==========================================
    // 1. MONTH DEFINITIONS & CALENDAR PROPERTIES
    // ==========================================

    fun getMonth(monthNumber: Int): EthiopianMonth {
        return EthiopianMonth.fromNumber(monthNumber)
    }

    fun getAllMonths(): List<EthiopianMonth> {
        return EthiopianMonth.entries.toList()
    }

    fun getDaysInMonth(year: Int, month: EthiopianMonth): Int {
        return month.daysInMonth(isLeapYear(year))
    }

    fun getDaysInMonth(year: Int, monthNumber: Int): Int {
        require(monthNumber in 1..13) { "Month must be between 1 and 13, received: $monthNumber" }
        return getMonth(monthNumber).daysInMonth(isLeapYear(year))
    }

    fun getDaysInYear(year: Int): Int {
        return LeapYearCalculator.getEthiopianYearDays(year)
    }

    fun isValidDate(year: Int, monthNumber: Int, day: Int): Boolean {
        return EthiopianDateConverter.isValidEthiopianDate(year, monthNumber, day)
    }

    // ==========================================
    // 2. LEAP YEAR & EVANGELIST CALCULATIONS
    // ==========================================

    fun isLeapYear(year: Int): Boolean {
        return LeapYearCalculator.isEthiopianLeapYear(year)
    }

    fun getEvangelist(year: Int): Evangelist {
        return Evangelist.fromYear(year)
    }

    // ==========================================
    // 3. CONVERSION ALGORITHMS (JDN ENGINE)
    // ==========================================

    fun ethiopianToJulianDay(year: Int, month: Int, day: Int): Long {
        return EthiopianDateConverter.ethiopianToJulianDay(year, month, day)
    }

    fun ethiopianToJulianDay(date: EthiopianDate): Long {
        return EthiopianDateConverter.ethiopianToJulianDay(date)
    }

    fun julianDayToEthiopian(jdn: Long): EthiopianDate {
        return EthiopianDateConverter.julianDayToEthiopian(jdn)
    }

    fun gregorianToJulianDay(year: Int, month: Int, day: Int): Long {
        return EthiopianDateConverter.gregorianToJulianDay(year, month, day)
    }

    fun gregorianToJulianDay(date: GregorianDate): Long {
        return EthiopianDateConverter.gregorianToJulianDay(date)
    }

    fun julianDayToGregorian(jdn: Long): GregorianDate {
        return EthiopianDateConverter.julianDayToGregorian(jdn)
    }

    fun toGregorian(ethiopianDate: EthiopianDate): GregorianDate {
        return EthiopianDateConverter.toGregorian(ethiopianDate)
    }

    fun toGregorian(year: Int, month: Int, day: Int): GregorianDate {
        return EthiopianDateConverter.toGregorian(year, month, day)
    }

    fun toEthiopian(gregorianDate: GregorianDate): EthiopianDate {
        return EthiopianDateConverter.toEthiopian(gregorianDate)
    }

    fun toEthiopian(year: Int, month: Int, day: Int): EthiopianDate {
        return EthiopianDateConverter.toEthiopian(year, month, day)
    }

    // ==========================================
    // 4. DAY OF THE WEEK & DATE ARITHMETIC
    // ==========================================

    fun getDayOfWeek(date: EthiopianDate): Int {
        return EthiopianDateConverter.getDayOfWeek(date)
    }

    fun addDays(date: EthiopianDate, days: Long): EthiopianDate {
        return EthiopianDateConverter.addDays(date, days)
    }

    fun subtractDays(date: EthiopianDate, days: Long): EthiopianDate {
        return EthiopianDateConverter.subtractDays(date, days)
    }

    fun daysBetween(from: EthiopianDate, to: EthiopianDate): Long {
        return EthiopianDateConverter.daysBetween(from, to)
    }
}
