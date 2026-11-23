package com.example.calendar.localization

object LocaleStrings {

    val ETHIOPIAN_MONTHS_AMHARIC = listOf(
        "መስከረም", "ጥቅምት", "ኅዳር", "ታኅሣሥ", "ጥር", "የካቲት",
        "መጋቢት", "ሚያዝያ", "ግንቦት", "ሰኔ", "ሐምሌ", "ነሐሴ", "ጳጉሜ"
    )

    val ETHIOPIAN_MONTHS_ENGLISH = listOf(
        "Meskerem", "Tikimt", "Hidar", "Tahsas", "Tir", "Yakatit",
        "Megabit", "Miazia", "Ginbot", "Sene", "Hamle", "Nehase", "Pagume"
    )

    val ETHIOPIAN_MONTHS_OROMO = listOf(
        "Fulbaana", "Onkololeessa", "Sadaasa", "Muddee", "Amajjii", "Guraandhala",
        "Bitooteessa", "Ebla", "Caamsaa", "Waxabajjii", "Adooleessa", "Hagayya", "Qaammee"
    )

    val ETHIOPIAN_MONTHS_TIGRINYA = listOf(
        "መስከረም", "ጥቅምቲ", "ሕዳር", "ታሕሳስ", "ጥሪ", "የካቲት",
        "መጋቢት", "ሚያዝያ", "ግንቦት", "ሰነ", "ሓምለ", "ነሓሰ", "ጳጉሜን"
    )

    val ETHIOPIAN_MONTHS_FRENCH = listOf(
        "Meskerem", "Tikimt", "Hidar", "Tahsas", "Tir", "Yakatit",
        "Megabit", "Miazia", "Ginbot", "Sene", "Hamle", "Nehase", "Pagoumé"
    )

    fun getMonthName(monthIndex: Int, language: AppLanguage): String {
        val idx = (monthIndex - 1).coerceIn(0, 12)
        return when (language) {
            AppLanguage.AMHARIC -> ETHIOPIAN_MONTHS_AMHARIC[idx]
            AppLanguage.ENGLISH -> ETHIOPIAN_MONTHS_ENGLISH[idx]
            AppLanguage.OROMO -> ETHIOPIAN_MONTHS_OROMO[idx]
            AppLanguage.TIGRINYA -> ETHIOPIAN_MONTHS_TIGRINYA[idx]
            AppLanguage.FRENCH -> ETHIOPIAN_MONTHS_FRENCH[idx]
        }
    }

    // Days of week: 1 = Monday .. 7 = Sunday
    val WEEKDAYS_AMHARIC_SHORT = listOf("ሰኞ", "ማክ", "ረቡ", "ሐሙ", "ዓር", "ቅዳ", "እሑ")
    val WEEKDAYS_AMHARIC_LONG = listOf("ሰኞ", "ማክሰኞ", "ረቡዕ", "ሐሙስ", "ዓርብ", "ቅዳሜ", "እሑድ")

    val WEEKDAYS_ENGLISH_SHORT = listOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
    val WEEKDAYS_ENGLISH_LONG = listOf("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")

    val WEEKDAYS_OROMO_SHORT = listOf("Wix", "Kib", "Rob", "Kam", "Jim", "San", "Dil")
    val WEEKDAYS_OROMO_LONG = listOf("Wiixata", "Kibxata", "Roobii", "Kamiisa", "Jimaata", "Sanbata", "Dilbata")

    val WEEKDAYS_TIGRINYA_SHORT = listOf("ሰኑ", "ሰሉ", "ረቡ", "ሓሙ", "ዓር", "ቀዳ", "ሰን")
    val WEEKDAYS_TIGRINYA_LONG = listOf("ሰኑይ", "ሰሉስ", "ረቡዕ", "ሓሙስ", "ዓርቢ", "ቀዳም", "ሰንበት")

    val WEEKDAYS_FRENCH_SHORT = listOf("Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim")
    val WEEKDAYS_FRENCH_LONG = listOf("Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche")

    fun getWeekdayShort(dayOfWeek: Int, language: AppLanguage): String {
        val idx = (dayOfWeek - 1).coerceIn(0, 6)
        return when (language) {
            AppLanguage.AMHARIC -> WEEKDAYS_AMHARIC_SHORT[idx]
            AppLanguage.ENGLISH -> WEEKDAYS_ENGLISH_SHORT[idx]
            AppLanguage.OROMO -> WEEKDAYS_OROMO_SHORT[idx]
            AppLanguage.TIGRINYA -> WEEKDAYS_TIGRINYA_SHORT[idx]
            AppLanguage.FRENCH -> WEEKDAYS_FRENCH_SHORT[idx]
        }
    }

    fun getWeekdayLong(dayOfWeek: Int, language: AppLanguage): String {
        val idx = (dayOfWeek - 1).coerceIn(0, 6)
        return when (language) {
            AppLanguage.AMHARIC -> WEEKDAYS_AMHARIC_LONG[idx]
            AppLanguage.ENGLISH -> WEEKDAYS_ENGLISH_LONG[idx]
            AppLanguage.OROMO -> WEEKDAYS_OROMO_LONG[idx]
            AppLanguage.TIGRINYA -> WEEKDAYS_TIGRINYA_LONG[idx]
            AppLanguage.FRENCH -> WEEKDAYS_FRENCH_LONG[idx]
        }
    }

    // UI Translation Strings
    fun get(key: String, language: AppLanguage): String {
        val map = when (language) {
            AppLanguage.AMHARIC -> AMHARIC_MAP
            AppLanguage.OROMO -> OROMO_MAP
            AppLanguage.TIGRINYA -> TIGRINYA_MAP
            AppLanguage.FRENCH -> FRENCH_MAP
            AppLanguage.ENGLISH -> ENGLISH_MAP
        }
        return map[key] ?: ENGLISH_MAP[key] ?: key
    }

    private val ENGLISH_MAP = mapOf(
        "nav_home" to "Home",
        "nav_calendar" to "Calendar",
        "nav_converter" to "Converter",
        "nav_holidays" to "Holidays",
        "nav_events" to "Events",
        "nav_more" to "More",
        "today" to "Today",
        "ethiopian_date" to "Ethiopian Date",
        "gregorian_date" to "Gregorian Date",
        "upcoming_holidays" to "Upcoming Holidays",
        "view_all" to "View All",
        "fasting_today" to "Fasting Status",
        "daily_observance" to "Daily Observance",
        "quick_actions" to "Quick Actions",
        "add_event" to "Add Event",
        "convert_date" to "Convert Date",
        "traditional_time" to "Ethiopian Time",
        "bahire_hasab" to "Bahire Hasab",
        "age_calculator" to "Age & Difference",
        "share_card" to "Share Greeting",
        "month_view" to "Month",
        "week_view" to "Week",
        "year_view" to "Year",
        "day_view" to "Day",
        "no_events_today" to "No events scheduled for today",
        "countdown" to "Countdown",
        "days_left" to "days left",
        "public_holiday" to "Public Holiday",
        "orthodox_feast" to "Orthodox Observance",
        "islamic_holiday" to "Islamic Holiday",
        "cultural_celebration" to "Cultural Celebration",
        "search_events" to "Search events...",
        "settings" to "Settings",
        "language" to "Language",
        "numeral_format" to "Numerals",
        "theme" to "Theme",
        "color_accent" to "Accent Color",
        "backup_restore" to "Backup & ICS",
        "about" to "About EthioCal Pro"
    )

    private val AMHARIC_MAP = mapOf(
        "nav_home" to "ዋና ገጽ",
        "nav_calendar" to "ቀን መቁጠሪያ",
        "nav_converter" to "ቀን ቀያሪ",
        "nav_holidays" to "በዓላት",
        "nav_events" to "ማስታወሻዎች",
        "nav_more" to "ተጨማሪ",
        "today" to "ዛሬ",
        "ethiopian_date" to "የኢትዮጵያ ቀን",
        "gregorian_date" to "የፈረንጆች ቀን",
        "upcoming_holidays" to "ቀጣይ በዓላት",
        "view_all" to "ሁሉንም እይ",
        "fasting_today" to "የዛሬ የጾም ሁኔታ",
        "daily_observance" to "የዕለቱ ታሳቢ (ጽላት)",
        "quick_actions" to "ፈጣን ድርጊቶች",
        "add_event" to "ማስታወሻ መዝግብ",
        "convert_date" to "ቀን ቀይር",
        "traditional_time" to "የኢትዮጵያ ሰዓት",
        "bahire_hasab" to "ባሕረ ሐሳብ",
        "age_calculator" to "ዕድሜ እና ልዩነት",
        "share_card" to "የበዓል ካርድ አጋራ",
        "month_view" to "ወር",
        "week_view" to "ሳምንት",
        "year_view" to "ዓመት",
        "day_view" to "ቀን",
        "no_events_today" to "ለዛሬ የተመዘገበ ክስተት የለም",
        "countdown" to "ቀሪ ቀናት",
        "days_left" to "ቀናት ቀርተዋል",
        "public_holiday" to "የሕዝብ በዓል",
        "orthodox_feast" to "የኦርቶዶክስ ተዋሕዶ በዓል",
        "islamic_holiday" to "የእስልምና በዓል",
        "cultural_celebration" to "ባህላዊ ክብረ በዓል",
        "search_events" to "ማስታወሻ ፈልግ...",
        "settings" to "ቅንብሮች",
        "language" to "ቋንቋ",
        "numeral_format" to "የቁጥሮች አጻጻፍ",
        "theme" to "ገጽታ",
        "color_accent" to "የቀለም ቅንብር",
        "backup_restore" to "ምትኬ እና ICS ማጋሪያ",
        "about" to "ስለ ኢትዮካል ፕሮ"
    )

    private val OROMO_MAP = mapOf(
        "nav_home" to "Fuula Duraa",
        "nav_calendar" to "Dhaha",
        "nav_converter" to "Jijjiirraa Guyyaa",
        "nav_holidays" to "Ayyaanota",
        "nav_events" to "Sagantaalee",
        "nav_more" to "Dabalata",
        "today" to "Har'a",
        "ethiopian_date" to "Guyyaa Itoophiyaa",
        "gregorian_date" to "Guyyaa Faranjii",
        "upcoming_holidays" to "Ayyaanota Dhufan",
        "view_all" to "Hunda Ilaali",
        "fasting_today" to "Haala Soomaa",
        "daily_observance" to "Kabaja Guyyaa",
        "quick_actions" to "Tarkaanfii Daddafaa",
        "add_event" to "Sagantaa Galchi",
        "convert_date" to "Guyyaa Jijjiiri",
        "traditional_time" to "Sa'aatii Itoophiyaa",
        "bahire_hasab" to "Baahira Hasaab",
        "age_calculator" to "Umrii fi Garaagarummaa",
        "share_card" to "Kaardii Hiri",
        "month_view" to "Ji'a",
        "week_view" to "Torban",
        "year_view" to "Bara",
        "day_view" to "Guyyaa",
        "no_events_today" to "Sagantaan har'aa hin jiru",
        "countdown" to "Guyyoota Hafan",
        "days_left" to "guyyoota hafan",
        "public_holiday" to "Ayyaana Ummataa",
        "orthodox_feast" to "Ayyaana Ortodoksii",
        "islamic_holiday" to "Ayyaana Islaamaa",
        "cultural_celebration" to "Ayyaana Aadaa",
        "search_events" to "Sagantaa Barbaadi...",
        "settings" to "Qindaa'ina",
        "language" to "Afaan",
        "numeral_format" to "Lakkoofsota",
        "theme" to "Bifa Mul'ataa",
        "color_accent" to "Halluu",
        "backup_restore" to "ICS fi Baakapii",
        "about" to "Waa'ee EthioCal Pro"
    )

    private val TIGRINYA_MAP = mapOf(
        "nav_home" to "መበገሲ",
        "nav_calendar" to "ዓውደ ኣዋርሕ",
        "nav_converter" to "ቀያሪ ዕለት",
        "nav_holidays" to "በዓላት",
        "nav_events" to "መዘከርታታት",
        "nav_more" to "ተወሳኺ",
        "today" to "ሎሚ",
        "ethiopian_date" to "ዕለት ኢትዮጵያ",
        "gregorian_date" to "ዕለት ፈረንጂ",
        "upcoming_holidays" to "ዝመጹ በዓላት",
        "view_all" to "ኩሉ ርአ",
        "fasting_today" to "ኩነታት ጾም",
        "daily_observance" to "ጽላት ናይ ሎሚ",
        "quick_actions" to "ቅልጡፍ ስጉምትታት",
        "add_event" to "መዘከርታ ኣእቱ",
        "convert_date" to "ዕለት ቀይር",
        "traditional_time" to "ሰዓት ኢትዮጵያ",
        "bahire_hasab" to "ባሕረ ሓሳብ",
        "age_calculator" to "ዕድመን ፍልልይን",
        "share_card" to "ካርድ ኣካፍል",
        "month_view" to "ወርሒ",
        "week_view" to "ሰሙን",
        "year_view" to "ዓመት",
        "day_view" to "መዓልቲ",
        "no_events_today" to "ናይ ሎሚ መደብ የለን",
        "countdown" to "ዝተረፈ መዓልታት",
        "days_left" to "መዓልታት ተሪፎም",
        "public_holiday" to "ናይ ህዝቢ በዓል",
        "orthodox_feast" to "በዓል ኦርቶዶክስ",
        "islamic_holiday" to "በዓል እስልምና",
        "cultural_celebration" to "ባህላዊ በዓል",
        "search_events" to "መዘከርታታት ድለ...",
        "settings" to "ቅጥዕታት",
        "language" to "ቋንቋ",
        "numeral_format" to "ኣገባብ ኣሃዛት",
        "theme" to "ገጽታ",
        "color_accent" to "ሕብሪ",
        "backup_restore" to "ምትካልን ICSን",
        "about" to "ብዛዕባ EthioCal Pro"
    )

    private val FRENCH_MAP = mapOf(
        "nav_home" to "Accueil",
        "nav_calendar" to "Calendrier",
        "nav_converter" to "Convertisseur",
        "nav_holidays" to "Fêtes",
        "nav_events" to "Événements",
        "nav_more" to "Plus",
        "today" to "Aujourd'hui",
        "ethiopian_date" to "Date Éthiopienne",
        "gregorian_date" to "Date Grégorienne",
        "upcoming_holidays" to "Fêtes à venir",
        "view_all" to "Voir tout",
        "fasting_today" to "Statut du Jeûne",
        "daily_observance" to "Commémoration",
        "quick_actions" to "Actions rapides",
        "add_event" to "Ajouter un événement",
        "convert_date" to "Convertir une date",
        "traditional_time" to "Heure Éthiopienne",
        "bahire_hasab" to "Bahire Hasab",
        "age_calculator" to "Âge & Différence",
        "share_card" to "Partager une carte",
        "month_view" to "Mois",
        "week_view" to "Semaine",
        "year_view" to "Année",
        "day_view" to "Jour",
        "no_events_today" to "Aucun événement pour aujourd'hui",
        "countdown" to "Compte à rebours",
        "days_left" to "jours restants",
        "public_holiday" to "Jour Férié",
        "orthodox_feast" to "Fête Orthodoxe",
        "islamic_holiday" to "Fête Islamique",
        "cultural_celebration" to "Fête Culturelle",
        "search_events" to "Rechercher...",
        "settings" to "Paramètres",
        "language" to "Langue",
        "numeral_format" to "Chiffres",
        "theme" to "Thème",
        "color_accent" to "Couleur d'accent",
        "backup_restore" to "Sauvegarde & ICS",
        "about" to "À propos de EthioCal Pro"
    )
}
