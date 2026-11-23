package com.example.calendar.core

/**
 * Bahire Hasab (ባሕረ ሐሳብ) - Computus of the Ethiopian Orthodox Tewahedo Church.
 *
 * Implements the mathematical and astronomical algorithms laid out by Patriarch Demetrius of Alexandria
 * (12th Pope of Alexandria, 189–232 AD) and canonicalized within the Ethiopian Ge'ez computational tradition.
 *
 * Provides exact calculation of:
 * - Amete Alem (ዓመተ ዓለም): 5500 + Ethiopian Year
 * - Evangelist (ወንጌላዊ): John, Matthew, Mark, Luke (Leap)
 * - Medeb (መደብ) & Wenber (ወንበር - Metonic 19-year Lunar Cycle Seat)
 * - Abekte (አበቅቴ - Epact / Lunar Year Surplus)
 * - Metqi (መጥቅዕ - Paschal Moon Position)
 * - Mebaja Hamer (መባጃ ሐመር - Easter Factor)
 * - Nenewe (ጾመ ነነዌ - Fast of Nineveh, the base date)
 * - All canonical movable fasts and feasts up to Pentecost, Apostles' Fast, and Fast of Salvation.
 */
object BahireHasab {

    /**
     * Canonical offset added to the Ethiopian Era (ዓመተ ምሕረት) to obtain the Era of Creation (ዓመተ ዓለም).
     */
    const val AMETE_FELESE_OFFSET = 5500

    /**
     * The Metonic lunar cycle length (19 solar years).
     */
    const val METONIC_CYCLE = 19

    /**
     * Annual epact increment (11 days difference between solar and lunar year).
     */
    const val EPACT_MULTIPLIER = 11

    /**
     * Canonical days in an ecclesiastical lunar month.
     */
    const val LUNAR_MONTH_DAYS = 30

    /**
     * Canonical day offsets from the Fast of Nineveh (ጾመ ነነዌ) to each movable feast.
     */
    object FeastOffsets {
        const val NENEWE = 0
        const val ABIY_TSOM = 14          // Great Lent (ዓቢይ ጾም - 14 days after Nineveh)
        const val DEBRE_ZEIT = 41         // Mount of Olives (ደብረ ዘይት - 41 days after Nineveh)
        const val HOSANNA = 62            // Palm Sunday (ሆሣዕና - 62 days after Nineveh)
        const val SIKLET = 67             // Good Friday (ስቅለት - 67 days after Nineveh)
        const val FASIKA = 69             // Easter / Resurrection (ፋሲካ / ትንሣኤ - 69 days after Nineveh)
        const val RIKBE_KAHNAT = 93       // Synod of Priests (ርክበ ካህናት - 93 days after Nineveh)
        const val ERGET = 108             // Ascension Day (ዕርገት - 108 days after Nineveh / 40 days after Easter)
        const val PARACLETE = 118         // Pentecost (ጰራቅሊጦስ - 118 days after Nineveh / 50 days after Easter)
        const val TSOME_HAWARYAT = 119    // Apostles' Fast (ጾመ ሐዋርያት - 119 days after Nineveh)
        const val TSOME_DIHNET = 121      // Fast of Salvation (ጾመ ድኅነት - 121 days after Nineveh)
    }

    /**
     * Represents a calculated movable Orthodox fast or feast.
     */
    data class OrthodoxFeast(
        val nameAmharic: String,
        val nameEnglish: String,
        val nameOromo: String,
        val nameTigrinya: String,
        val ethiopianDate: EthiopianDate,
        val description: String,
        val isFast: Boolean = false
    )

    /**
     * Complete computational result of Bahire Hasab for a given Ethiopian year.
     */
    data class Result(
        val ethiopianYear: Int,
        val ameteAlem: Int,
        val evangelist: LeapYearCalculator.Evangelist,
        val wenber: Int,
        val abeqte: Int,
        val metqi: Int,
        val metqiMonth: Int, // 1 = Meskerem, 2 = Tikimt
        val nenewe: EthiopianDate,
        val movableFeasts: List<OrthodoxFeast>
    )

    // =========================================================================
    // 1. CORE MATHEMATICAL COMPUTUS ALGORITHMS
    // =========================================================================

    /**
     * Calculates Amete Alem (ዓመተ ዓለም - Year of the World) from Creation:
     * Amete Alem = Ethiopian Year + 5500.
     */
    fun ameteAlem(year: Int): Int = year + AMETE_FELESE_OFFSET

    /**
     * Determines the Evangelist (ወንጌላዊ) of the Ethiopian year:
     * 1 = Matthew (ማቴዎስ), 2 = Mark (ማርቆስ), 3 = Luke (ሉቃስ - Leap Year), 0 = John (ዮሐንስ).
     */
    fun evangelist(year: Int): LeapYearCalculator.Evangelist =
        LeapYearCalculator.Evangelist.fromEthiopianYear(year)

    /**
     * Calculates Medeb (መደብ) - the position in the 19-year Metonic cycle:
     * Medeb = Amete Alem % 19.
     */
    fun medeb(year: Int): Int = ameteAlem(year) % METONIC_CYCLE

    /**
     * Calculates Wenber (ወንበር - Metonic Seat):
     * Wenber = (Amete Alem % 19) - 1. If result is -1, Wenber = 18.
     * Range: 0 to 18.
     */
    fun wenber(year: Int): Int {
        val raw = medeb(year) - 1
        return if (raw < 0) 18 else raw
    }

    /**
     * Calculates Abekte (አበቅቴ - Epact):
     * The age of the moon on Meskerem 1.
     * Abekte = (Wenber * 11) % 30.
     * Range: 0 to 29.
     */
    fun abeqte(year: Int): Int = (wenber(year) * EPACT_MULTIPLIER) % LUNAR_MONTH_DAYS

    /**
     * Calculates Metqi (መጥቅዕ - Paschal full moon position):
     * Metqi = 30 - Abekte. If Abekte == 0, Metqi = 30.
     * Range: 1 to 30.
     */
    fun metqi(year: Int): Int {
        val a = abeqte(year)
        return if (a == 0) 30 else 30 - a
    }

    /**
     * Determines the Ethiopian month in which Metqi falls:
     * If Metqi > 14, it falls in Meskerem (Month 1).
     * If Metqi <= 14, it falls in Tikimt (Month 2).
     */
    fun metqiMonth(year: Int): Int = if (metqi(year) > 14) 1 else 2

    /**
     * Returns the full EthiopianDate of Metqi.
     */
    fun metqiDate(year: Int): EthiopianDate =
        EthiopianDate(year, metqiMonth(year), metqi(year))

    /**
     * Returns the canonical Tewsak (ዕለተ ተውሳክ) for a day of the week:
     * - Sunday (7 / እሑድ) -> 7
     * - Monday (1 / ሰኞ) -> 6
     * - Tuesday (2 / ማክሰኞ) -> 5
     * - Wednesday (3 / ረቡዕ) -> 4
     * - Thursday (4 / ሐሙስ) -> 3
     * - Friday (5 / ዓርብ) -> 2
     * - Saturday (6 / ቅዳሜ) -> 8
     *
     * @param dayOfWeek 1 = Monday .. 7 = Sunday
     */
    fun dayOfWeekTewsak(dayOfWeek: Int): Int = when (dayOfWeek) {
        7 -> 7 // እሑድ
        1 -> 6 // ሰኞ
        2 -> 5 // ማክሰኞ
        3 -> 4 // ረቡዕ
        4 -> 3 // ሐሙስ
        5 -> 2 // ዓርብ
        6 -> 8 // ቅዳሜ
        else -> 0
    }

    /**
     * Calculates Mebaja Hamer (መባጃ ሐመር - Easter Factor):
     * Sum of Metqi day + day-of-week Tewsak.
     */
    fun mebajaHamer(year: Int): Int {
        val mDate = metqiDate(year)
        val dow = EthiopianDateConverter.getDayOfWeek(mDate)
        return mDate.day + dayOfWeekTewsak(dow)
    }

    /**
     * Calculates the exact date of the Fast of Nineveh (ጾመ ነነዌ).
     *
     * The foundational date of Bahire Hasab:
     * - If Metqi fell in Meskerem:
     *     - If (Metqi + Tewsak) <= 30: Month is Tir (5), Day is (Metqi + Tewsak).
     *     - If (Metqi + Tewsak) > 30: Month is Yakatit (6), Day is (Metqi + Tewsak - 30).
     * - If Metqi fell in Tikimt:
     *     - Month is Yakatit (6), Day is (Metqi + Tewsak).
     */
    fun nenewe(year: Int): EthiopianDate {
        val mMonth = metqiMonth(year)
        val mDate = metqiDate(year)
        val dow = EthiopianDateConverter.getDayOfWeek(mDate)
        val sum = mDate.day + dayOfWeekTewsak(dow)

        val neneweMonth: Int
        val neneweDay: Int

        if (mMonth == 1) { // Meskerem
            if (sum <= 30) {
                neneweMonth = 5 // Tir
                neneweDay = sum
            } else {
                neneweMonth = 6 // Yakatit
                neneweDay = sum - 30
            }
        } else { // Tikimt
            neneweMonth = 6 // Yakatit
            neneweDay = sum
        }

        return EthiopianDate(year, neneweMonth, neneweDay)
    }

    // =========================================================================
    // 2. INDIVIDUAL MOVABLE FEAST MATHEMATICAL ACCESSORS
    // =========================================================================

    /**
     * Internal helper to add day offset to a date via Julian Day Numbers.
     */
    private fun addDays(base: EthiopianDate, days: Int): EthiopianDate {
        val jdn = EthiopianDateConverter.ethiopianToJulianDay(base)
        return EthiopianDateConverter.julianDayToEthiopian(jdn + days)
    }

    /**
     * Calculates the start date of Great Lent (ዓቢይ ጾም / ሁዳዴ):
     * Exactly 14 days after Nineveh. Always begins on a Monday (ሰኞ).
     */
    fun abiyTsom(year: Int): EthiopianDate = addDays(nenewe(year), FeastOffsets.ABIY_TSOM)

    /**
     * Calculates Debre Zeit (ደብረ ዘይት - Mount of Olives):
     * Exactly 41 days after Nineveh. Mid-Lent Sunday (እሑድ).
     */
    fun debreZeit(year: Int): EthiopianDate = addDays(nenewe(year), FeastOffsets.DEBRE_ZEIT)

    /**
     * Calculates Hosanna / Palm Sunday (ሆሣዕና):
     * Exactly 62 days after Nineveh. Sunday before Easter (እሑድ).
     */
    fun hosanna(year: Int): EthiopianDate = addDays(nenewe(year), FeastOffsets.HOSANNA)

    /**
     * Calculates Good Friday / Siklet (ስቅለት):
     * Exactly 67 days after Nineveh. Friday before Easter (ዓርብ).
     */
    fun siklet(year: Int): EthiopianDate = addDays(nenewe(year), FeastOffsets.SIKLET)

    /**
     * Calculates Easter / Tensae / Fasika (ፋሲካ / ትንሣኤ):
     * Exactly 69 days after Nineveh. Always on a Sunday (እሑድ).
     */
    fun fasika(year: Int): EthiopianDate = addDays(nenewe(year), FeastOffsets.FASIKA)

    /**
     * Calculates Rikbe Kahnat (ርክበ ካህናት - Synod of the Clergy):
     * Exactly 93 days after Nineveh (24 days after Easter). Always on a Wednesday (ረቡዕ).
     */
    fun rikbeKahnat(year: Int): EthiopianDate = addDays(nenewe(year), FeastOffsets.RIKBE_KAHNAT)

    /**
     * Calculates Ascension Day / Erget (ዕርገት):
     * Exactly 108 days after Nineveh (40 days after Easter). Always on a Thursday (ሐሙስ).
     */
    fun erget(year: Int): EthiopianDate = addDays(nenewe(year), FeastOffsets.ERGET)

    /**
     * Calculates Pentecost / Paraclete (ጰራቅሊጦስ):
     * Exactly 118 days after Nineveh (50 days after Easter). Always on a Sunday (እሑድ).
     */
    fun paraclete(year: Int): EthiopianDate = addDays(nenewe(year), FeastOffsets.PARACLETE)

    /**
     * Calculates the start of Apostles' Fast (ጾመ ሐዋርያት / ጾመ ሰኔ):
     * Exactly 119 days after Nineveh (day after Pentecost). Always begins on a Monday (ሰኞ).
     */
    fun tsomeHawaryat(year: Int): EthiopianDate = addDays(nenewe(year), FeastOffsets.TSOME_HAWARYAT)

    /**
     * Calculates the start of Fast of Salvation (ጾመ ድኅነት):
     * Exactly 121 days after Nineveh. Always begins on a Wednesday (ረቡዕ).
     */
    fun tsomeDihnet(year: Int): EthiopianDate = addDays(nenewe(year), FeastOffsets.TSOME_DIHNET)

    /**
     * Calculates the duration (in days) of the Apostles' Fast (ጾመ ሐዋርያት) for the given year.
     * The fast begins the Monday after Pentecost and ends on Hamle 5 (Feast of Saints Peter & Paul).
     */
    fun apostlesFastDuration(year: Int): Int {
        val start = tsomeHawaryat(year)
        val end = EthiopianDate(year, 11, 5) // 5 Hamle
        val diff = EthiopianDateConverter.daysBetween(start, end)
        return kotlin.math.max(0, diff.toInt())
    }

    /**
     * Returns the fixed canonical duration of the Great Lent (55 days).
     */
    fun greatLentDuration(): Int = 55

    /**
     * Returns the fixed canonical duration of the Fast of Nineveh (3 days).
     */
    fun ninevehFastDuration(): Int = 3

    // =========================================================================
    // 3. FASTING PERIOD DETECTION ALGORITHMS
    // =========================================================================

    /**
     * Checks if the given date falls within Great Lent (ዓቢይ ጾም):
     * 55 continuous days from Abiy Tsom start date up to Holy Saturday (eve of Easter).
     */
    fun isGreatLent(date: EthiopianDate): Boolean {
        val lentStart = abiyTsom(date.year)
        val easter = fasika(date.year)
        val dateJdn = EthiopianDateConverter.ethiopianToJulianDay(date)
        val startJdn = EthiopianDateConverter.ethiopianToJulianDay(lentStart)
        val easterJdn = EthiopianDateConverter.ethiopianToJulianDay(easter)
        return dateJdn in startJdn until easterJdn
    }

    /**
     * Checks if the given date falls within the Apostles' Fast (ጾመ ሐዋርያት):
     * From Monday after Pentecost until Hamle 5 (inclusive).
     */
    fun isApostlesFast(date: EthiopianDate): Boolean {
        val fastStart = tsomeHawaryat(date.year)
        val fastEnd = EthiopianDate(date.year, 11, 5)
        val dateJdn = EthiopianDateConverter.ethiopianToJulianDay(date)
        val startJdn = EthiopianDateConverter.ethiopianToJulianDay(fastStart)
        val endJdn = EthiopianDateConverter.ethiopianToJulianDay(fastEnd)
        return dateJdn in startJdn..endJdn
    }

    /**
     * Checks if the given date falls within the Fast of Nineveh (ጾመ ነነዌ):
     * Exactly 3 days starting from Nenewe (Monday, Tuesday, Wednesday).
     */
    fun isNinevehFast(date: EthiopianDate): Boolean {
        val neneweStart = nenewe(date.year)
        val dateJdn = EthiopianDateConverter.ethiopianToJulianDay(date)
        val startJdn = EthiopianDateConverter.ethiopianToJulianDay(neneweStart)
        return dateJdn in startJdn until (startJdn + 3)
    }

    /**
     * Checks if the given date falls within the Fifty Days of Joy (ሃምሳ ፌስሐ):
     * The 50 days between Easter (Fasika) and Pentecost, during which Wednesday and Friday
     * fasts are canonically relaxed.
     */
    fun isFiftyDaysOfJoy(date: EthiopianDate): Boolean {
        val easter = fasika(date.year)
        val pentecost = paraclete(date.year)
        val dateJdn = EthiopianDateConverter.ethiopianToJulianDay(date)
        val easterJdn = EthiopianDateConverter.ethiopianToJulianDay(easter)
        val pentecostJdn = EthiopianDateConverter.ethiopianToJulianDay(pentecost)
        return dateJdn in easterJdn..pentecostJdn
    }

    /**
     * Checks if the date is an ordinary weekly fast day (Wednesday or Friday)
     * outside the Fifty Days of Joy.
     */
    fun isWeeklyFastDay(date: EthiopianDate): Boolean {
        val dow = EthiopianDateConverter.getDayOfWeek(date)
        if (dow != 3 && dow != 5) return false // 3 = Wednesday (ረቡዕ), 5 = Friday (ዓርብ)
        return !isFiftyDaysOfJoy(date)
    }

    // =========================================================================
    // 4. COMPLETE FEAST GENERATION & AGGREGATION
    // =========================================================================

    /**
     * Returns the full canonical list of all 11 movable feasts and fasts for an Ethiopian year.
     */
    fun getMovableFeasts(year: Int): List<OrthodoxFeast> {
        val neneweDate = nenewe(year)
        val neneweJdn = EthiopianDateConverter.ethiopianToJulianDay(neneweDate)

        fun feastAt(
            offset: Int,
            amharic: String,
            english: String,
            oromo: String,
            tigrinya: String,
            desc: String,
            isFast: Boolean
        ): OrthodoxFeast {
            val d = EthiopianDateConverter.julianDayToEthiopian(neneweJdn + offset)
            return OrthodoxFeast(amharic, english, oromo, tigrinya, d, desc, isFast)
        }

        return listOf(
            OrthodoxFeast(
                "ጾመ ነነዌ",
                "Fast of Nineveh (Nenewe)",
                "Sooma Nanawwee",
                "ጾመ ነነዌ",
                neneweDate,
                "Three-day fast commemorating the repentance of the city of Nineveh.",
                isFast = true
            ),
            feastAt(
                FeastOffsets.ABIY_TSOM,
                "ዓቢይ ጾም (ሁዳዴ)",
                "Great Lent (Abiy Tsom)",
                "Sooma Guddaa",
                "ዓቢይ ጾም",
                "The 55-day Great Lent commemorating Jesus Christ's 40 days of fasting in the wilderness.",
                isFast = true
            ),
            feastAt(
                FeastOffsets.DEBRE_ZEIT,
                "ደብረ ዘይት",
                "Mount of Olives (Debre Zeit)",
                "Gaara Zayt",
                "ደብረ ዘይት",
                "Mid-Lent Sunday focusing on Christ's prophecy on the Mount of Olives.",
                isFast = false
            ),
            feastAt(
                FeastOffsets.HOSANNA,
                "ሆሣዕና",
                "Palm Sunday (Hosanna)",
                "Hosaa'inaa",
                "ሆሣዕና",
                "Triumphant entry of our Lord Jesus Christ into Jerusalem.",
                isFast = false
            ),
            feastAt(
                FeastOffsets.SIKLET,
                "ስቅለት (ዓርበ ስቅለት)",
                "Good Friday (Siklet)",
                "Fannoo (Jimaata Fannoo)",
                "ዓርቢ ስቅለት",
                "Solemn commemoration of the Crucifixion and death of Jesus Christ on Golgotha.",
                isFast = true
            ),
            feastAt(
                FeastOffsets.FASIKA,
                "ትንሣኤ (ፋሲካ)",
                "Easter / Resurrection (Tensae / Fasika)",
                "Fasika / Du'aa Ka'uu",
                "ትንሣኤ (ፋሲካ)",
                "The glorious Feast of the Resurrection of Jesus Christ from the dead.",
                isFast = false
            ),
            feastAt(
                FeastOffsets.RIKBE_KAHNAT,
                "ርክበ ካህናት",
                "Rikbe Kahnat (Synod of Priests)",
                "Waldaa Lubootaa",
                "ርክበ ካህናት",
                "Canonical assembly of the priesthood following the Feast of Easter.",
                isFast = false
            ),
            feastAt(
                FeastOffsets.ERGET,
                "ዕርገት",
                "Ascension Day (Erget)",
                "Ol Ba'iinsa",
                "ዕርገት",
                "Celebrates the bodily Ascension of Jesus Christ into Heaven, 40 days after Easter.",
                isFast = false
            ),
            feastAt(
                FeastOffsets.PARACLETE,
                "ጰራቅሊጦስ",
                "Pentecost (Paraclete)",
                "Qulqulluu Phaaraaqliixoos",
                "ጰራቅሊጦስ",
                "Descent of the Holy Spirit upon the Holy Apostles, 50 days after Easter.",
                isFast = false
            ),
            feastAt(
                FeastOffsets.TSOME_HAWARYAT,
                "ጾመ ሐዋርያት (ጾመ ሰኔ)",
                "Apostles' Fast (Tsome Hawaryat)",
                "Sooma Ergamootaa",
                "ጾመ ሐዋርያት",
                "Commemorates the apostles beginning their preaching mission; lasts until Hamle 5.",
                isFast = true
            ),
            feastAt(
                FeastOffsets.TSOME_DIHNET,
                "ጾመ ድኅነት",
                "Fast of Salvation (Tsome Dihnet)",
                "Sooma Fayyinaa",
                "ጾመ ድኅነት",
                "Resumption of Wednesday and Friday fasts following the Fifty Days of Pentecost.",
                isFast = true
            )
        )
    }

    /**
     * Calculates the complete Bahire Hasab report for a given Ethiopian year.
     */
    fun calculate(year: Int): Result {
        return Result(
            ethiopianYear = year,
            ameteAlem = ameteAlem(year),
            evangelist = evangelist(year),
            wenber = wenber(year),
            abeqte = abeqte(year),
            metqi = metqi(year),
            metqiMonth = metqiMonth(year),
            nenewe = nenewe(year),
            movableFeasts = getMovableFeasts(year)
        )
    }
}
