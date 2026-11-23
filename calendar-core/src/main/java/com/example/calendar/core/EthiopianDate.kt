package com.example.calendar.core

/**
 * Represents a date in the Ethiopian Calendar (ዓውደ አኅዛብ).
 *
 * @param year Ethiopian year (e.g., 2017 E.C.)
 * @param month Ethiopian month (1 = Meskerem ... 13 = Pagume)
 * @param day Ethiopian day of month (1..30 for regular months, 1..5/6 for Pagume)
 */
data class EthiopianDate(
    val year: Int,
    val month: Int,
    val day: Int
) : Comparable<EthiopianDate> {

    init {
        require(month in 1..13) { "Ethiopian month must be between 1 and 13, was $month" }
        val maxDays = daysInMonth(year, month)
        require(day in 1..maxDays) {
            "Day must be between 1 and $maxDays for month $month in year $year, was $day"
        }
    }

    val monthEnum: EthiopianMonth
        get() = EthiopianMonth.fromNumber(month)

    fun isLeapYear(): Boolean = LeapYearCalculator.isEthiopianLeapYear(year)

    fun daysInMonth(): Int = daysInMonth(year, month)

    override fun compareTo(other: EthiopianDate): Int {
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
        fun isLeapYear(year: Int): Boolean = LeapYearCalculator.isEthiopianLeapYear(year)

        fun daysInMonth(year: Int, month: Int): Int {
            require(month in 1..13) { "Month must be between 1 and 13, received: $month" }
            return if (month == 13) {
                if (isLeapYear(year)) 6 else 5
            } else {
                30
            }
        }
    }
}
