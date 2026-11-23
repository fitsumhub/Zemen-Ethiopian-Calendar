package com.example.calendar.core

import java.util.Locale

/**
 * Traditional Ethiopian timekeeping converter and models.
 *
 * In Ethiopia, a 12-hour cycle begins at sunrise (approx 6:00 AM Gregorian = 12:00 morning Ethiopian)
 * and the night cycle begins at sunset (approx 6:00 PM Gregorian = 12:00 night Ethiopian).
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
        require(gHour in 0..23) { "Hour must be between 0 and 23, was: $gHour" }
        require(gMinute in 0..59) { "Minute must be between 0 and 59, was: $gMinute" }

        val isDaytime = gHour in 6..17
        val ethHour = when {
            gHour >= 6 -> (gHour - 6).let { if (it == 0) 12 else if (it > 12) it - 12 else it }
            else -> (gHour + 6).let { if (it == 0) 12 else it }
        }

        val period = when (gHour) {
            5 -> TimePeriod.DAWN
            6, 7, 8, 9, 10, 11 -> TimePeriod.MORNING
            12 -> TimePeriod.MIDDAY
            13, 14, 15, 16, 17 -> TimePeriod.AFTERNOON
            18, 19, 20 -> TimePeriod.EVENING
            21, 22, 23 -> TimePeriod.NIGHT
            0 -> TimePeriod.MIDNIGHT
            else -> TimePeriod.NIGHT
        }

        return EthiopianTime(ethHour, gMinute, isDaytime, period)
    }

    /**
     * Converts 12-hour Ethiopian time to 24-hour Gregorian time.
     */
    fun ethiopianToGregorian(ethHour: Int, ethMinute: Int, isDaytime: Boolean): GregorianTime {
        require(ethHour in 1..12) { "Ethiopian hour must be between 1 and 12, was: $ethHour" }
        require(ethMinute in 0..59) { "Minute must be between 0 and 59, was: $ethMinute" }

        val gHour = if (isDaytime) {
            (ethHour % 12) + 6
        } else {
            ((ethHour % 12) + 18) % 24
        }

        return GregorianTime(gHour, ethMinute)
    }
}
