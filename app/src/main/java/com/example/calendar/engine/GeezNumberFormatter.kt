package com.example.calendar.engine

import com.example.calendar.core.GeezNumeral

/**
 * Re-exports and delegates Ge'ez numeral conversions to the :calendar-core module.
 */
object GeezNumberFormatter {

    fun toGeez(num: Int): String = GeezNumeral.toGeez(num)

    fun isGeez(text: String): Boolean = GeezNumeral.isGeez(text)

    fun fromGeez(geez: String): Int? = GeezNumeral.fromGeez(geez)
}
