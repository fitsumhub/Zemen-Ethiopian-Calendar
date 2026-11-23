package com.example.calendar.core

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Result model representing a detailed Gregorian to Ethiopian date conversion.
 * Contains both raw calendar dates, human-friendly localized representations,
 * Ge'ez numerals, evangelist cycle, Ethiopian season, and astronomical metadata.
 */
data class GregorianToEthiopianResult(
    val gregorianDate: GregorianDate,
    val ethiopianDate: EthiopianDate,
    val formattedAmharic: String,
    val formattedEnglish: String,
    val formattedGregorian: String,
    val dayOfWeekAmharic: String,
    val dayOfWeekEnglish: String,
    val dayOfWeekNumber: Int, // 1 = Monday (ሰኞ) ... 7 = Sunday (እሑድ)
    val geezDay: String,
    val geezYear: String,
    val geezFullDate: String,
    val evangelistAmharic: String,
    val evangelistEnglish: String,
    val seasonAmharic: String,
    val seasonEnglish: String,
    val seasonDescription: String,
    val majorHolidayAmharic: String? = null,
    val majorHolidayEnglish: String? = null,
    val isLeapYearGregorian: Boolean,
    val isLeapYearEthiopian: Boolean,
    val julianDayNumber: Long
)

/**
 * Dedicated utility class for converting Gregorian calendar dates into
 * their exact astronomical and traditional Ethiopian calendar equivalents.
 *
 * Provides bidirectional verification, strict bounds validation, ISO string parsing,
 * java.util.Date/Calendar bridges, and rich cultural/liturgical contextualization.
 */
class GregorianToEthiopianConverter {

    companion object {
        val INSTANCE = GregorianToEthiopianConverter()

        /**
         * Fast static conversion method taking integer year, month, and day.
         */
        @JvmStatic
        fun convertDate(year: Int, month: Int, day: Int): GregorianToEthiopianResult {
            return INSTANCE.convert(year, month, day)
        }

        /**
         * Fast static conversion method taking a [GregorianDate].
         */
        @JvmStatic
        fun convertDate(gregorianDate: GregorianDate): GregorianToEthiopianResult {
            return INSTANCE.convert(gregorianDate)
        }
    }

    /**
     * Converts a [GregorianDate] instance into a comprehensive [GregorianToEthiopianResult].
     */
    fun convert(gregorianDate: GregorianDate): GregorianToEthiopianResult {
        return convert(gregorianDate.year, gregorianDate.month, gregorianDate.day)
    }

    /**
     * Converts integer Gregorian year, month (1..12), and day (1..31) into a [GregorianToEthiopianResult].
     *
     * @throws IllegalArgumentException if the Gregorian date is invalid.
     */
    fun convert(year: Int, month: Int, day: Int): GregorianToEthiopianResult {
        require(isValidGregorianDate(year, month, day)) {
            "Invalid Gregorian date: $year-$month-$day (Days in month: ${getDaysInMonth(year, month)})"
        }

        val gregDate = GregorianDate(year, month, day)
        val ethDate = EthiopianDateConverter.toEthiopian(gregDate)
        val jdn = EthiopianDateConverter.gregorianToJulianDay(gregDate)

        // Day of week calculation (1 = Monday, ..., 7 = Sunday)
        val dow = EthiopianDateConverter.getDayOfWeek(ethDate)
        val (dowAmharic, dowEnglish) = getDayOfWeekNames(dow)

        // Localized Month Names
        val ethMonth = ethDate.monthEnum
        val formattedAmharic = "${ethMonth.amharicName} ${ethDate.day} ቀን ${ethDate.year} ዓ.ም"
        val formattedEnglish = "${ethMonth.englishName} ${ethDate.day}, ${ethDate.year} E.C."

        val gregMonthNames = listOf(
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        )
        val formattedGregorian = "${dowEnglish}, ${gregMonthNames.getOrElse(month - 1) { "Month $month" }} $day, $year"

        // Ge'ez numerals
        val geezDay = GeezNumeral.toGeez(ethDate.day)
        val geezYear = GeezNumeral.toGeez(ethDate.year)
        val geezFullDate = "${ethMonth.amharicName} $geezDay ቀን $geezYear ዓ.ም"

        // Evangelist cycle
        val evangelist = LeapYearCalculator.getEvangelist(ethDate.year)

        // Season
        val season = EthiopianSeason.fromEthiopianDate(ethDate)

        // Major religious / national holidays on this converted Ethiopian date
        val (holidayAm, holidayEn) = findMajorHoliday(ethDate.year, ethDate.month, ethDate.day)

        return GregorianToEthiopianResult(
            gregorianDate = gregDate,
            ethiopianDate = ethDate,
            formattedAmharic = formattedAmharic,
            formattedEnglish = formattedEnglish,
            formattedGregorian = formattedGregorian,
            dayOfWeekAmharic = dowAmharic,
            dayOfWeekEnglish = dowEnglish,
            dayOfWeekNumber = dow,
            geezDay = geezDay,
            geezYear = geezYear,
            geezFullDate = geezFullDate,
            evangelistAmharic = evangelist.amharicName,
            evangelistEnglish = evangelist.englishName,
            seasonAmharic = season.amharicName,
            seasonEnglish = season.englishName,
            seasonDescription = season.descriptionAmharic,
            majorHolidayAmharic = holidayAm,
            majorHolidayEnglish = holidayEn,
            isLeapYearGregorian = LeapYearCalculator.isGregorianLeapYear(year),
            isLeapYearEthiopian = LeapYearCalculator.isEthiopianLeapYear(ethDate.year),
            julianDayNumber = jdn
        )
    }

    /**
     * Converts a [Date] instance.
     */
    fun convert(date: Date): GregorianToEthiopianResult {
        val cal = Calendar.getInstance()
        cal.time = date
        return convert(
            year = cal.get(Calendar.YEAR),
            month = cal.get(Calendar.MONTH) + 1,
            day = cal.get(Calendar.DAY_OF_MONTH)
        )
    }

    /**
     * Converts a [Calendar] instance.
     */
    fun convert(calendar: Calendar): GregorianToEthiopianResult {
        return convert(
            year = calendar.get(Calendar.YEAR),
            month = calendar.get(Calendar.MONTH) + 1,
            day = calendar.get(Calendar.DAY_OF_MONTH)
        )
    }

    /**
     * Safely attempts conversion, returning null if the date parameters are invalid.
     */
    fun convertOrNull(year: Int, month: Int, day: Int): GregorianToEthiopianResult? {
        return if (isValidGregorianDate(year, month, day)) {
            try {
                convert(year, month, day)
            } catch (_: Exception) {
                null
            }
        } else {
            null
        }
    }

    /**
     * Parses an ISO date string ("YYYY-MM-DD" or "YYYY/MM/DD") and performs conversion.
     */
    fun parseAndConvert(dateString: String): Result<GregorianToEthiopianResult> {
        return runCatching {
            val clean = dateString.trim().replace('/', '-')
            val parts = clean.split('-')
            require(parts.size == 3) { "Expected date format YYYY-MM-DD or YYYY/MM/DD, got: $dateString" }
            val y = parts[0].toInt()
            val m = parts[1].toInt()
            val d = parts[2].toInt()
            convert(y, m, d)
        }
    }

    /**
     * Validates whether a Gregorian date is astronomically valid.
     */
    fun isValidGregorianDate(year: Int, month: Int, day: Int): Boolean {
        if (year !in 1..9999) return false
        if (month !in 1..12) return false
        val maxDays = getDaysInMonth(year, month)
        return day in 1..maxDays
    }

    /**
     * Returns the number of days in a Gregorian month, accounting for leap years.
     */
    fun getDaysInMonth(year: Int, month: Int): Int {
        return GregorianDate.daysInMonth(year, month)
    }

    /**
     * Checks if a Gregorian year is a leap year.
     */
    fun isLeapYear(year: Int): Boolean {
        return LeapYearCalculator.isGregorianLeapYear(year)
    }

    private fun getDayOfWeekNames(dow: Int): Pair<String, String> {
        return when (dow) {
            1 -> "ሰኞ" to "Monday"
            2 -> "ማክሰኞ" to "Tuesday"
            3 -> "ረቡዕ" to "Wednesday"
            4 -> "ሐሙስ" to "Thursday"
            5 -> "ዓርብ" to "Friday"
            6 -> "ቅዳሜ" to "Saturday"
            7 -> "እሑድ" to "Sunday"
            else -> "ሰኞ" to "Monday"
        }
    }

    /**
     * Identifies major fixed or movable Ethiopian holidays for a given Ethiopian date.
     */
    private fun findMajorHoliday(ethYear: Int, ethMonth: Int, ethDay: Int): Pair<String?, String?> {
        // Fixed major holidays
        when (ethMonth) {
            1 -> {
                if (ethDay == 1) return "እንቁጣጣሽ (የዘመን መለወጫ)" to "Enkutatash (Ethiopian New Year)"
                if (ethDay == 17) return "መስቀል (ደመራ)" to "Meskel (Finding of the True Cross)"
            }
            4 -> {
                if (ethDay == 29 || (LeapYearCalculator.isEthiopianLeapYear(ethYear) && ethDay == 28)) {
                    return "ገና (የጌታችን የኢየሱስ ክርስቶስ ልደት)" to "Genna (Ethiopian Christmas)"
                }
            }
            5 -> {
                if (ethDay == 11) return "ጥምቀት (ኤጲፋንያ)" to "Timket (Epiphany)"
                if (ethDay == 12) return "ቃና ዘገሊላ" to "Kana ZeGelila (Miracle of Cana)"
            }
            6 -> {
                if (ethDay == 23) return "የዓድዋ ድል በዓል" to "Adwa Victory Day"
            }
            8 -> {
                if (ethDay == 27) return "የአርበኞች ቀን" to "Patriots' Victory Day"
            }
            9 -> {
                if (ethDay == 20) return "ደርግ የወደቀበት ቀን" to "Downfall of the Derg"
            }
            13 -> {
                if (ethDay == 3) return "ሩፋኤል" to "Feast of Archangel Rufael"
            }
        }

        // Movable feasts via BahireHasab object
        val movableFeasts = listOf(
            BahireHasab.nenewe(ethYear) to ("ጾመ ነነዌ" to "Fast of Nineveh"),
            BahireHasab.abiyTsom(ethYear) to ("ዓቢይ ጾም (ሁዳዴ)" to "Great Lent"),
            BahireHasab.debreZeit(ethYear) to ("ደብረ ዘይት" to "Mount of Olives"),
            BahireHasab.hosanna(ethYear) to ("ሆሣዕና" to "Palm Sunday (Hosanna)"),
            BahireHasab.siklet(ethYear) to ("ስቅለት" to "Good Friday (Siklet)"),
            BahireHasab.fasika(ethYear) to ("ትንሣኤ (ፋሲካ)" to "Fasika (Ethiopian Easter)"),
            BahireHasab.erget(ethYear) to ("ዕርገት" to "Ascension"),
            BahireHasab.paraclete(ethYear) to ("ጰራቅሊጦስ (በዓለ ሃምሳ)" to "Pentecost (Paraclete)")
        )

        for ((feastDate, names) in movableFeasts) {
            if (feastDate.month == ethMonth && feastDate.day == ethDay) {
                return names.first to names.second
            }
        }

        return null to null
    }
}
