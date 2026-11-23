package com.example.calendar.core

/**
 * Represents a standard date in the Gregorian calendar.
 *
 * @param year Gregorian year (e.g., 2024, 2025)
 * @param month Gregorian month (1 = January ... 12 = December)
 * @param day Day of month (1..31 depending on month and leap year)
 */
data class GregorianDate(
    val year: Int,
    val month: Int,
    val day: Int
) : Comparable<GregorianDate> {

    init {
        require(month in 1..12) { "Gregorian month must be between 1 and 12, was $month" }
        val maxDays = daysInMonth(year, month)
        require(day in 1..maxDays) {
            "Day must be between 1 and $maxDays for month $month in year $year, was $day"
        }
    }

    fun isLeapYear(): Boolean = LeapYearCalculator.isGregorianLeapYear(year)

    fun daysInMonth(): Int = daysInMonth(year, month)

    override fun compareTo(other: GregorianDate): Int {
        if (year != other.year) return year.compareTo(other.year)
        if (month != other.month) return month.compareTo(other.month)
        return day.compareTo(other.day)
    }

    override fun toString(): String {
        val mStr = month.toString().padStart(2, '0')
        val dStr = day.toString().padStart(2, '0')
        return "$year-$mStr-$dStr"
    }

    companion object {
        fun isLeapYear(year: Int): Boolean = LeapYearCalculator.isGregorianLeapYear(year)

        fun daysInMonth(year: Int, month: Int): Int {
            return when (month) {
                1, 3, 5, 7, 8, 10, 12 -> 31
                4, 6, 9, 11 -> 30
                2 -> if (isLeapYear(year)) 29 else 28
                else -> 30
            }
        }
    }
}
