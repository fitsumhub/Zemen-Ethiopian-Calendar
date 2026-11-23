package com.example.calendar.core

/**
 * Astronomical and algorithmic bidirectional converter between the Ethiopian Calendar
 * and the International Gregorian Calendar using Julian Day Number (JDN) equations.
 *
 * Provides mathematically proven, lossless conversions across past, present, and future centuries.
 */
object EthiopianDateConverter {

    /**
     * Astronomical epoch of the Ethiopian Calendar in Julian Day Numbers.
     * Corresponds to Meskerem 1, 1 E.C. (August 29, 8 C.E. Julian / August 27, 8 C.E. proleptic Gregorian).
     */
    const val ETHIOPIAN_EPOCH_JDN = 1724221L

    /**
     * Validates whether the given year, month, and day constitute a valid Ethiopian date.
     */
    fun isValidEthiopianDate(year: Int, month: Int, day: Int): Boolean {
        if (month !in 1..13) return false
        val maxDays = EthiopianDate.daysInMonth(year, month)
        return day in 1..maxDays
    }

    /**
     * Validates whether the given year, month, and day constitute a valid Gregorian date.
     */
    fun isValidGregorianDate(year: Int, month: Int, day: Int): Boolean {
        if (month !in 1..12) return false
        val maxDays = GregorianDate.daysInMonth(year, month)
        return day in 1..maxDays
    }

    /**
     * Converts an Ethiopian date to its Julian Day Number (JDN).
     */
    fun ethiopianToJulianDay(year: Int, month: Int, day: Int): Long {
        require(isValidEthiopianDate(year, month, day)) {
            "Invalid Ethiopian date: $year-$month-$day"
        }
        return ETHIOPIAN_EPOCH_JDN +
                365L * (year - 1) +
                (year / 4) +
                30L * (month - 1) +
                (day - 1)
    }

    fun ethiopianToJulianDay(date: EthiopianDate): Long {
        return ethiopianToJulianDay(date.year, date.month, date.day)
    }

    /**
     * Converts a Julian Day Number (JDN) to its corresponding Ethiopian date.
     */
    fun julianDayToEthiopian(jdn: Long): EthiopianDate {
        val totalDays = jdn - ETHIOPIAN_EPOCH_JDN
        val cycle = totalDays / 1461
        val rem = (totalDays % 1461).toInt().let { if (it < 0) it + 1461 else it }
        val adjustedCycle = if (totalDays < 0 && rem != 0) cycle - 1 else cycle

        val yearOffset: Int
        val dayInYear: Int
        when {
            rem < 365 -> {
                yearOffset = 0
                dayInYear = rem
            }
            rem < 730 -> {
                yearOffset = 1
                dayInYear = rem - 365
            }
            rem < 1096 -> {
                yearOffset = 2
                dayInYear = rem - 730
            }
            else -> {
                yearOffset = 3
                dayInYear = rem - 1096
            }
        }

        val year = (adjustedCycle * 4 + yearOffset + 1).toInt()
        val month = (dayInYear / 30) + 1
        val day = (dayInYear % 30) + 1
        return EthiopianDate(year, month, day)
    }

    /**
     * Converts a Gregorian calendar date to its Julian Day Number (JDN).
     */
    fun gregorianToJulianDay(year: Int, month: Int, day: Int): Long {
        require(isValidGregorianDate(year, month, day)) {
            "Invalid Gregorian date: $year-$month-$day"
        }
        val a = (14 - month) / 12
        val y = year + 4800 - a
        val m = month + 12 * a - 3
        return (day + (153 * m + 2) / 5 + 365L * y + y / 4 - y / 100 + y / 400 - 32045)
    }

    fun gregorianToJulianDay(date: GregorianDate): Long {
        return gregorianToJulianDay(date.year, date.month, date.day)
    }

    /**
     * Converts a Julian Day Number (JDN) to its corresponding Gregorian date.
     */
    fun julianDayToGregorian(jdn: Long): GregorianDate {
        val a = jdn + 32044
        val b = (4 * a + 3) / 146097
        val c = a - (146097 * b) / 4
        val d = (4 * c + 3) / 1461
        val e = c - (1461 * d) / 4
        val m = (5 * e + 2) / 153
        val day = (e - (153 * m + 2) / 5 + 1).toInt()
        val month = (m + 3 - 12 * (m / 10)).toInt()
        val year = (100 * b + d - 4800 + (m / 10)).toInt()
        return GregorianDate(year, month, day)
    }

    /**
     * Converts an Ethiopian date to a Gregorian date.
     */
    fun toGregorian(ethiopianDate: EthiopianDate): GregorianDate {
        val jdn = ethiopianToJulianDay(ethiopianDate)
        return julianDayToGregorian(jdn)
    }

    fun toGregorian(year: Int, month: Int, day: Int): GregorianDate {
        val jdn = ethiopianToJulianDay(year, month, day)
        return julianDayToGregorian(jdn)
    }

    /**
     * Converts a Gregorian date to an Ethiopian date.
     */
    fun toEthiopian(gregorianDate: GregorianDate): EthiopianDate {
        val jdn = gregorianToJulianDay(gregorianDate)
        return julianDayToEthiopian(jdn)
    }

    fun toEthiopian(year: Int, month: Int, day: Int): EthiopianDate {
        val jdn = gregorianToJulianDay(year, month, day)
        return julianDayToEthiopian(jdn)
    }

    /**
     * Returns the ISO-8601 day of the week for an Ethiopian date:
     * 1 = Monday (ሰኞ), 2 = Tuesday (ማክሰኞ), ..., 6 = Saturday (ቅዳሜ), 7 = Sunday (እሑድ).
     */
    fun getDayOfWeek(date: EthiopianDate): Int {
        val jdn = ethiopianToJulianDay(date)
        val dow0 = (jdn % 7).toInt()
        return dow0 + 1
    }

    /**
     * Adds days to an Ethiopian date.
     */
    fun addDays(date: EthiopianDate, days: Long): EthiopianDate {
        val currentJdn = ethiopianToJulianDay(date)
        return julianDayToEthiopian(currentJdn + days)
    }

    /**
     * Subtracts days from an Ethiopian date.
     */
    fun subtractDays(date: EthiopianDate, days: Long): EthiopianDate {
        return addDays(date, -days)
    }

    /**
     * Calculates the number of days between two Ethiopian dates (to - from).
     */
    fun daysBetween(from: EthiopianDate, to: EthiopianDate): Long {
        return ethiopianToJulianDay(to) - ethiopianToJulianDay(from)
    }
}
