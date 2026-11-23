package com.example.calendar.core

/**
 * Enumeration representing all 13 months of the Ethiopian calendar (አውራኅ).
 * Includes the 12 regular 30-day months and Pagume (ጳጉሜ / the epagomenal month).
 */
enum class EthiopianMonth(
    val number: Int,
    val amharicName: String,
    val englishName: String,
    val geezName: String,
    val oromoName: String,
    val tigrinyaName: String,
    val seasonAmharic: String,
    val seasonEnglish: String
) {
    MESKEREM(1, "መስከረም", "Meskerem", "ወርኀ መስከረም", "Fulbaana", "መስከረም", "መጸው", "Autumn"),
    TIKIMT(2, "ጥቅምት", "Tikimt", "ወርኀ ጥቅምት", "Onkololeessa", "ጥቅምቲ", "መጸው", "Autumn"),
    HIDAR(3, "ኅዳር", "Hidar", "ወርኀ ኅዳር", "Sadaasa", "ሕዳር", "መጸው", "Autumn"),
    TAHSAS(4, "ታኅሣሥ", "Tahsas", "ወርኀ ታኅሣሥ", "Muddee", "ታሕሳስ", "በጋ", "Winter"),
    TIR(5, "ጥር", "Tir", "ወርኀ ጥር", "Amajjii", "ጥሪ", "በጋ", "Winter"),
    YAKATIT(6, "የካቲት", "Yakatit", "ወርኀ የካቲት", "Guraandhala", "የካቲት", "በጋ", "Winter"),
    MEGABIT(7, "መጋቢት", "Megabit", "ወርኀ መጋቢት", "Bitooteessa", "መጋቢት", "ጸደይ", "Spring"),
    MIAZIA(8, "ሚያዝያ", "Miazia", "ወርኀ ሚያዝያ", "Ebla", "ሚያዝያ", "ጸደይ", "Spring"),
    GINBOT(9, "ግንቦት", "Ginbot", "ወርኀ ግንቦት", "Caamsaa", "ግንቦት", "ጸደይ", "Spring"),
    SENE(10, "ሰኔ", "Sene", "ወርኀ ሰኔ", "Waxabajjii", "ሰነ", "ክረምት", "Summer"),
    HAMLE(11, "ሐምሌ", "Hamle", "ወርኀ ሐምሌ", "Adooleessa", "ሓምለ", "ክረምት", "Summer"),
    NEHASE(12, "ነሐሴ", "Nehase", "ወርኀ ነሐሴ", "Hagayya", "ነሓሰ", "ክረምት", "Summer"),
    PAGUME(13, "ጳጉሜ", "Pagume", "ወርኀ ጳጉሜን", "Qaammee", "ጳጉሜን", "ክረምት", "Summer");

    /**
     * Returns the number of days in this month for a given year.
     * Regular months (1..12) always have 30 days.
     * Pagume (13) has 6 days in an Ethiopian leap year, 5 days otherwise.
     */
    fun daysInMonth(isLeapYear: Boolean): Int {
        return if (this == PAGUME) {
            if (isLeapYear) 6 else 5
        } else {
            30
        }
    }

    companion object {
        fun fromNumber(monthNumber: Int): EthiopianMonth {
            require(monthNumber in 1..13) { "Month number must be between 1 and 13, received: $monthNumber" }
            return entries[monthNumber - 1]
        }
    }
}
