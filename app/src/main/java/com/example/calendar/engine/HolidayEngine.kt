package com.example.calendar.engine

/**
 * Complete holiday, religious observances, Islamic celebrations,
 * cultural events, monthly saints' days, and fasting status engine.
 */
object HolidayEngine {

    enum class HolidayType {
        NATIONAL_PUBLIC,
        ORTHODOX_MAJOR,
        ORTHODOX_MOVABLE,
        ORTHODOX_FASTING,
        ISLAMIC,
        CULTURAL_REGIONAL,
        MONTHLY_SAINT
    }

    data class Holiday(
        val id: String,
        val titleAmharic: String,
        val titleEnglish: String,
        val titleOromo: String,
        val titleTigrinya: String,
        val ethiopianDate: EthiopianDate,
        val type: HolidayType,
        val description: String,
        val isPublicHoliday: Boolean = false,
        val isFasting: Boolean = false
    )

    data class MonthlySaintDay(
        val day: Int,
        val nameAmharic: String,
        val nameEnglish: String,
        val nameOromo: String,
        val nameTigrinya: String,
        val significance: String
    )

    data class CanonicalFast(
        val id: String,
        val nameAmharic: String,
        val nameEnglish: String,
        val nameOromo: String,
        val nameTigrinya: String,
        val durationDays: Int,
        val startDate: EthiopianDate,
        val endDate: EthiopianDate,
        val significance: String,
        val dietaryRules: String,
        val biblicalFoundation: String
    )

    data class DetailedFastingInfo(
        val isFasting: Boolean,
        val seasonNameAmharic: String,
        val seasonNameEnglish: String,
        val fastingLevel: String, // "Strict Fasting until 3 PM (Vegan)", "Fifty Days of Joy (No Fast)", etc.
        val description: String
    )

    val MONTHLY_SAINTS = listOf(
        MonthlySaintDay(1, "ልደታ ለማርያም እና ኤልያስ", "Lideta & Elias", "Lidataa fi Eeliyaas", "ልደታን ኤልያስን", "Birth of Virgin Mary and Prophet Elijah"),
        MonthlySaintDay(2, "ታዴዎስ ሐዋርያ", "Thaddaeus the Apostle", "Taadewoos Ergamaa", "ታዴዎስ ሃዋርያ", "Commemoration of Apostle St. Jude Thaddaeus"),
        MonthlySaintDay(3, "በዓታ ለማርያም", "Ba'eta leMaryam", "Ba'ataa Maariyaam", "በዓታ ለማርያም", "Entry of the Virgin Mary into the Temple"),
        MonthlySaintDay(4, "ዮሐንስ ወልደ ነጎድጓድ", "St. John the Evangelist", "Yohaannis Ilma Qaqawweessaa", "ዮሃንስ ወልደ ነጎድጓድ", "Apostle John the Theologian, beloved disciple of Christ"),
        MonthlySaintDay(5, "አቡነ ገብረ መንፈስ ቅዱስ (አቦ)", "Abune Gebre Menfes Kidus (Abo)", "Abbaa Gabra Manfas Qulqulluu", "አቡነ ገብረ መንፈስ ቅዱስ", "Desert Monk & Hermit of Mount Ziquala"),
        MonthlySaintDay(6, "ቁስቋም ማርያም እና ኢየሱስ", "Qusqwam Maryam", "Maariyaam Qusquwaam", "ቁስቋም ማርያም", "Holy Family's exile and refuge in Mount Qusqwam, Egypt"),
        MonthlySaintDay(7, "ቅድስት ሥላሴ", "Holy Trinity (Selassie)", "Sillaasee Qulqulluu", "ቅድስት ሥላሴ", "Solemnity of the Holy Trinity: Father, Son, and Holy Spirit"),
        MonthlySaintDay(8, "አባ ኪሮስ እና ዮሐንስ አፈወርቅ", "Abba Kiros & John Chrysostom", "Abbaa Kiroos", "ኣባ ኪሮስ", "St. Kiros the Ascetic and St. John Chrysostom Golden-mouthed"),
        MonthlySaintDay(9, "ሠለስቱ ምዕት (318ቱ አባቶች)", "318 Church Fathers of Nicaea", "Abbootii 318 Niiqiyaa", "ሰለስቱ ምእት", "Defenders of orthodox doctrine at the First Council of Nicaea"),
        MonthlySaintDay(10, "መስቀለ ክርስቶስ", "Feast of the Holy Cross", "Fannoo Masqalaa", "መስቀለ ክርስቶስ", "Commemoration of the Cross of Salvation"),
        MonthlySaintDay(11, "ሐና እና ኢያቄም", "St. Anne & St. Joachim", "Haannaa fi Iyaaqeem", "ሃናን ኢያቄምን", "Righteous parents of the Blessed Virgin Mary"),
        MonthlySaintDay(12, "ቅዱስ ሚካኤል ሊቀ መላእክት", "Archangel Michael", "Qulqulluu Mikaa'el", "ቅዱስ ሚካኤል", "Feast of Archangel Michael, protector and defender of God's people"),
        MonthlySaintDay(13, "እግዚአብሔር አብ እና ሩፋኤል", "God the Father & Raphael", "Waaqayyo Abbaa fi Rufaa'eel", "እግዚአብሔር ኣብ", "Providence of God the Father & Archangel Raphael the Healer"),
        MonthlySaintDay(14, "አባ አረጋዊ እና ገብረ ክርስቶስ", "Abba Aregawi & Gebre Kristos", "Abbaa Aragawwii", "ኣባ ኣረጋዊ", "Leader of the Nine Saints, founder of Debre Damo monastery"),
        MonthlySaintDay(15, "ቅዱስ ቂርቆስ እና ኢየሉጣ", "St. Cyricus & Julitta", "Qulqulluu Qirqoos", "ቅዱስ ቂርቆስ", "Holy Child Martyr Quiricus and his mother Julitta"),
        MonthlySaintDay(16, "ኪዳነ ምሕረት", "Kidane Mihret (Covenant of Mercy)", "Kidaana Mihrat", "ኪዳነ ምሕረት", "Our Lady's Covenant of Mercy with humanity"),
        MonthlySaintDay(17, "ቅዱስ እስጢፋኖስ ቀዳሜ ሰማዕት", "St. Stephen Protomartyr", "Qulqulluu Isxifaanos", "ቅዱስ እስጢፋኖስ", "First Christian deacon and protomartyr"),
        MonthlySaintDay(18, "አቡነ ኤዎስጣቴዎስ", "Abune Ewostatewos", "Abbaa Ewosxaatewoos", "ኣቡነ ኤዎስጣቴዎስ", "Monastic reformer and founder of the Sabbath movement"),
        MonthlySaintDay(19, "ቅዱስ ገብርኤል ሊቀ መላእክት", "Archangel Gabriel", "Qulqulluu Gabri'eel", "ቅዱስ ገብርኤል", "Angel of the Annunciation & deliverance from the fiery furnace"),
        MonthlySaintDay(20, "ሕንፀተ ቤተክርስቲያን", "Dedication of St. Mary Church", "Ijaarsa Bataskaanaa", "ህንጸተ ቤተክርስቲያን", "Commemoration of the miraculous building of the first Marian church"),
        MonthlySaintDay(21, "እመቤታችን ቅድስት ድንግል ማርያም", "Virgin Mary (Mariam)", "Qulqulleettii Maariyaam", "ቅድስት ድንግል ማርያም", "Mother of God, Queen of Heaven, greatest intercessor"),
        MonthlySaintDay(22, "ቅዱስ ዑራኤል እና ደቅስዮስ", "Archangel Uriel & Daqsios", "Qulqulluu Uraa'eel", "ቅዱስ ዑራኤል", "Archangel Uriel, angel of illumination, and St. Dexius"),
        MonthlySaintDay(23, "ቅዱስ ጊዮርጊስ ሰማዕት", "St. George the Martyr", "Qulqulluu Giyoorgis", "ቅዱስ ጊዮርጊስ", "Great Martyr St. George of Lydda, vanquisher of the dragon"),
        MonthlySaintDay(24, "አቡነ ተክለ ሃይማኖት", "Abune Tekle Haymanot", "Abbaa Takla Haaymaanoot", "ኣቡነ ተክለ ሃይማኖት", "Beloved monastic father of Ethiopia and founder of Debre Libanos"),
        MonthlySaintDay(25, "ቅዱስ መርቆሬዎስ ሰማዕት", "St. Mercurius (Abu Seifein)", "Qulqulluu Marqorewoos", "ቅዱስ መርቆሬዎስ", "Great soldier-martyr with the two swords"),
        MonthlySaintDay(26, "ቅዱስ ቶማስ ሐዋርያ", "St. Thomas the Apostle", "Qulqulluu Toomaas", "ቅዱስ ቶማስ", "Apostle of Christ who proclaimed 'My Lord and my God'"),
        MonthlySaintDay(27, "መድኃኔ ዓለም", "Medhane Alem (Savior of the World)", "Madhaanee Alam", "መድኃኔ ዓለም", "Feast of our Lord and Savior Jesus Christ, Redeemer of all"),
        MonthlySaintDay(28, "አማኑኤል", "Emmanuel", "Imaanu'eel", "ኣማኑኤል", "Commemoration of God with Us, the Incarnate Christ"),
        MonthlySaintDay(29, "በዓለ ወልድ / ልደት", "Balewold (Feast of God the Son)", "Ayyaana Ilmaa", "በዓለ ወልድ", "Monthly celebration of the Holy Incarnation and Nativity"),
        MonthlySaintDay(30, "ቅዱስ ማርቆስ ወንጌላዊ", "St. Mark the Evangelist", "Qulqulluu Maarqoos", "ቅዱስ ማርቆስ", "Author of the Gospel of Mark and first Patriarch of Alexandria")
    )

    /**
     * Retrieves all holidays and celebrations for a specific Ethiopian year.
     */
    fun getHolidaysForYear(year: Int): List<Holiday> {
        val list = mutableListOf<Holiday>()
        val isLeap = EthiopianDate.isLeapYear(year)

        // 1. National & Public Fixed Holidays
        list.add(
            Holiday(
                "enkutatash_$year",
                "እንቁጣጣሽ (የኢትዮጵያ አዲስ ዓመት)",
                "Enkutatash (Ethiopian New Year)",
                "Enquxaaxaash (Bara Haaraa Itoophiyaa)",
                "እንቁጣጣሽ (ሓድሽ ዓመት)",
                EthiopianDate(year, 1, 1),
                HolidayType.NATIONAL_PUBLIC,
                "The Ethiopian New Year marks the end of the rainy season and arrival of sunshine and Adey Abeba flowers.",
                isPublicHoliday = true
            )
        )
        list.add(
            Holiday(
                "meskel_$year",
                "መስቀል (የደመራ በዓል)",
                "Meskel (Finding of the True Cross)",
                "Masqala (Ayyaana Dambaraa)",
                "መስቀል (ደመራ)",
                EthiopianDate(year, 1, 17),
                HolidayType.NATIONAL_PUBLIC,
                "UNESCO-inscribed festival celebrating Queen Helena finding the True Cross with bonfires (Demera).",
                isPublicHoliday = true
            )
        )
        list.add(
            Holiday(
                "genna_$year",
                "ገና (የጌታችን ልደት)",
                "Genna (Ethiopian Christmas)",
                "Gannaa (Dhaloota Gooftaa)",
                "ገና (ልደት)",
                // In leap year, Christmas is celebrated on Tahsas 28
                EthiopianDate(year, 4, if (isLeap) 28 else 29),
                HolidayType.NATIONAL_PUBLIC,
                "Feast of the Nativity of Jesus Christ, celebrated with traditional games and worship.",
                isPublicHoliday = true
            )
        )
        list.add(
            Holiday(
                "timket_$year",
                "ጥምቀት (ኤጲፋንያ)",
                "Timket (Epiphany)",
                "Cuuphaa",
                "ጥምቀት",
                EthiopianDate(year, 5, 11),
                HolidayType.NATIONAL_PUBLIC,
                "UNESCO-inscribed commemoration of the Baptism of Jesus in the Jordan River by John the Baptist.",
                isPublicHoliday = true
            )
        )
        list.add(
            Holiday(
                "kana_zegelila_$year",
                "ቃና ዘገሊላ",
                "Kana ZeGelila (Wedding of Cana)",
                "Qanaa Zagaliilaa",
                "ቃና ዘገሊላ",
                EthiopianDate(year, 5, 12),
                HolidayType.ORTHODOX_MAJOR,
                "Commemoration of Christ's first miracle turning water into wine at the wedding of Cana.",
                isPublicHoliday = false
            )
        )
        list.add(
            Holiday(
                "adwa_$year",
                "የዓድዋ ድል በዓል",
                "Victory of Adwa",
                "Injifannoo Adwaa",
                "መዓልቲ ዓወት ዓድዋ",
                EthiopianDate(year, 6, 23),
                HolidayType.NATIONAL_PUBLIC,
                "Celebrates Ethiopia's historic 1896 defeat of Italian colonial forces, symbol of African freedom.",
                isPublicHoliday = true
            )
        )
        list.add(
            Holiday(
                "patriots_day_$year",
                "የአርበኞች ቀን",
                "Ethiopian Patriots' Victory Day",
                "Guyyaa Goototaa",
                "መዓልቲ ሓርበኛታት",
                EthiopianDate(year, 8, 27),
                HolidayType.NATIONAL_PUBLIC,
                "Honors the patriots who resisted the 1936-1941 fascist occupation.",
                isPublicHoliday = true
            )
        )
        list.add(
            Holiday(
                "ginbot_20_$year",
                "ግንቦት 20",
                "Ginbot 20 (Downfall of Derg)",
                "Ginboot 20",
                "ግንቦት 20",
                EthiopianDate(year, 9, 20),
                HolidayType.NATIONAL_PUBLIC,
                "National day commemorating the fall of the military Derg regime.",
                isPublicHoliday = true
            )
        )

        // 2. Movable Orthodox Feasts from Bahire Hasab
        val bahireHasab = BahireHasabCalculator.calculate(year)
        for (feast in bahireHasab.movableFeasts) {
            val isPublic = feast.nameEnglish.contains("Easter") || feast.nameEnglish.contains("Good Friday")
            list.add(
                Holiday(
                    id = "bh_${feast.ethiopianDate.month}_${feast.ethiopianDate.day}_$year",
                    titleAmharic = feast.nameAmharic,
                    titleEnglish = feast.nameEnglish,
                    titleOromo = feast.nameOromo,
                    titleTigrinya = feast.nameTigrinya,
                    ethiopianDate = feast.ethiopianDate,
                    type = if (feast.isFast) HolidayType.ORTHODOX_FASTING else HolidayType.ORTHODOX_MOVABLE,
                    description = feast.description,
                    isPublicHoliday = isPublic,
                    isFasting = feast.isFast
                )
            )
        }

        // 3. Cultural & Regional Celebrations
        // Irreecha (Usually first Sunday after Meskel / early Tikimt)
        val meskelDow = EthiopianCalendarEngine.getDayOfWeek(EthiopianDate(year, 1, 17))
        val daysToSunday = (7 - meskelDow + 7) % 7
        val irreechaJdn = EthiopianCalendarEngine.ethiopianToJdn(EthiopianDate(year, 1, 17)) + (if (daysToSunday == 0) 7 else daysToSunday)
        val irreechaDate = EthiopianCalendarEngine.jdnToEthiopian(irreechaJdn)
        list.add(
            Holiday(
                "irreecha_$year",
                "ኢሬቻ (የኦሮሞ የምስጋና በዓል)",
                "Irreecha (Oromo Thanksgiving)",
                "Irreechaa (Ayyaana Galataa)",
                "ኢሬቻ",
                irreechaDate,
                HolidayType.CULTURAL_REGIONAL,
                "Historic Oromo thanksgiving celebration at Hora Harsadi (Bishoftu) and Hora Finfinnee (Addis Ababa).",
                isPublicHoliday = false
            )
        )

        // Ashenda / Shadey / Solel (Nehase 16 - 19)
        list.add(
            Holiday(
                "ashenda_$year",
                "አሸንዳ / ሻደይ / ሶለል",
                "Ashenda / Shadey / Solel Festival",
                "Ayyaana Ashendaa",
                "ኣሸንዳ (ማርያም)",
                EthiopianDate(year, 12, 16),
                HolidayType.CULTURAL_REGIONAL,
                "Joyous girls and young women's cultural festival celebrated across northern Ethiopia.",
                isPublicHoliday = false
            )
        )

        // Fichee-Chambalaalla (Around early Ginbot/Sene depending on Sidama elders Qeda)
        list.add(
            Holiday(
                "fichee_$year",
                "ፊቼ ጫምባላላ (የሲዳማ አዲስ ዓመት)",
                "Fichee-Chambalaalla (Sidama New Year)",
                "Ayyaana Fiichee Cambalaallaa",
                "ፊቼ ጫምባላላ",
                EthiopianDate(year, 9, 15),
                HolidayType.CULTURAL_REGIONAL,
                "UNESCO-inscribed intangible cultural heritage: Sidama New Year festival.",
                isPublicHoliday = false
            )
        )

        // 4. Islamic Celebrations in Ethiopian Context (Estimated via Gregorian/Lunar algorithm)
        val islamicHolidays = calculateIslamicHolidaysForYear(year)
        list.addAll(islamicHolidays)

        return list.sortedBy { it.ethiopianDate }
    }

    /**
     * Determines whether a given Ethiopian date is an Orthodox fasting day.
     */
    fun isFastingDay(date: EthiopianDate): FastingStatus {
        val dow = EthiopianCalendarEngine.getDayOfWeek(date)
        val bh = BahireHasabCalculator.calculate(date.year)

        // Date JDN
        val dateJdn = EthiopianCalendarEngine.ethiopianToJdn(date)
        val easter = bh.movableFeasts.firstOrNull { it.nameEnglish.contains("Easter") }
        val pentecost = bh.movableFeasts.firstOrNull { it.nameEnglish.contains("Pentecost") }

        // Fiseha 50 (ሃምሳ ፌስሐ): 50 days between Easter and Pentecost are NOT fast days
        if (easter != null && pentecost != null) {
            val easterJdn = EthiopianCalendarEngine.ethiopianToJdn(easter.ethiopianDate)
            val pentecostJdn = EthiopianCalendarEngine.ethiopianToJdn(pentecost.ethiopianDate)
            if (dateJdn in easterJdn..pentecostJdn) {
                return FastingStatus(isFasting = false, reason = "የሃምሳ ፌስሐ (Fifty Days of Joy - No Fasting)")
            }
        }

        // 1. Great Lent (ዓቢይ ጾም): 55 days ending on Holy Saturday eve
        val lentStart = bh.movableFeasts.firstOrNull { it.nameEnglish.contains("Great Lent") }
        if (lentStart != null && easter != null) {
            val lentJdn = EthiopianCalendarEngine.ethiopianToJdn(lentStart.ethiopianDate)
            val easterJdn = EthiopianCalendarEngine.ethiopianToJdn(easter.ethiopianDate)
            if (dateJdn in lentJdn until easterJdn) {
                return FastingStatus(isFasting = true, reason = "ዓቢይ ጾም (Great Lent / Hudade)")
            }
        }

        // 2. Fast of Nineveh (ጾመ ነነዌ): 3 days
        val neneweJdn = EthiopianCalendarEngine.ethiopianToJdn(bh.nenewe)
        if (dateJdn in neneweJdn..(neneweJdn + 2)) {
            return FastingStatus(isFasting = true, reason = "ጾመ ነነዌ (Fast of Nineveh)")
        }

        // 3. Fast of the Prophets (ጾመ ነቢያት): Hidar 15 to Tahsas 28/29
        val isLeap = EthiopianDate.isLeapYear(date.year)
        val adventEndDay = if (isLeap) 28 else 29
        if ((date.month == 3 && date.day >= 15) || (date.month == 4 && date.day <= adventEndDay)) {
            return FastingStatus(isFasting = true, reason = "ጾመ ነቢያት (Fast of the Prophets / Advent)")
        }

        // 4. Filseta (ጾመ ፍልሰታ): Nehase 1 to Nehase 16
        if (date.month == 12 && date.day in 1..16) {
            return FastingStatus(isFasting = true, reason = "ጾመ ፍልሰታ (Fast of the Assumption)")
        }

        // 5. Apostles Fast (ጾመ ሐዋርያት): Monday after Pentecost until Hamle 5
        val apostlesStart = bh.movableFeasts.firstOrNull { it.nameEnglish.contains("Fast of the Apostles") }
        if (apostlesStart != null) {
            val apStartJdn = EthiopianCalendarEngine.ethiopianToJdn(apostlesStart.ethiopianDate)
            val apEndJdn = EthiopianCalendarEngine.ethiopianToJdn(EthiopianDate(date.year, 11, 5))
            if (dateJdn in apStartJdn..apEndJdn) {
                return FastingStatus(isFasting = true, reason = "ጾመ ሐዋርያት (Fast of the Apostles / የሰኔ ጾም)")
            }
        }

        // 6. Weekly Fasting: Wednesday (ረቡዕ = 3) and Friday (ዓርብ = 5)
        if (dow == 3) {
            return FastingStatus(isFasting = true, reason = "የረቡዕ ጾም (Wednesday Fast of Salvation)")
        }
        if (dow == 5) {
            return FastingStatus(isFasting = true, reason = "የዓርብ ጾም (Friday Fast of the Crucifixion)")
        }

        return FastingStatus(isFasting = false, reason = "ጾም የለም (Regular day)")
    }

    data class FastingStatus(
        val isFasting: Boolean,
        val reason: String
    )

    fun getCanonicalFastsForYear(year: Int): List<CanonicalFast> {
        val bh = BahireHasabCalculator.calculate(year)
        val isLeap = EthiopianDate.isLeapYear(year)
        val list = mutableListOf<CanonicalFast>()

        // 1. ጾመ ነቢያት (Fast of the Prophets / Advent) - 43 days
        val adventStart = EthiopianDate(year, 3, 15)
        val adventEnd = EthiopianDate(year, 4, if (isLeap) 28 else 29)
        list.add(
            CanonicalFast(
                id = "fast_prophets_$year",
                nameAmharic = "ጾመ ነቢያት (የገና ጾም)",
                nameEnglish = "Fast of the Prophets (Advent)",
                nameOromo = "Sooma Raajotaa",
                nameTigrinya = "ጾመ ነብያት",
                durationDays = 43,
                startDate = adventStart,
                endDate = adventEnd,
                significance = "Commemorates the holy prophets who longed for, prayed, and prophesied the Incarnation of Christ.",
                dietaryRules = "Strict vegan diet (no meat, dairy, or eggs). Fasting daily until 3:00 PM.",
                biblicalFoundation = "Isaiah 7:14; Micah 5:2"
            )
        )

        // 2. ጾመ ጋድ (Gahad Fast of Genna & Timket)
        list.add(
            CanonicalFast(
                id = "fast_gahad_$year",
                nameAmharic = "ጾመ ጋድ (የልደትና ጥምቀት ዋዜማ)",
                nameEnglish = "Gahad Fast (Christmas & Epiphany Eves)",
                nameOromo = "Sooma Gaad",
                nameTigrinya = "ጾመ ጋድ",
                durationDays = 2,
                startDate = EthiopianDate(year, 4, if (isLeap) 27 else 28),
                endDate = EthiopianDate(year, 5, 10),
                significance = "Strict vigils observed on the eves of Christmas and Epiphany before midnight celebrations.",
                dietaryRules = "Complete fasting until the evening liturgy and Holy Communion.",
                biblicalFoundation = "Luke 2:7; Matthew 3:13"
            )
        )

        // 3. ጾመ ነነዌ (Fast of Nineveh) - 3 days
        val neneweStart = bh.nenewe
        val neneweEndJdn = EthiopianCalendarEngine.ethiopianToJdn(neneweStart) + 2
        val neneweEnd = EthiopianCalendarEngine.jdnToEthiopian(neneweEndJdn)
        list.add(
            CanonicalFast(
                id = "fast_nineveh_$year",
                nameAmharic = "ጾመ ነነዌ (የነነዌ ጾም)",
                nameEnglish = "Fast of Nineveh",
                nameOromo = "Sooma Nannawwee",
                nameTigrinya = "ጾመ ነነዌ",
                durationDays = 3,
                startDate = neneweStart,
                endDate = neneweEnd,
                significance = "Remembrance of the repentance of the citizens of Nineveh following Prophet Jonah's preaching.",
                dietaryRules = "Strict fasting from sunrise to 3:00 PM or dusk, followed by a purely vegan meal.",
                biblicalFoundation = "Jonah 3:5-10"
            )
        )

        // 4. ዓቢይ ጾም / ሁዳዴ (Great Lent) - 55 days
        val lentStart = bh.movableFeasts.firstOrNull { it.nameEnglish.contains("Great Lent") }?.ethiopianDate ?: BahireHasabCalculator.abiyTsom(year)
        val easter = bh.movableFeasts.firstOrNull { it.nameEnglish.contains("Easter") }?.ethiopianDate ?: BahireHasabCalculator.fasika(year)
        val lentEndJdn = EthiopianCalendarEngine.ethiopianToJdn(easter) - 1
        val lentEnd = EthiopianCalendarEngine.jdnToEthiopian(lentEndJdn)
        list.add(
            CanonicalFast(
                id = "fast_great_lent_$year",
                nameAmharic = "ዓቢይ ጾም (ሁዳዴ)",
                nameEnglish = "Great Lent (Hudade)",
                nameOromo = "Sooma Guddaa (Hudaadee)",
                nameTigrinya = "ዓቢይ ጾም",
                durationDays = 55,
                startDate = lentStart,
                endDate = lentEnd,
                significance = "The 55-day fast honoring Christ's 40-day wilderness fast, culminating in Holy Week (Himamat).",
                dietaryRules = "Strict abstinence from all animal products. Fasting until 3:00 PM daily; sunset during Holy Week.",
                biblicalFoundation = "Matthew 4:1-2; Mark 1:12-13"
            )
        )

        // 5. ጾመ ሐዋርያት (Fast of the Apostles - የሰኔ ጾም)
        val apostlesStart = bh.movableFeasts.firstOrNull { it.nameEnglish.contains("Fast of the Apostles") }?.ethiopianDate ?: BahireHasabCalculator.tsomeHawaryat(year)
        val apostlesEnd = EthiopianDate(year, 11, 5) // Hamle 5
        val apostlesDuration = BahireHasabCalculator.apostlesFastDuration(year)
        list.add(
            CanonicalFast(
                id = "fast_apostles_$year",
                nameAmharic = "ጾመ ሐዋርያት (የሰኔ ጾም)",
                nameEnglish = "Fast of the Apostles",
                nameOromo = "Sooma Ergamootaa",
                nameTigrinya = "ጾመ ሃዋርያት",
                durationDays = apostlesDuration,
                startDate = apostlesStart,
                endDate = apostlesEnd,
                significance = "Follows Pentecost, honoring the Apostles who fasted before proclaiming the Gospel across the nations.",
                dietaryRules = "Vegan diet, abstinence from dairy and meat, daily fasting until 3:00 PM.",
                biblicalFoundation = "Acts 13:2-3; Matthew 9:15"
            )
        )

        // 6. ጾመ ድኅነት (Fast of Salvation - ረቡዕ እና ዓርብ)
        list.add(
            CanonicalFast(
                id = "fast_salvation_$year",
                nameAmharic = "ጾመ ድኅነት (የረቡዕና ዓርብ ጾም)",
                nameEnglish = "Fast of Salvation (Wed & Fri)",
                nameOromo = "Sooma Fayyinaa (Roobii fi Jimmata)",
                nameTigrinya = "ጾመ ድሕነት (ረቡዕን ዓርብን)",
                durationDays = 104,
                startDate = EthiopianDate(year, 1, 1),
                endDate = EthiopianDate(year, 13, if (isLeap) 6 else 5),
                significance = "Observed every Wednesday (Betrayal by Judas) and Friday (Crucifixion), except the 50 Days of Joy.",
                dietaryRules = "Abstaining from all meat, fish, and dairy; fasting until 3:00 PM.",
                biblicalFoundation = "Zechariah 8:19; Didache 8:1"
            )
        )

        // 7. ጾመ ፍልሰታ (Fast of the Assumption) - 16 days
        list.add(
            CanonicalFast(
                id = "fast_filseta_$year",
                nameAmharic = "ጾመ ፍልሰታ ለማርያም",
                nameEnglish = "Fast of the Assumption (Filseta)",
                nameOromo = "Sooma Baqannaa Maariyaam",
                nameTigrinya = "ጾመ ፍልሰታ",
                durationDays = 16,
                startDate = EthiopianDate(year, 12, 1),
                endDate = EthiopianDate(year, 12, 16),
                significance = "16 days commemorating the bodily Assumption of the Blessed Virgin Mary into Heaven.",
                dietaryRules = "Strict veganism accompanied by devout prayers, prostrations, and holy liturgy.",
                biblicalFoundation = "Psalm 45:9; Revelation 12:1"
            )
        )

        return list
    }

    fun getDetailedFastingInfo(date: EthiopianDate): DetailedFastingInfo {
        val basic = isFastingDay(date)
        val bh = BahireHasabCalculator.calculate(date.year)
        val dateJdn = EthiopianCalendarEngine.ethiopianToJdn(date)

        val easter = bh.movableFeasts.firstOrNull { it.nameEnglish.contains("Easter") }
        val pentecost = bh.movableFeasts.firstOrNull { it.nameEnglish.contains("Pentecost") }
        if (easter != null && pentecost != null) {
            val easterJdn = EthiopianCalendarEngine.ethiopianToJdn(easter.ethiopianDate)
            val pentecostJdn = EthiopianCalendarEngine.ethiopianToJdn(pentecost.ethiopianDate)
            if (dateJdn in easterJdn..pentecostJdn) {
                return DetailedFastingInfo(
                    isFasting = false,
                    seasonNameAmharic = "የሃምሳ ፌስሐ (Fifty Days of Joy)",
                    seasonNameEnglish = "Fifty Days of Joy (Pentecost Season)",
                    fastingLevel = "No Fasting Allowed (በዓለ ፌስሐ)",
                    description = "Fifty glorious days celebrating the Resurrection and Ascension of Christ. Fasting is prohibited."
                )
            }
        }

        if (basic.isFasting) {
            val level = if (basic.reason.contains("ዓቢይ ጾም") || basic.reason.contains("ነነዌ")) {
                "Strict Fasting until 3:00 PM (Vegan only)"
            } else {
                "Fasting until 3:00 PM (Abstaining from meat & dairy)"
            }
            return DetailedFastingInfo(
                isFasting = true,
                seasonNameAmharic = basic.reason,
                seasonNameEnglish = "Orthodox Fasting Day",
                fastingLevel = level,
                description = "Abstaining from all animal products in prayer, repentance, and communion with God."
            )
        } else {
            return DetailedFastingInfo(
                isFasting = false,
                seasonNameAmharic = "ጾም የለም (Regular Day)",
                seasonNameEnglish = "Regular Day (Non-Fasting)",
                fastingLevel = "No fasting restriction",
                description = "Regular non-fasting day. Food may be enjoyed according to customary practices."
            )
        }
    }

    /**
     * Converts a Tabular Islamic calendar date (Hijri) to Julian Day Number (JDN).
     * Works accurately across centuries (past and next 100+ years).
     */
    private fun hijriToJdn(hYear: Int, hMonth: Int, hDay: Int): Long {
        val monthDays = kotlin.math.ceil(29.5 * (hMonth - 1)).toLong()
        val yearDays = (hYear - 1) * 354L + ((3 + 11 * hYear) / 30)
        return hDay + monthDays + yearDays + 1948439L
    }

    /**
     * Converts a Julian Day Number (JDN) to Tabular Islamic (Hijri) year.
     */
    private fun jdnToHijriYear(jdn: Long): Int {
        val days = jdn - 1948440L + 10632L
        val cycle = days / 10631L
        val rem = days % 10631L
        return (cycle * 30L + (rem * 30L + 14L) / 10631L - 29L).toInt()
    }

    /**
     * Calculates Islamic holidays falling within the given Ethiopian year.
     * Fully functional across centuries, including the next 100+ years.
     */
    private fun calculateIslamicHolidaysForYear(year: Int): List<Holiday> {
        val list = mutableListOf<Holiday>()

        // Ethiopian year boundaries in JDN
        val ethYearStartJdn = EthiopianCalendarEngine.ethiopianToJdn(EthiopianDate(year, 1, 1))
        val daysInYear = if (EthiopianDate.isLeapYear(year)) 366 else 365
        val ethYearEndJdn = ethYearStartJdn + daysInYear - 1

        // Determine the range of Hijri years overlapping this Ethiopian year
        val startHijriYear = jdnToHijriYear(ethYearStartJdn) - 1
        val endHijriYear = jdnToHijriYear(ethYearEndJdn) + 1

        for (hYear in startHijriYear..endHijriYear) {
            // 1. Mawlid (12 Rabi' al-Awwal = Month 3, Day 12)
            val mawlidJdn = hijriToJdn(hYear, 3, 12)
            if (mawlidJdn in ethYearStartJdn..ethYearEndJdn) {
                val mawlidDate = EthiopianCalendarEngine.jdnToEthiopian(mawlidJdn)
                list.add(
                    Holiday(
                        "mawlid_${hYear}_$year",
                        "መውሊድ (የነቢዩ መሐመድ ልደት)",
                        "Mawlid an-Nabi ($hYear AH)",
                        "Ayyaana Mawliidaa",
                        "መውሊድ",
                        mawlidDate,
                        HolidayType.ISLAMIC,
                        "Commemoration of the birth of Prophet Muhammad ($hYear AH), observed across Ethiopian Muslim communities.",
                        isPublicHoliday = true
                    )
                )
            }

            // 2. Ramadan Start (1 Ramadan = Month 9, Day 1)
            val ramadanJdn = hijriToJdn(hYear, 9, 1)
            if (ramadanJdn in ethYearStartJdn..ethYearEndJdn) {
                val ramadanDate = EthiopianCalendarEngine.jdnToEthiopian(ramadanJdn)
                list.add(
                    Holiday(
                        "ramadan_${hYear}_$year",
                        "የረመዳን መጀመሪያ",
                        "Start of Ramadan ($hYear AH)",
                        "Jalqaba Sooma Ramadaanaa",
                        "መጀመርታ ረመዳን",
                        ramadanDate,
                        HolidayType.ISLAMIC,
                        "Beginning of the holy fasting month of Ramadan for the year $hYear AH.",
                        isPublicHoliday = false,
                        isFasting = true
                    )
                )
            }

            // 3. Eid al-Fitr (1 Shawwal = Month 10, Day 1)
            val eidFitrJdn = hijriToJdn(hYear, 10, 1)
            if (eidFitrJdn in ethYearStartJdn..ethYearEndJdn) {
                val eidFitrDate = EthiopianCalendarEngine.jdnToEthiopian(eidFitrJdn)
                list.add(
                    Holiday(
                        "eid_fitr_${hYear}_$year",
                        "ዒድ አል-ፊጥር (የጾም መፍቻ በዓል)",
                        "Eid al-Fitr ($hYear AH)",
                        "Ayyaana Iid Al-Fixrii",
                        "ዒድ አል-ፊጥር",
                        eidFitrDate,
                        HolidayType.ISLAMIC,
                        "Celebration concluding the holy month of Ramadan ($hYear AH), marked with prayers, family feasts, and charity.",
                        isPublicHoliday = true
                    )
                )
            }

            // 4. Eid al-Adha / Arafa (10 Dhu al-Hijjah = Month 12, Day 10)
            val eidAdhaJdn = hijriToJdn(hYear, 12, 10)
            if (eidAdhaJdn in ethYearStartJdn..ethYearEndJdn) {
                val eidAdhaDate = EthiopianCalendarEngine.jdnToEthiopian(eidAdhaJdn)
                list.add(
                    Holiday(
                        "eid_adha_${hYear}_$year",
                        "ዒድ አል-አድሃ (አረፋ)",
                        "Eid al-Adha / Arafa ($hYear AH)",
                        "Ayyaana Iid Al-Adhaa (Arafa)",
                        "ዒድ አል-አድሓ (ዓረፋ)",
                        eidAdhaDate,
                        HolidayType.ISLAMIC,
                        "Feast of the Sacrifice ($hYear AH) commemorating Ibrahim's devotion, also concluding the annual Hajj pilgrimage.",
                        isPublicHoliday = true
                    )
                )
            }
        }

        return list
    }
}
