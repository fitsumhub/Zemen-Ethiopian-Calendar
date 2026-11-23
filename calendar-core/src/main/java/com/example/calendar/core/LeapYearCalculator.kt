package com.example.calendar.core

/**
 * Encapsulates leap year calculations and the 4-year Evangelist cycle for
 * the Ethiopian Calendar and Gregorian Calendar.
 */
object LeapYearCalculator {

    /**
     * In the Ethiopian calendar, a year is a leap year (ዘመነ ሉቃስ) if (year % 4 == 3).
     * During an Ethiopian leap year, Pagume (the 13th month) has 6 days instead of 5,
     * making the year 366 days long.
     */
    fun isEthiopianLeapYear(year: Int): Boolean {
        return (year % 4 + 4) % 4 == 3
    }

    /**
     * Determines whether a given Gregorian year is a leap year under the Gregorian calendar rules.
     */
    fun isGregorianLeapYear(year: Int): Boolean {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }

    /**
     * Returns total days in an Ethiopian year (366 for leap year, 365 otherwise).
     */
    fun getEthiopianYearDays(year: Int): Int {
        return if (isEthiopianLeapYear(year)) 366 else 365
    }

    /**
     * Returns total days in a Gregorian year (366 for leap year, 365 otherwise).
     */
    fun getGregorianYearDays(year: Int): Int {
        return if (isGregorianLeapYear(year)) 366 else 365
    }

    /**
     * Traditional 4-year cycle named after the Four Evangelists (አራቱ ወንጌላውያን).
     * The year of Luke (ሉቃስ) is always the Ethiopian leap year.
     */
    enum class Evangelist(
        val index: Int,
        val amharicName: String,
        val englishName: String,
        val isLeapYear: Boolean
    ) {
        JOHN(0, "ዘመነ ዮሐንስ", "Year of John", false),
        MATTHEW(1, "ዘመነ ማቴዎስ", "Year of Matthew", false),
        MARK(2, "ዘመነ ማርቆስ", "Year of Mark", false),
        LUKE(3, "ዘመነ ሉቃስ", "Year of Luke", true);

        val amharic: String get() = amharicName
        val english: String get() = englishName

        companion object {
            /**
             * Returns the Evangelist for the given Ethiopian year based on Amete Alem (ዓመተ ዓለም = year + 5500).
             */
            fun fromEthiopianYear(year: Int): Evangelist {
                val ameteAlem = year + 5500
                return when ((ameteAlem % 4 + 4) % 4) {
                    1 -> MATTHEW
                    2 -> MARK
                    3 -> LUKE
                    else -> JOHN
                }
            }
        }
    }

    /**
     * Returns the Evangelist presiding over the given Ethiopian year.
     */
    fun getEvangelist(year: Int): Evangelist {
        return Evangelist.fromEthiopianYear(year)
    }
}
