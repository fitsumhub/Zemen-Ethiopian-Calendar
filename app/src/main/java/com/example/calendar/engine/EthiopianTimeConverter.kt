package com.example.calendar.engine

import java.util.Locale

/**
 * Traditional Ethiopian timekeeping converter.
 * In Ethiopia, a 12-hour cycle begins at sunrise (6:00 AM Gregorian = 12:00 morning Ethiopian)
 * and the night cycle begins at sunset (6:00 PM Gregorian = 12:00 night Ethiopian).
 */
object EthiopianTimeConverter {

    enum class TimePeriod(
        val amharic: String,
        val english: String,
        val afaanOromo: String,
        val tigrinya: String
    ) {
        DAWN("ንጋት", "Dawn", "Barii", "ወጋሕታ"),
        MORNING("ጧት", "Morning", "Ganama", "ንግሆ"),
        MIDDAY("ቀትር", "Midday / Noon", "Guyyaa", "ቀትሪ"),
        AFTERNOON("ከሰዓት", "Afternoon", "Waaree booda", "ድሕሪ ቀትሪ"),
        EVENING("ምሽት", "Evening", "Galgala", "ምሸት"),
        NIGHT("ሌሊት", "Night", "Halkan", "ለይቲ"),
        MIDNIGHT("እኩለ ሌሊት", "Midnight", "Halkan walakkaa", "ፍርቂ ለይቲ")
    }

    data class EthiopianTime(
        val hour: Int, // 1..12
        val minute: Int,
        val isDaytime: Boolean, // true = daytime (ቀን), false = nighttime (ሌሊት)
        val period: TimePeriod
    ) {
        fun formatted(): String {
            val hStr = hour.toString()
            val mStr = String.format(Locale.US, "%02d", minute)
            val periodStr = if (isDaytime) "ቀን" else "ሌሊት"
            return "${period.amharic} $hStr:$mStr ($periodStr)"
        }
    }

    data class GregorianTime(
        val hour24: Int, // 0..23
        val minute: Int
    ) {
        val hour12: Int
            get() = when (val h = hour24 % 12) {
                0 -> 12
                else -> h
            }
        val isPm: Boolean
            get() = hour24 >= 12

        fun formatted(): String {
            val amPm = if (isPm) "PM" else "AM"
            return String.format(Locale.US, "%d:%02d %s (%02d:%02d)", hour12, minute, amPm, hour24, minute)
        }
    }

    /**
     * Converts 24-hour Gregorian time to Ethiopian time.
     */
    fun gregorianToEthiopian(gHour: Int, gMinute: Int): EthiopianTime {
        val totalMinutes = (gHour * 60 + gMinute) % (24 * 60)
        // 6:00 AM (360 mins) is Ethiopian 12:00 daytime (0 offset)
        val ethiopianMinutes = (totalMinutes - 360 + 1440) % 1440
        val ethHourRaw = ethiopianMinutes / 60
        val ethMinute = ethiopianMinutes % 60
        val ethHour = if (ethHourRaw % 12 == 0) 12 else ethHourRaw % 12
        val isDaytime = ethHourRaw < 12

        val period = determinePeriod(gHour, gMinute)
        return EthiopianTime(ethHour, ethMinute, isDaytime, period)
    }

    /**
     * Converts Ethiopian 12-hour time back to Gregorian 24-hour time.
     */
    fun ethiopianToGregorian(ethHour: Int, ethMinute: Int, isDaytime: Boolean): GregorianTime {
        val normalizedHour = if (ethHour == 12) 0 else ethHour
        val ethMinutes = (if (isDaytime) normalizedHour else normalizedHour + 12) * 60 + ethMinute
        // Add 6 hours (360 mins) to get Gregorian
        val gregMinutes = (ethMinutes + 360) % 1440
        val gHour = gregMinutes / 60
        val gMinute = gregMinutes % 60
        return GregorianTime(gHour, gMinute)
    }

    private fun determinePeriod(gHour: Int, gMinute: Int): TimePeriod {
        return when (gHour) {
            in 5..6 -> if (gHour == 6 && gMinute > 30) TimePeriod.MORNING else TimePeriod.DAWN
            in 7..11 -> TimePeriod.MORNING
            12 -> TimePeriod.MIDDAY
            in 13..17 -> TimePeriod.AFTERNOON
            in 18..20 -> TimePeriod.EVENING
            in 21..23 -> TimePeriod.NIGHT
            0 -> TimePeriod.MIDNIGHT
            in 1..4 -> TimePeriod.NIGHT
            else -> TimePeriod.MORNING
        }
    }
}
