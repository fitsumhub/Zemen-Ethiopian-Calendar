package com.example.calendar.core

/**
 * High-fidelity converter between Arabic numerals (1, 2, 3...)
 * and traditional Ethiopian Ge'ez numerals (፩, ፪, ፫, ፲, ፻, ፼).
 *
 * Implements canonical Ethiopian numeral formatting rules:
 * - 1..9: ፩ .. ፱
 * - 10..90: ፲ .. ፺
 * - 100: ፻ (single hundred does not use prefix ፩)
 * - 10,000: ፼ (single ten-thousand does not use prefix ፩)
 */
object GeezNumeral {

    private val GEEZ_ONES = arrayOf("", "፩", "፪", "፫", "፬", "፭", "፮", "፯", "፰", "፱")
    private val GEEZ_TENS = arrayOf("", "፲", "፳", "፴", "፵", "፶", "፷", "፸", "፹", "፺")
    private const val GEEZ_HUNDRED = "፻"
    private const val GEEZ_TEN_THOUSAND = "፼"
    private const val ALL_GEEZ_CHARS = "፩፪፫፬፭፮፯፰፱፲፳፴፵፶፷፸፹፺፻፼"

    /**
     * Converts a positive integer into its traditional Ge'ez numeral representation.
     */
    fun toGeez(num: Int): String {
        if (num <= 0) return num.toString()

        // 1 to 99
        if (num < 100) {
            val tens = num / 10
            val ones = num % 10
            return GEEZ_TENS[tens] + GEEZ_ONES[ones]
        }

        // 100 to 9,999
        if (num < 10000) {
            val hundreds = num / 100
            val remainder = num % 100
            val prefix = if (hundreds == 1) GEEZ_HUNDRED else toGeez(hundreds) + GEEZ_HUNDRED
            val suffix = if (remainder > 0) toGeez(remainder) else ""
            return prefix + suffix
        }

        // 10,000 and above
        val tenThousands = num / 10000
        val remainder = num % 10000
        val prefix = if (tenThousands == 1) GEEZ_TEN_THOUSAND else toGeez(tenThousands) + GEEZ_TEN_THOUSAND
        val suffix = if (remainder > 0) toGeez(remainder) else ""
        return prefix + suffix
    }

    /**
     * Checks if a string contains valid Ge'ez numerals.
     */
    fun isGeez(text: String): Boolean {
        if (text.isEmpty()) return false
        return text.all { it in ALL_GEEZ_CHARS }
    }

    /**
     * Parses standard Ge'ez numerals back into an integer.
     */
    fun fromGeez(geez: String): Int? {
        if (geez.isEmpty()) return null
        var total = 0
        var currentChunk = 0

        var i = 0
        while (i < geez.length) {
            val c = geez[i].toString()
            when (c) {
                GEEZ_TEN_THOUSAND -> {
                    val multiplier = if (currentChunk == 0) 1 else currentChunk
                    total += multiplier * 10000
                    currentChunk = 0
                }
                GEEZ_HUNDRED -> {
                    val multiplier = if (currentChunk == 0) 1 else currentChunk
                    total += multiplier * 100
                    currentChunk = 0
                }
                else -> {
                    val oneIdx = GEEZ_ONES.indexOf(c)
                    if (oneIdx > 0) {
                        currentChunk += oneIdx
                    } else {
                        val tenIdx = GEEZ_TENS.indexOf(c)
                        if (tenIdx > 0) {
                            currentChunk += tenIdx * 10
                        }
                    }
                }
            }
            i++
        }
        total += currentChunk
        return if (total > 0) total else null
    }
}
