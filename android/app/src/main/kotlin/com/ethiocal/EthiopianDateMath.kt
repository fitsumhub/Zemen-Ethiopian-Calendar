package com.ethiocal

import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

/**
 * Minimal Ethiopian ↔ Gregorian conversion (JDN) for home-widget freshness
 * when Flutter has not yet synced, or the calendar day rolls overnight.
 */
object EthiopianDateMath {
    private const val ETHIOPIAN_EPOCH_JDN = 1724221

    data class EthDate(val year: Int, val month: Int, val day: Int)

    private val monthNamesAm = arrayOf(
        "", "መስከረም", "ጥቅምት", "ኅዳር", "ታኅሣሥ", "ጥር", "የካቲት",
        "መጋቢት", "ሚያዝያ", "ግንቦት", "ሰኔ", "ሐምሌ", "ነሐሴ", "ጳጉሜን",
    )

    private val weekdayNamesAm = arrayOf(
        "", "ሰኞ", "ማክሰኞ", "ረቡዕ", "ሐሙስ", "ዓርብ", "ቅዳሜ", "እሑድ",
    )

    fun todayEthiopia(): EthDate {
        val cal = Calendar.getInstance(TimeZone.getDefault())
        return toEthiopian(
            cal.get(Calendar.YEAR),
            cal.get(Calendar.MONTH) + 1,
            cal.get(Calendar.DAY_OF_MONTH),
        )
    }

    fun toEthiopian(gYear: Int, gMonth: Int, gDay: Int): EthDate {
        return julianDayToEthiopian(gregorianToJulianDay(gYear, gMonth, gDay))
    }

    fun monthNameAm(month: Int): String =
        monthNamesAm.getOrElse(month.coerceIn(1, 13)) { "—" }

    fun weekdayNameAm(eth: EthDate): String {
        val dow = dayOfWeek(eth) // 1=Mon … 7=Sun
        return weekdayNamesAm.getOrElse(dow) { "" }
    }

    /** 1 = Monday … 7 = Sunday */
    fun dayOfWeek(eth: EthDate): Int {
        val jdn = ethiopianToJulianDay(eth.year, eth.month, eth.day)
        return (jdn % 7) + 1
    }

    fun daysInMonth(year: Int, month: Int): Int {
        if (month == 13) return if (year % 4 == 3) 6 else 5
        return 30
    }

    /** Traditional Ethiopian Evangelist cycle for the year (ዘመነ ማቴዎስ / ማርቆስ / ሉቃስ / ዮሐንስ). */
    fun evangelistAm(year: Int): String {
        val ameteAlem = year + 5500
        return when ((ameteAlem % 4 + 4) % 4) {
            1 -> "ዘመነ ማቴዎስ"
            2 -> "ዘመነ ማርቆስ"
            3 -> "ዘመነ ሉቃስ"
            else -> "ዘመነ ዮሐንስ"
        }
    }

    /** Canonical monthly commemorating saint for days 1..30 in Ethiopian Orthodox tradition. */
    fun canonicalSaintAm(day: Int): String {
        val saints = arrayOf(
            "",
            "ልደታ ለማርያም", "ታዴዎስ ሐዋርያ", "በዓታ ለማርያም", "ዮሐንስ ወልደ ነጎድጓድ",
            "አቡነ ገብረ መንፈስ ቅዱስ", "ቁስቋም ማርያም", "ቅድስት ሥላሴ", "አባ ኪሮስ",
            "ሠለስቱ ምዕት", "መስቀለ ክርስቶስ", "ሐና እና ኢያቄም", "ቅዱስ ሚካኤል",
            "እግዚአብሔር አብ", "አባ አረጋዊ", "ቅዱስ ቂርቆስ", "ኪዳነ ምሕረት",
            "ቅዱስ እስጢፋኖስ", "አቡነ ኤዎስጣቴዎስ", "ቅዱስ ገብርኤል", "ሕንፀተ ቤተክርስቲያን",
            "ቅድስት ድንግል ማርያም", "ቅዱስ ዑራኤል", "ቅዱስ ጊዮርጊስ", "አቡነ ተክለ ሃይማኖት",
            "ቅዱስ መርቆሬዎስ", "ቅዱስ ቶማስ", "መድኃኔ ዓለም", "አማኑኤል",
            "በዓለ ወልድ", "ቅዱስ ማርቆስ"
        )
        return saints.getOrElse(day.coerceIn(1, 30)) { "" }
    }

    /** Fast 1..30 Ge'ez numeral conversion for widget freshness. */
    fun toGeez(num: Int): String {
        if (num <= 0 || num > 30) return num.toString()
        val ones = arrayOf("", "፩", "፪", "፫", "፬", "፭", "፮", "፯", "፰", "፱")
        val tens = arrayOf("", "፲", "፳", "፴")
        val t = num / 10
        val o = num % 10
        return tens[t] + ones[o]
    }

    fun gregorianLabel(): String {
        val cal = Calendar.getInstance(TimeZone.getDefault())
        val months = arrayOf(
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December",
        )
        val m = months[cal.get(Calendar.MONTH)]
        val d = cal.get(Calendar.DAY_OF_MONTH)
        val y = cal.get(Calendar.YEAR)
        return String.format(Locale.US, "%s %d, %d", m, d, y)
    }

    private fun ethiopianToJulianDay(year: Int, month: Int, day: Int): Int {
        return ETHIOPIAN_EPOCH_JDN +
            365 * (year - 1) +
            (year / 4) +
            30 * (month - 1) +
            (day - 1)
    }

    private fun gregorianToJulianDay(year: Int, month: Int, day: Int): Int {
        val a = (14 - month) / 12
        val y = year + 4800 - a
        val m = month + 12 * a - 3
        return day + ((153 * m + 2) / 5) + 365 * y + (y / 4) - (y / 100) + (y / 400) - 32045
    }

    private fun julianDayToEthiopian(jdn: Int): EthDate {
        val totalDays = jdn - ETHIOPIAN_EPOCH_JDN
        var cycle = totalDays / 1461
        var rem = totalDays % 1461
        if (rem < 0) rem += 1461
        if (totalDays < 0 && rem != 0) cycle -= 1

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

        val year = cycle * 4 + yearOffset + 1
        val month = (dayInYear / 30) + 1
        val day = (dayInYear % 30) + 1
        return EthDate(year, month, day)
    }
}
