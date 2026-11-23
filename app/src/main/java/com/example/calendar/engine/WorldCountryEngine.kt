package com.example.calendar.engine

import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

/**
 * High-precision World, European & Regional Conversion Engine.
 * Supports:
 * 1. World & European Timezone Conversions from Ethiopian 12h clock & Addis Ababa EAT (UTC+3)
 * 2. Multi-Calendar conversions: Gregorian (EU/US), Julian (Eastern Orthodox Europe),
 *    Coptic (Egypt), Islamic/Hijri (Middle East), and ISO 8601
 * 3. Country-specific date formats, European astronomical seasons, financial quarters,
 *    and workweek/business hour comparisons between Ethiopia and Europe/World countries.
 */
object WorldCountryEngine {

    enum class WorldRegion(val labelEn: String, val labelAm: String) {
        ALL("All Cities", "ሁሉም ከተሞች"),
        EUROPE("🇪🇺 Europe", "አውሮፓ"),
        AMERICAS("🌎 Americas", "አሜሪካ"),
        MIDDLE_EAST("🇸🇦 Middle East", "መካከለኛው ምስራቅ"),
        ASIA_OCEANIA("🌏 Asia & Pacific", "እስያ እና ፓሲፊክ"),
        AFRICA("🌍 Africa", "አፍሪካ")
    }

    enum class BusinessStatus(val label: String, val colorHex: Long) {
        OPEN("🟢 Business Hours (Open)", 0xFF10B981),
        LEISURE("🟡 Morning / Evening (Active)", 0xFFF59E0B),
        SLEEPING("🌙 Night / Sleeping", 0xFF6B7280)
    }

    data class WorldCity(
        val id: String,
        val cityEn: String,
        val cityAm: String,
        val countryEn: String,
        val countryAm: String,
        val flag: String,
        val timeZoneId: String,
        val region: WorldRegion,
        val dialCode: String,
        val currency: String
    )

    data class WorldCityTimeResult(
        val city: WorldCity,
        val hour24: Int,
        val minute: Int,
        val hour12: Int,
        val isPm: Boolean,
        val timeZoneAbbreviation: String,
        val rawOffsetHours: Double,
        val differenceFromAddisHours: Double,
        val dayOffset: Int, // -1 = yesterday, 0 = same day, +1 = tomorrow
        val businessStatus: BusinessStatus,
        val formattedTime12: String,
        val formattedTime24: String
    )

    data class EuropeanCalendarResult(
        val gregorianFormattedEu: String,      // 14.11.2026 (Europe standard)
        val gregorianFormattedUk: String,      // 14/11/2026 (UK / Ireland)
        val gregorianFormattedDe: String,      // 14. November 2026 (Germany / Austria)
        val gregorianFormattedFr: String,      // 14/11/2026 (France / Italy)
        val gregorianFormattedUs: String,      // 11/14/2026 (USA / Canada)
        val iso8601: String,                   // 2026-11-14
        val julianDateStr: String,             // Julian Calendar (Orthodox Europe)
        val julianYear: Int,
        val julianMonth: Int,
        val julianDay: Int,
        val copticDateStr: String,             // Coptic Calendar (Egypt)
        val copticYear: Int,
        val copticMonthName: String,
        val copticDay: Int,
        val hijriDateStr: String,              // Hijri Calendar (Middle East)
        val europeanSeasonEn: String,
        val europeanSeasonAm: String,
        val europeanSeasonEmoji: String,
        val europeanQuarter: String,           // Q1 - Q4
        val dayOfYear: Int,
        val weekOfYear: Int,
        val isEuropeanWeekend: Boolean,
        val isEthiopianWeekend: Boolean,
        val yearOffsetExplanation: String
    )

    data class CountryProfile(
        val id: String,
        val nameEn: String,
        val nameAm: String,
        val capitalEn: String,
        val flag: String,
        val region: String,
        val timeZoneId: String,
        val timeZoneName: String,
        val dialCode: String,
        val currencyName: String,
        val currencySymbol: String,
        val dateFormatExample: String,
        val workweek: String,
        val businessHours: String,
        val callingRecommendationFromAddis: String,
        val holidayDifferences: String,
        val seasonDifference: String
    )

    // Curated list of World & European cities relevant to Ethiopian diaspora, trade & diplomacy
    val WORLD_CITIES = listOf(
        WorldCity("lon", "London", "ለንደን", "United Kingdom", "እንግሊዝ", "🇬🇧", "Europe/London", WorldRegion.EUROPE, "+44", "GBP (£)"),
        WorldCity("ber", "Berlin", "በርሊን", "Germany", "ጀርመን", "🇩🇪", "Europe/Berlin", WorldRegion.EUROPE, "+49", "EUR (€)"),
        WorldCity("par", "Paris", "ፓሪስ", "France", "ፈረንሳይ", "🇫🇷", "Europe/Paris", WorldRegion.EUROPE, "+33", "EUR (€)"),
        WorldCity("rom", "Rome", "ሮም", "Italy", "ጣሊያን", "🇮🇹", "Europe/Rome", WorldRegion.EUROPE, "+39", "EUR (€)"),
        WorldCity("sto", "Stockholm", "ስቶክሆልም", "Sweden", "ስዊድን", "🇸🇪", "Europe/Stockholm", WorldRegion.EUROPE, "+46", "SEK (kr)"),
        WorldCity("ams", "Amsterdam", "አምስተርዳም", "Netherlands", "ኔዘርላንድስ", "🇳🇱", "Europe/Amsterdam", WorldRegion.EUROPE, "+31", "EUR (€)"),
        WorldCity("zur", "Zurich", "ዙሪክ", "Switzerland", "ስዊዘርላንድ", "🇨🇭", "Europe/Zurich", WorldRegion.EUROPE, "+41", "CHF (Fr)"),
        WorldCity("bru", "Brussels", "ብራሰልስ", "Belgium", "ቤልጂየም", "🇧🇪", "Europe/Brussels", WorldRegion.EUROPE, "+32", "EUR (€)"),
        WorldCity("ath", "Athens", "አቴንስ", "Greece", "ግሪክ", "🇬🇷", "Europe/Athens", WorldRegion.EUROPE, "+30", "EUR (€)"),
        WorldCity("hel", "Helsinki", "ሄልሲንኪ", "Finland", "ፊንላንድ", "🇫🇮", "Europe/Helsinki", WorldRegion.EUROPE, "+358", "EUR (€)"),
        WorldCity("mos", "Moscow", "ሞስኮ", "Russia", "ሩሲያ", "🇷🇺", "Europe/Moscow", WorldRegion.EUROPE, "+7", "RUB (₽)"),

        // Americas
        WorldCity("was", "Washington D.C.", "ዋሽንግተን ዲሲ", "United States", "አሜሪካ", "🇺🇸", "America/New_York", WorldRegion.AMERICAS, "+1", "USD ($)"),
        WorldCity("nyc", "New York", "ኒው ዮርክ", "United States", "አሜሪካ", "🇺🇸", "America/New_York", WorldRegion.AMERICAS, "+1", "USD ($)"),
        WorldCity("lax", "Los Angeles", "ሎስ አንጀለስ", "United States", "አሜሪካ", "🇺🇸", "America/Los_Angeles", WorldRegion.AMERICAS, "+1", "USD ($)"),
        WorldCity("tor", "Toronto", "ቶሮንቶ", "Canada", "ካናዳ", "🇨🇦", "America/Toronto", WorldRegion.AMERICAS, "+1", "CAD ($)"),

        // Middle East & Gulf
        WorldCity("dxb", "Dubai", "ዱባይ", "United Arab Emirates", "የተባበሩት አረብ ኤምሬቶች", "🇦🇪", "Asia/Dubai", WorldRegion.MIDDLE_EAST, "+971", "AED (د.إ)"),
        WorldCity("ruh", "Riyadh", "ሪያድ", "Saudi Arabia", "ሳውዲ አረቢያ", "🇸🇦", "Asia/Riyadh", WorldRegion.MIDDLE_EAST, "+966", "SAR (﷼)"),
        WorldCity("doh", "Doha", "ዶሃ", "Qatar", "ኳታር", "🇶🇦", "Asia/Qatar", WorldRegion.MIDDLE_EAST, "+974", "QAR (﷼)"),
        WorldCity("kwi", "Kuwait City", "ኩዌት ሲቲ", "Kuwait", "ኩዌት", "🇰🇼", "Asia/Kuwait", WorldRegion.MIDDLE_EAST, "+965", "KWD (د.ك)"),

        // Africa
        WorldCity("cai", "Cairo", "ካይሮ", "Egypt", "ግብፅ", "🇪🇬", "Africa/Cairo", WorldRegion.AFRICA, "+20", "EGP (E£)"),
        WorldCity("nbo", "Nairobi", "ናይሮቢ", "Kenya", "ኬንያ", "🇰🇪", "Africa/Nairobi", WorldRegion.AFRICA, "+254", "KES (KSh)"),
        WorldCity("jnb", "Johannesburg", "ጆሃንስበርግ", "South Africa", "ደቡብ አፍሪካ", "🇿🇦", "Africa/Johannesburg", WorldRegion.AFRICA, "+27", "ZAR (R)"),

        // Asia & Oceania
        WorldCity("syd", "Sydney", "ሲድኒ", "Australia", "አውስትራሊያ", "🇦🇺", "Australia/Sydney", WorldRegion.ASIA_OCEANIA, "+61", "AUD ($)"),
        WorldCity("mel", "Melbourne", "ሜልበርን", "Australia", "አውስትራሊያ", "🇦🇺", "Australia/Melbourne", WorldRegion.ASIA_OCEANIA, "+61", "AUD ($)"),
        WorldCity("tyo", "Tokyo", "ቶኪዮ", "Japan", "ጃፓን", "🇯🇵", "Asia/Tokyo", WorldRegion.ASIA_OCEANIA, "+81", "JPY (¥)"),
        WorldCity("bjs", "Beijing", "ቤጂንግ", "China", "ቻይና", "🇨🇳", "Asia/Shanghai", WorldRegion.ASIA_OCEANIA, "+86", "CNY (¥)")
    )

    val COUNTRY_PROFILES = listOf(
        CountryProfile(
            id = "de",
            nameEn = "Germany (Federal Republic)",
            nameAm = "ጀርመን",
            capitalEn = "Berlin",
            flag = "🇩🇪",
            region = "Central Europe",
            timeZoneId = "Europe/Berlin",
            timeZoneName = "CET (UTC+1) / CEST (UTC+2 in Summer)",
            dialCode = "+49",
            currencyName = "Euro",
            currencySymbol = "EUR (€)",
            dateFormatExample = "DD.MM.YYYY (e.g. 14.11.2026)",
            workweek = "Monday – Friday (40 hrs/wk). Saturday & Sunday closed.",
            businessHours = "08:30 – 17:00 CET",
            callingRecommendationFromAddis = "11:00 AM – 05:00 PM Addis Ababa time (corresponds to 09:00 AM – 03:00 PM in Germany).",
            holidayDifferences = "Western Christmas (Dec 25/26), German Unity Day (Oct 3). Ethiopian Genna (Jan 7) & Meskel are regular working days.",
            seasonDifference = "European Winter (Dec–Feb) is cold/snowy, while Ethiopia enjoys sunny Bega (dry harvest). European Summer (Jun–Aug) is warm, while Ethiopia has main rainy season (Kiremt)."
        ),
        CountryProfile(
            id = "uk",
            nameEn = "United Kingdom",
            nameAm = "እንግሊዝ / ብሪታንያ",
            capitalEn = "London",
            flag = "🇬🇧",
            region = "Western Europe",
            timeZoneId = "Europe/London",
            timeZoneName = "GMT (UTC+0) / BST (UTC+1 in Summer)",
            dialCode = "+44",
            currencyName = "British Pound Sterling",
            currencySymbol = "GBP (£)",
            dateFormatExample = "DD/MM/YYYY (e.g. 14/11/2026)",
            workweek = "Monday – Friday. Saturday & Sunday weekend.",
            businessHours = "09:00 – 17:30 GMT",
            callingRecommendationFromAddis = "12:00 PM – 06:00 PM Addis Ababa time (corresponds to 09:00 AM – 03:00 PM in London).",
            holidayDifferences = "Christmas (Dec 25), Boxing Day (Dec 26), Bank Holidays. Fiscal year starts April 6, whereas Ethiopian fiscal year starts Hamle 1 (July 8).",
            seasonDifference = "Temperate maritime climate. UK Spring (Mar–May) coincides with Ethiopian Belg."
        ),
        CountryProfile(
            id = "fr",
            nameEn = "France",
            nameAm = "ፈረንሳይ",
            capitalEn = "Paris",
            flag = "🇫🇷",
            region = "Western Europe",
            timeZoneId = "Europe/Paris",
            timeZoneName = "CET (UTC+1) / CEST (UTC+2 in Summer)",
            dialCode = "+33",
            currencyName = "Euro",
            currencySymbol = "EUR (€)",
            dateFormatExample = "DD/MM/YYYY (e.g. 14/11/2026)",
            workweek = "Monday – Friday (35 hrs standard). Saturday & Sunday weekend.",
            businessHours = "09:00 – 18:00 CET",
            callingRecommendationFromAddis = "11:00 AM – 05:00 PM Addis Ababa time.",
            holidayDifferences = "Bastille Day (July 14), Assumption (Aug 15). Uses Gregorian calendar exclusively.",
            seasonDifference = "Four distinct European seasons with daylight saving time changes in late March and late October."
        ),
        CountryProfile(
            id = "it",
            nameEn = "Italy",
            nameAm = "ጣሊያን",
            capitalEn = "Rome",
            flag = "🇮🇹",
            region = "Southern Europe",
            timeZoneId = "Europe/Rome",
            timeZoneName = "CET (UTC+1) / CEST (UTC+2 in Summer)",
            dialCode = "+39",
            currencyName = "Euro",
            currencySymbol = "EUR (€)",
            dateFormatExample = "DD/MM/YYYY (e.g. 14/11/2026)",
            workweek = "Monday – Friday. Saturday & Sunday weekend.",
            businessHours = "09:00 – 18:00 CET",
            callingRecommendationFromAddis = "11:00 AM – 05:00 PM Addis Ababa time.",
            holidayDifferences = "Ferragosto (Aug 15), Epifania (Jan 6 - one day before Ethiopian Genna).",
            seasonDifference = "Mediterranean climate. Ethiopian community in Rome/Milan celebrates Timket and Meskel with vibrant diaspora gatherings."
        ),
        CountryProfile(
            id = "se",
            nameEn = "Sweden",
            nameAm = "ስዊድን",
            capitalEn = "Stockholm",
            flag = "🇸🇪",
            region = "Northern Europe (Scandinavia)",
            timeZoneId = "Europe/Stockholm",
            timeZoneName = "CET (UTC+1) / CEST (UTC+2 in Summer)",
            dialCode = "+46",
            currencyName = "Swedish Krona",
            currencySymbol = "SEK (kr)",
            dateFormatExample = "YYYY-MM-DD or DD.MM.YYYY",
            workweek = "Monday – Friday. Very strict family-friendly hours.",
            businessHours = "08:30 – 16:30 CET",
            callingRecommendationFromAddis = "10:30 AM – 04:30 PM Addis Ababa time.",
            holidayDifferences = "Midsummer (late June), Lucia (Dec 13). Long daylight hours in summer and short dark days in winter.",
            seasonDifference = "Subarctic/temperate climate with deep snow in winter contrasted with Ethiopia's highland subtropical warmth."
        ),
        CountryProfile(
            id = "us",
            nameEn = "United States of America",
            nameAm = "አሜሪካ",
            capitalEn = "Washington D.C.",
            flag = "🇺🇸",
            region = "North America",
            timeZoneId = "America/New_York",
            timeZoneName = "EST (UTC-5) / EDT (UTC-4 in Summer)",
            dialCode = "+1",
            currencyName = "US Dollar",
            currencySymbol = "USD ($)",
            dateFormatExample = "MM/DD/YYYY (e.g. 11/14/2026)",
            workweek = "Monday – Friday (40 hrs). Saturday & Sunday weekend.",
            businessHours = "09:00 – 17:00 EST",
            callingRecommendationFromAddis = "04:00 PM – 10:00 PM Addis Ababa time (corresponds to 09:00 AM – 03:00 PM US Eastern Time).",
            holidayDifferences = "Thanksgiving (4th Thursday of November), 4th of July, Memorial Day, Labor Day. Home to the largest Ethiopian diaspora globally (DC, California, Texas, Atlanta).",
            seasonDifference = "US fiscal year runs Oct 1 – Sep 30. Wide range of climate zones."
        ),
        CountryProfile(
            id = "ca",
            nameEn = "Canada",
            nameAm = "ካናዳ",
            capitalEn = "Ottawa",
            flag = "🇨🇦",
            region = "North America",
            timeZoneId = "America/Toronto",
            timeZoneName = "EST (UTC-5) / EDT (UTC-4 in Summer)",
            dialCode = "+1",
            currencyName = "Canadian Dollar",
            currencySymbol = "CAD ($)",
            dateFormatExample = "YYYY-MM-DD or DD/MM/YYYY",
            workweek = "Monday – Friday. Saturday & Sunday weekend.",
            businessHours = "09:00 – 17:00 EST",
            callingRecommendationFromAddis = "04:00 PM – 10:00 PM Addis Ababa time.",
            holidayDifferences = "Canada Day (July 1), Victoria Day (May), Thanksgiving (2nd Monday of October). Large Ethiopian communities in Toronto, Calgary, Edmonton, Ottawa.",
            seasonDifference = "Severe continental winter contrasted with temperate summer."
        ),
        CountryProfile(
            id = "ae",
            nameEn = "United Arab Emirates",
            nameAm = "የተባበሩት አረብ ኤምሬቶች (ዱባይ)",
            capitalEn = "Abu Dhabi",
            flag = "🇦🇪",
            region = "Middle East / Gulf",
            timeZoneId = "Asia/Dubai",
            timeZoneName = "GST (UTC+4 all year - No DST)",
            dialCode = "+971",
            currencyName = "UAE Dirham",
            currencySymbol = "AED (د.إ)",
            dateFormatExample = "DD/MM/YYYY",
            workweek = "Monday – Thursday (full day) + Friday half day (since 2022). Saturday & Sunday weekend.",
            businessHours = "08:00 – 17:00 GST",
            callingRecommendationFromAddis = "09:00 AM – 04:00 PM Addis Ababa time (UAE is only 1 hour ahead of Ethiopia).",
            holidayDifferences = "Islamic holidays (Eid al-Fitr, Eid al-Adha, Islamic New Year, Prophet's Birthday) and National Day (Dec 2). Highly popular business and travel corridor with Addis Ababa.",
            seasonDifference = "Hot desert climate. Ethiopia is 1 hour behind Dubai all year with no daylight saving shifts."
        ),
        CountryProfile(
            id = "sa",
            nameEn = "Saudi Arabia",
            nameAm = "ሳውዲ አረቢያ",
            capitalEn = "Riyadh",
            flag = "🇸🇦",
            region = "Middle East",
            timeZoneId = "Asia/Riyadh",
            timeZoneName = "AST (UTC+3 all year - Same as Ethiopia!)",
            dialCode = "+966",
            currencyName = "Saudi Riyal",
            currencySymbol = "SAR (﷼)",
            dateFormatExample = "DD/MM/YYYY + Umm al-Qura Hijri",
            workweek = "Sunday – Thursday. Friday & Saturday weekend.",
            businessHours = "08:00 – 16:30 AST",
            callingRecommendationFromAddis = "Exact same time as Addis Ababa (0 hours time difference)! Working hours 09:00 AM – 04:00 PM Sunday through Thursday.",
            holidayDifferences = "Official calendar uses Umm al-Qura Hijri lunar system alongside Gregorian. Major breaks on Eid al-Fitr and Hajj season.",
            seasonDifference = "Direct geographical neighbor across the Red Sea; identical standard time (UTC+3)."
        ),
        CountryProfile(
            id = "eg",
            nameEn = "Egypt (Coptic & Arab Republic)",
            nameAm = "ግብፅ",
            capitalEn = "Cairo",
            flag = "🇪🇬",
            region = "North Africa",
            timeZoneId = "Africa/Cairo",
            timeZoneName = "EET (UTC+2) / EEST (UTC+3 in Summer)",
            dialCode = "+20",
            currencyName = "Egyptian Pound",
            currencySymbol = "EGP (E£)",
            dateFormatExample = "DD/MM/YYYY",
            workweek = "Sunday – Thursday. Friday & Saturday weekend.",
            businessHours = "09:00 – 16:00 EET",
            callingRecommendationFromAddis = "10:00 AM – 04:00 PM Addis Ababa time.",
            holidayDifferences = "Coptic Christmas (Jan 7, matches Ethiopian Genna), Sham Ennessim (Easter Monday). Historic sister church of Alexandria with matching 13-month Coptic calendar.",
            seasonDifference = "Shares the ancient Nile basin connection; 1 hour behind Addis Ababa in winter, identical time during Egypt summer DST."
        ),
        CountryProfile(
            id = "au",
            nameEn = "Australia",
            nameAm = "አውስትራሊያ",
            capitalEn = "Canberra",
            flag = "🇦🇺",
            region = "Oceania",
            timeZoneId = "Australia/Sydney",
            timeZoneName = "AEST (UTC+10) / AEDT (UTC+11 in Summer)",
            dialCode = "+61",
            currencyName = "Australian Dollar",
            currencySymbol = "AUD ($)",
            dateFormatExample = "DD/MM/YYYY",
            workweek = "Monday – Friday. Saturday & Sunday weekend.",
            businessHours = "09:00 – 17:00 AEST",
            callingRecommendationFromAddis = "07:00 AM – 11:00 AM Addis Ababa time (corresponds to 02:00 PM – 06:00 PM in Sydney).",
            holidayDifferences = "Australia Day (Jan 26), ANZAC Day (Apr 25). Financial year runs July 1 – June 30.",
            seasonDifference = "Southern hemisphere: seasons are reversed! When it is winter in Europe/North America, it is summer in Australia."
        )
    )

    /**
     * Converts a given Addis Ababa Standard Time (UTC+3) to all target world & European cities.
     * Note: Traditional Ethiopian daytime 12:00 = 06:00 AM Addis Ababa.
     */
    fun convertAddisAbabaTimeToWorldCities(
        addisHour24: Int,
        addisMinute: Int,
        referenceYear: Int = 2026,
        referenceMonth: Int = 10,
        referenceDay: Int = 20
    ): List<WorldCityTimeResult> {
        val addisCal = Calendar.getInstance(TimeZone.getTimeZone("GMT+3")).apply {
            set(Calendar.YEAR, referenceYear)
            set(Calendar.MONTH, referenceMonth - 1)
            set(Calendar.DAY_OF_MONTH, referenceDay)
            set(Calendar.HOUR_OF_DAY, addisHour24)
            set(Calendar.MINUTE, addisMinute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val utcMillis = addisCal.timeInMillis

        return WORLD_CITIES.map { city ->
            val targetTz = TimeZone.getTimeZone(city.timeZoneId)
            val targetCal = Calendar.getInstance(targetTz).apply {
                timeInMillis = utcMillis
            }

            val tHour24 = targetCal.get(Calendar.HOUR_OF_DAY)
            val tMinute = targetCal.get(Calendar.MINUTE)
            val tHour12 = when (val h = tHour24 % 12) {
                0 -> 12
                else -> h
            }
            val isPm = tHour24 >= 12

            // Day offset relative to Addis Ababa day
            val dayDiff = targetCal.get(Calendar.DAY_OF_YEAR) - addisCal.get(Calendar.DAY_OF_YEAR)
            val normalizedDayOffset = when {
                dayDiff > 0 -> 1
                dayDiff < 0 -> -1
                else -> 0
            }

            // Raw offset in hours
            val rawOffsetHours = targetTz.getOffset(utcMillis) / 3600000.0
            val addisOffsetHours = 3.0 // UTC+3
            val diffFromAddis = rawOffsetHours - addisOffsetHours

            // Business status
            val status = when (tHour24) {
                in 9..17 -> BusinessStatus.OPEN
                in 7..8, in 18..21 -> BusinessStatus.LEISURE
                else -> BusinessStatus.SLEEPING
            }

            val tzAbbr = targetTz.getDisplayName(targetTz.inDaylightTime(targetCal.time), TimeZone.SHORT)
            val f12 = String.format(Locale.US, "%d:%02d %s", tHour12, tMinute, if (isPm) "PM" else "AM")
            val f24 = String.format(Locale.US, "%02d:%02d", tHour24, tMinute)

            WorldCityTimeResult(
                city = city,
                hour24 = tHour24,
                minute = tMinute,
                hour12 = tHour12,
                isPm = isPm,
                timeZoneAbbreviation = tzAbbr,
                rawOffsetHours = rawOffsetHours,
                differenceFromAddisHours = diffFromAddis,
                dayOffset = normalizedDayOffset,
                businessStatus = status,
                formattedTime12 = f12,
                formattedTime24 = f24
            )
        }
    }

    /**
     * Converts a specific European/World city time back to Addis Ababa standard time (UTC+3)
     * and Traditional Ethiopian time.
     */
    fun convertWorldCityTimeToAddisAbaba(
        cityId: String,
        hour24: Int,
        minute: Int,
        referenceYear: Int = 2026,
        referenceMonth: Int = 10,
        referenceDay: Int = 20
    ): Pair<Int, Int> { // Returns Addis Ababa (hour24, minute)
        val city = WORLD_CITIES.firstOrNull { it.id == cityId } ?: WORLD_CITIES[0]
        val sourceTz = TimeZone.getTimeZone(city.timeZoneId)
        val sourceCal = Calendar.getInstance(sourceTz).apply {
            set(Calendar.YEAR, referenceYear)
            set(Calendar.MONTH, referenceMonth - 1)
            set(Calendar.DAY_OF_MONTH, referenceDay)
            set(Calendar.HOUR_OF_DAY, hour24)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val utcMillis = sourceCal.timeInMillis

        val addisCal = Calendar.getInstance(TimeZone.getTimeZone("GMT+3")).apply {
            timeInMillis = utcMillis
        }
        return Pair(addisCal.get(Calendar.HOUR_OF_DAY), addisCal.get(Calendar.MINUTE))
    }

    /**
     * Computes comprehensive European & multi-calendar metadata from an Ethiopian Date
     * and its corresponding Gregorian Date.
     */
    fun computeEuropeanAndWorldCalendarDetails(
        ethiopianDate: EthiopianDate,
        gregorianDate: GregorianDate,
        jdn: Long
    ): EuropeanCalendarResult {
        val gYear = gregorianDate.year
        val gMonth = gregorianDate.month
        val gDay = gregorianDate.day

        // 1. European & World Formats
        val gregFormattedEu = String.format(Locale.US, "%02d.%02d.%04d", gDay, gMonth, gYear)
        val gregFormattedUk = String.format(Locale.US, "%02d/%02d/%04d", gDay, gMonth, gYear)
        val monthNamesDe = listOf("Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember")
        val deMonth = monthNamesDe.getOrElse(gMonth - 1) { "" }
        val gregFormattedDe = "$gDay. $deMonth $gYear"
        val gregFormattedFr = String.format(Locale.US, "%02d/%02d/%04d", gDay, gMonth, gYear)
        val gregFormattedUs = String.format(Locale.US, "%02d/%02d/%04d", gMonth, gDay, gYear)
        val iso8601 = String.format(Locale.US, "%04d-%02d-%02d", gYear, gMonth, gDay)

        // 2. Julian Calendar Calculation (Old Style / Orthodox Europe)
        // Astronomical algorithm to convert JDN to Julian Calendar:
        val c = jdn + 32082L
        val d = (4L * c + 3L) / 1461L
        val e = c - (1461L * d) / 4L
        val m = (5L * e + 2L) / 153L
        val julDay = (e - (153L * m + 2L) / 5L + 1L).toInt()
        val julMonth = (m + 3L - 12L * (m / 10L)).toInt()
        val julYear = (d - 4800L + m / 10L).toInt()
        val julianDateStr = String.format(Locale.US, "%02d/%02d/%04d (Old Style / 13 days behind GC)", julDay, julMonth, julYear)

        // 3. Coptic Calendar Calculation (Alexandria / Egypt)
        // Coptic Era of Martyrs started Aug 29, 284 AD (JDN 1825030)
        // Ethiopian Era started Aug 29, 8 AD (JDN 1723856)
        // Year offset between Ethiopian and Coptic is exactly 276 years.
        val copticYear = ethiopianDate.year - 276
        val copticDay = ethiopianDate.day
        val copticMonthsEn = listOf(
            "Thout (ቶት)", "Paopi (ባባ)", "Hathor (ሀቱር)", "Koiak (ኪያክ)",
            "Tobi (ጡባ)", "Meshir (አምሺር)", "Paremhat (በረምሃት)", "Parmouti (በረሙዳ)",
            "Pashons (በሽንስ)", "Paoni (በአውና)", "Epip (አቢብ)", "Mesori (መስራ)",
            "Pi Kogi Enavot / Nasie (ናሲ)"
        )
        val copticMonthName = copticMonthsEn.getOrElse(ethiopianDate.month - 1) { "Month ${ethiopianDate.month}" }
        val copticDateStr = "$copticDay $copticMonthName $copticYear A.M."

        // 4. Islamic / Hijri Calendar Estimation
        val days = jdn - 1948440L + 10632L
        val cycle = days / 10631L
        val rem = days % 10631L
        val hYear = (cycle * 30L + (rem * 30L + 14L) / 10631L - 29L).toInt()
        val dayInYear = (jdn - (1948439L + (hYear - 1) * 354L + ((3 + 11 * hYear) / 30))).toInt()
        val hMonth = kotlin.math.min(12, ((dayInYear - 1) / 29.5).toInt() + 1)
        val monthDays = kotlin.math.ceil(29.5 * (hMonth - 1)).toInt()
        val hDay = (dayInYear - monthDays).coerceIn(1, 30)
        val hijriMonths = listOf("Muharram", "Safar", "Rabi' I", "Rabi' II", "Jumada I", "Jumada II", "Rajab", "Sha'ban", "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah")
        val hijriDateStr = "$hDay ${hijriMonths.getOrElse(hMonth - 1) { "" }} $hYear AH"

        // 5. European Astronomical Season
        val (seasonEn, seasonAm, seasonEmoji) = when {
            (gMonth == 3 && gDay >= 20) || gMonth in 4..5 || (gMonth == 6 && gDay < 21) ->
                Triple("Spring (Frühling / Printemps)", "ፀደይ (የአውሮፓ)", "🌸")
            (gMonth == 6 && gDay >= 21) || gMonth in 7..8 || (gMonth == 9 && gDay < 23) ->
                Triple("Summer (Sommer / Été)", "በጋ (የአውሮፓ)", "☀️")
            (gMonth == 9 && gDay >= 23) || gMonth in 10..11 || (gMonth == 12 && gDay < 22) ->
                Triple("Autumn (Herbst / Automne)", "መኸር (የአውሮፓ)", "🍂")
            else ->
                Triple("Winter (Winter / Hiver)", "ክረምት / በረዶ (የአውሮፓ)", "❄️")
        }

        // 6. European Quarter & Calendar Day of Year
        val quarter = when (gMonth) {
            in 1..3 -> "Q1 (Jan–Mar)"
            in 4..6 -> "Q2 (Apr–Jun)"
            in 7..9 -> "Q3 (Jul–Sep)"
            else -> "Q4 (Oct–Dec)"
        }

        val gCal = Calendar.getInstance().apply {
            set(Calendar.YEAR, gYear)
            set(Calendar.MONTH, gMonth - 1)
            set(Calendar.DAY_OF_MONTH, gDay)
        }
        val dayOfYear = gCal.get(Calendar.DAY_OF_YEAR)
        val weekOfYear = gCal.get(Calendar.WEEK_OF_YEAR)
        val dayOfWeek = gCal.get(Calendar.DAY_OF_WEEK) // 1 = Sunday, 7 = Saturday

        val isEuWeekend = dayOfWeek == Calendar.SATURDAY || dayOfWeek == Calendar.SUNDAY
        val isEthWeekend = dayOfWeek == Calendar.SUNDAY // Ethiopian civil government has Saturday off/half-day, Sunday is national rest day

        // 7. Explanatory Year Offset
        val yearDiff = gYear - ethiopianDate.year
        val yearOffsetExplanation = if (yearDiff == 7) {
            "Between Sep 11 and Dec 31, the European/Gregorian calendar is exactly 7 years ahead of the Ethiopian Calendar ($gYear - ${ethiopianDate.year} = 7 years gap)."
        } else {
            "Between Jan 1 and Sep 10, the European/Gregorian calendar is exactly 8 years ahead of the Ethiopian Calendar ($gYear - ${ethiopianDate.year} = 8 years gap)."
        }

        return EuropeanCalendarResult(
            gregorianFormattedEu = gregFormattedEu,
            gregorianFormattedUk = gregFormattedUk,
            gregorianFormattedDe = gregFormattedDe,
            gregorianFormattedFr = gregFormattedFr,
            gregorianFormattedUs = gregFormattedUs,
            iso8601 = iso8601,
            julianDateStr = julianDateStr,
            julianYear = julYear,
            julianMonth = julMonth,
            julianDay = julDay,
            copticDateStr = copticDateStr,
            copticYear = copticYear,
            copticMonthName = copticMonthName,
            copticDay = copticDay,
            hijriDateStr = hijriDateStr,
            europeanSeasonEn = seasonEn,
            europeanSeasonAm = seasonAm,
            europeanSeasonEmoji = seasonEmoji,
            europeanQuarter = quarter,
            dayOfYear = dayOfYear,
            weekOfYear = weekOfYear,
            isEuropeanWeekend = isEuWeekend,
            isEthiopianWeekend = isEthWeekend,
            yearOffsetExplanation = yearOffsetExplanation
        )
    }
}
