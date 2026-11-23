package com.example.calendar.core

/**
 * The Four Canonical Seasons of Ethiopia (አራቱ የኢትዮጵያ ወቅቶች):
 * - Metsew / Meher (መፀው / መኸር - Autumn / Harvest): Meskerem 26 - Tahsas 25
 * - Bega (በጋ - Winter / Dry): Tahsas 26 - Megabit 25
 * - Tseday / Belg (ጸደይ / በልግ - Spring / Blossom): Megabit 26 - Sene 25
 * - Kiremt (ክረምት - Summer / Rainy): Sene 26 - Meskerem 25 (including Pagume)
 */
enum class EthiopianSeason(
    val amharicName: String,
    val englishName: String,
    val descriptionAmharic: String,
    val descriptionEnglish: String,
    val emoji: String
) {
    METSEW_MEHER(
        "መፀው (መኸር)",
        "Autumn / Harvest (Meher)",
        "ከመስከረም 26 እስከ ታኅሣሥ 25። የአዝመራ፣ የአበባና የምስጋና ወቅት።",
        "From Meskerem 26 to Tahsas 25. The season of harvest, blooming Adey Abeba, and thanksgiving.",
        "🌾"
    ),
    BEGA(
        "በጋ",
        "Winter / Dry (Bega)",
        "ከታኅሣሥ 26 እስከ መጋቢት 25። ፀሐያማ፣ ደረቅና የጥምቀት በዓላት ወቅት።",
        "From Tahsas 26 to Megabit 25. The sunny and dry season marked by Timkat and Kana ZeGalila.",
        "☀️"
    ),
    TSEDAY_BELG(
        "ጸደይ (በልግ)",
        "Spring / Blossom (Tseday / Belg)",
        "ከመጋቢት 26 እስከ ሰኔ 25። የትንሣኤ (ፋሲካ) እና የልምላሜ ወቅት።",
        "From Megabit 26 to Sene 25. The season of spring blossoms, green growth, and Easter (Fasika).",
        "🌱"
    ),
    KIREMT(
        "ክረምት",
        "Summer / Rainy (Kiremt)",
        "ከሰኔ 26 እስከ መስከረም 25 (ጳጉሜን ጨምሮ)። የዝናብ፣ የጎርፍና የጾመ ፍልሰታ ወቅት።",
        "From Sene 26 to Meskerem 25 (including Pagume). The season of heavy rains, lush greenery, and Filseta.",
        "🌧️"
    );

    companion object {
        /**
         * Returns the Ethiopian season for any given Ethiopian month and day.
         */
        fun fromEthiopianDate(month: Int, day: Int): EthiopianSeason {
            return when (month) {
                1 -> if (day <= 25) KIREMT else METSEW_MEHER
                2, 3 -> METSEW_MEHER
                4 -> if (day <= 25) METSEW_MEHER else BEGA
                5, 6 -> BEGA
                7 -> if (day <= 25) BEGA else TSEDAY_BELG
                8, 9 -> TSEDAY_BELG
                10 -> if (day <= 25) TSEDAY_BELG else KIREMT
                11, 12, 13 -> KIREMT
                else -> KIREMT
            }
        }

        fun fromEthiopianDate(date: EthiopianDate): EthiopianSeason =
            fromEthiopianDate(date.month, date.day)
    }
}
