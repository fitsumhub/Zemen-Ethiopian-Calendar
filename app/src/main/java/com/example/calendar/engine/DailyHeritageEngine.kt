package com.example.calendar.engine

/**
 * Daily Ethiopian Heritage Engine (ቀን ቀን / ዕለታዊ ጥበብ).
 * Provides authentic Ethiopian proverbs (ምሳሌያዊ አነጋገሮች), liturgical commemorations,
 * and cultural wisdom for each day of the year.
 */
object DailyHeritageEngine {

    data class EthiopianProverb(
        val amharic: String,
        val englishTranslation: String,
        val meaning: String,
        val category: String // "ጥበብ" (Wisdom), "ትዕግሥት" (Patience), "አንድነት" (Unity), "ሥራ" (Diligence)
    )

    data class DailyHeritage(
        val date: EthiopianDate,
        val saint: HolidayEngine.MonthlySaintDay?,
        val fasting: HolidayEngine.FastingStatus,
        val proverb: EthiopianProverb,
        val solarPhase: String,
        val evangelist: String
    )

    // Curated authentic Ethiopian proverbs corresponding to the 30 days of any Ethiopian month (+ Pagume)
    val PROVERBS_BY_DAY = listOf(
        // Day 1
        EthiopianProverb(
            amharic = "ድር ቢያብር አንበሳ ያስር።",
            englishTranslation = "When spider webs unite, they can tie up a lion.",
            meaning = "አንድነትና ትብብር ትልልቅ ችግሮችን በቀላሉ ለመፍታት ኃይል ይሰጣል። (Unity and solidarity overcome the greatest obstacles.)",
            category = "አንድነት (Unity)"
        ),
        // Day 2
        EthiopianProverb(
            amharic = "ቀስ በቀስ ቇንቇ ዶሮ በእግሯ ትሄዳለች።",
            englishTranslation = "Little by little, an egg learns to walk on its own legs.",
            meaning = "በትዕግሥትና በተከታታይ ጥረት የማይሳካ ነገር የለም። (With patience and consistent effort, great milestones are achieved.)",
            category = "ትዕግሥት (Patience)"
        ),
        // Day 3
        EthiopianProverb(
            amharic = "ካለፈው ዓመት የተሻለ ዘንድሮ፣ ካለፈው ጥፋት የተሻለ ዛሬ።",
            englishTranslation = "Better this year than the past year; better today's wisdom than yesterday's error.",
            meaning = "ሰው ከስህተቱ ተምሮ በየቀኑ አዲስ ዕውቀትና ብልሃት ማግኘት አለበት። (Learn from yesterday to build a better today.)",
            category = "ጥበብ (Wisdom)"
        ),
        // Day 4
        EthiopianProverb(
            amharic = "ሰው በዕውቀቱ፣ እንጨት በእሳቱ።",
            englishTranslation = "A human is distinguished by wisdom, as wood is revealed by fire.",
            meaning = "የሰው ልጅ እውነተኛ ዋጋና ልህቀት የሚለካው ባለው ዕውቀትና በጎ ምግባር ነው። (True worth is measured by knowledge and virtue.)",
            category = "ጥበብ (Wisdom)"
        ),
        // Day 5
        EthiopianProverb(
            amharic = "እጅ ለእጅ ከተያያዙ፣ ተራራንም ይገፋሉ።",
            englishTranslation = "When hands join together, they can move mountains.",
            meaning = "የኅብረት ሥራ ከግለሰብ አቅም በላይ የሆኑ ፈተናዎችን ያቀላል። (Cooperation overcomes all hardships.)",
            category = "አንድነት (Unity)"
        ),
        // Day 6
        EthiopianProverb(
            amharic = "የዘራኸውን ታጭዳለህ፣ የበጎነት ፍሬ በጊዜው ያብባል።",
            englishTranslation = "What you sow, you shall reap; the fruit of kindness blossoms in due time.",
            meaning = "ለሌሎች የምናደርገው መልካም ነገር በሙሉ ወደ እኛ በበረከት ይመለሳል። (Good deeds always return as blessings.)",
            category = "ሥነ ምግባር (Virtue)"
        ),
        // Day 7
        EthiopianProverb(
            amharic = "እግዚአብሔር ሲሰጥ በጓዳ፣ ሲነሳ በደጅ።",
            englishTranslation = "When the Almighty blesses, it fills the heart quietly and abundantly.",
            meaning = "በረከትና ጸጋ በፈጣሪ ፈቃድ በትሕትና ይመጣል። (Blessings come through humility and grace.)",
            category = "እምነት (Faith)"
        ),
        // Day 8
        EthiopianProverb(
            amharic = "ካላዩ አያምኑ፣ ካልሰሩ አይበሉ።",
            englishTranslation = "Seeing brings belief; labor brings sustenance.",
            meaning = "ጠንክሮ መስራትና ምርታማ መሆን የክብርና የዕድገት መሠረት ነው። (Diligence is the foundation of dignified living.)",
            category = "ሥራ (Diligence)"
        ),
        // Day 9
        EthiopianProverb(
            amharic = "ከመናገር በፊት ማሰብ፣ ከመዝራት በፊት ማረስ።",
            englishTranslation = "Think before speaking, just as you plow before sowing.",
            meaning = "ጥንቁቅነትና አርቆ አሳቢነት ለስኬት ወሳኝ ናቸው። (Thoughtfulness and foresight lead to success.)",
            category = "ጥበብ (Wisdom)"
        ),
        // Day 10
        EthiopianProverb(
            amharic = "የቀስታ ሩጫ መንገድ ያስጨርሳል።",
            englishTranslation = "A steady pace finishes the longest journey.",
            meaning = "ሳይሰለቹ በተረጋጋ መንፈስ መጓዝ ግብ ላይ ያደርሳል። (Consistency and perseverance carry you to the finish line.)",
            category = "ትዕግሥት (Patience)"
        ),
        // Day 11
        EthiopianProverb(
            amharic = "በዕውቀት የታነጸ ቤት አይፈርስም።",
            englishTranslation = "A house built on wisdom never falls.",
            meaning = "ዕውቀትና ትምህርት የሕይወትን መሠረት ያጠነክራሉ። (Knowledge provides an unshakable foundation.)",
            category = "ጥበብ (Wisdom)"
        ),
        // Day 12
        EthiopianProverb(
            amharic = "የሚካኤል ክንፍ የሰላምና የምልጃ ምልክት ነው።",
            englishTranslation = "Peace and guardianship watch over the righteous.",
            meaning = "ሰላምና ጥበቃ በትሕትናና በእምነት ይመጣል። (Guardian peace surrounds those who walk in righteousness.)",
            category = "እምነት (Faith)"
        ),
        // Day 13
        EthiopianProverb(
            amharic = "ዛሬ ያበጠረው ነገ ያበስለዋል።",
            englishTranslation = "He who sifts today will bake tomorrow.",
            meaning = "የዛሬ ዝግጅት ለነገው ድግስና ስኬት ዋስትና ነው። (Today's preparation ensures tomorrow's abundance.)",
            category = "ሥራ (Diligence)"
        ),
        // Day 14
        EthiopianProverb(
            amharic = "መልካም ስም ከወርቅ ይበልጣል።",
            englishTranslation = "A good name is worth more than pure gold.",
            meaning = "ታማኝነትና ንፁህ ስብዕና ከምድራዊ ሀብት ሁሉ ይልቃል። (Integrity and character exceed worldly treasures.)",
            category = "ሥነ ምግባር (Virtue)"
        ),
        // Day 15
        EthiopianProverb(
            amharic = "ወሃ ሲጠማ ወደ ምንጭ፣ ሰው ሲጨነቅ ወደ ወዳጅ።",
            englishTranslation = "Thirst leads to the spring; hardship leads to a true companion.",
            meaning = "እውነተኛ ጓደኝነት በፈተና ጊዜ ይፈተሻል። (True friendship shines in times of adversity.)",
            category = "ወዳጅነት (Friendship)"
        ),
        // Day 16
        EthiopianProverb(
            amharic = "በዓላማ የጀመረ ሰው ከግማሽ በላይ ተራምዷል።",
            englishTranslation = "He who begins with clear purpose has already walked half the journey.",
            meaning = "ግልጽ ዕቅድና ዓላማ የመንገዱን አስቸጋሪነት ይቀንሳል። (Clear purpose makes the longest road easy.)",
            category = "ጥበብ (Wisdom)"
        ),
        // Day 17
        EthiopianProverb(
            amharic = "የእስጢፋኖስ ትዕግሥትና ይቅርታ የጽናት ማማ ነው።",
            englishTranslation = "Steadfast patience and forgiveness illuminate the path.",
            meaning = "ይቅር ባይነት የልብ ሰላምና የነፍስ ብርታት ይሰጣል። (Forgiveness yields profound inner peace.)",
            category = "ይቅርታ (Forgiveness)"
        ),
        // Day 18
        EthiopianProverb(
            amharic = "ጊዜ የሰጠው ቅል ድንጋይ ይሰብራል።",
            englishTranslation = "Given its season, even a humble gourd can crack a stone.",
            meaning = "የጊዜን ኃይልና ዋጋ መገንዘብ ብልህነት ነው። (Never underestimate the power of time and timing.)",
            category = "ጥበብ (Wisdom)"
        ),
        // Day 19
        EthiopianProverb(
            amharic = "የገብርኤል የምስራች የደስታ አብሳሪ ነው።",
            englishTranslation = "Good news and glad tidings brighten the heaviest heart.",
            meaning = "ተስፋና መልካም ዜና ለነገ ብርሃን ያበራሉ። (Hope and glad tidings illuminate tomorrow.)",
            category = "እምነት (Faith)"
        ),
        // Day 20
        EthiopianProverb(
            amharic = "የተማረ ሰው ለራሱ ብቻ ሳይሆን ለአገርም መብራት ነው።",
            englishTranslation = "An educated soul is a lamp for oneself and a beacon for the nation.",
            meaning = "ዕውቀትን ለወገን ማካፈል ታላቅ ክብር ነው። (Sharing knowledge enriches entire communities.)",
            category = "ጥበብ (Wisdom)"
        ),
        // Day 21
        EthiopianProverb(
            amharic = "የእናት ምርቃት ከሁሉ ይልቃል፤ የእመቤታችን ምልጃ ሰላምን ያወርዳል።",
            englishTranslation = "A mother's blessing is greatest; maternal warmth brings enduring peace.",
            meaning = "የእናት ፍቅርና ክብር በሕይወት ውስጥ ትልቅ በረከት ነው። (Maternal love and blessing form our deepest anchor.)",
            category = "በረከት (Blessing)"
        ),
        // Day 22
        EthiopianProverb(
            amharic = "ሳይቸኩሉ የሄዱበት መንገድ ድካሙ አይሰማም።",
            englishTranslation = "A path trodden without haste feels effortless.",
            meaning = "መረጋጋትና እርጋታ የተሳካ ውጤት ያስገኛሉ። (Calm deliberation brings fruitful outcomes.)",
            category = "ትዕግሥት (Patience)"
        ),
        // Day 23
        EthiopianProverb(
            amharic = "የጊዮርጊስ ጽናት ድል አድራጊነትን ያስተምራል።",
            englishTranslation = "Courage and steadfastness overcome all tribulations.",
            meaning = "በፅናት መቆም ከማንኛውም ፈተና በላይ ያደርጋል። (Unyielding courage triumphs over every challenge.)",
            category = "ጽናት (Courage)"
        ),
        // Day 24
        EthiopianProverb(
            amharic = "በልብ ያለን በጎ ሐሳብ በተግባር ማሳየት የጥበበኞች መንገድ ነው።",
            englishTranslation = "Turning righteous intent into action is the way of the wise.",
            meaning = "መልካም ሐሳብ ብቻ ሳይሆን መልካም ሥራ አስፈላጊ ነው። (Righteous action validates noble thoughts.)",
            category = "ሥነ ምግባር (Virtue)"
        ),
        // Day 25
        EthiopianProverb(
            amharic = "ጥንቸል በሩጫዋ፣ ኤሊ በትዕግሥቷ።",
            englishTranslation = "The hare has swiftness, but the tortoise has perseverance.",
            meaning = "በራስህ ፍጥነትና ብቃት ሳታቋርጥ መጓዝ አሸናፊ ያደርጋል። (Perseverance at your own pace wins the day.)",
            category = "ትዕግሥት (Patience)"
        ),
        // Day 26
        EthiopianProverb(
            amharic = "የዘወትር ንባብ የልብ አይን ያበራል።",
            englishTranslation = "Continuous study opens the eyes of the heart.",
            meaning = "ዘወትር መማርና ማስተዋል አእምሮን ያጎለምታል። (Lifelong reading and reflection expand perception.)",
            category = "ጥበብ (Wisdom)"
        ),
        // Day 27
        EthiopianProverb(
            amharic = "የመድኃኔዓለም ቸርነት ለሁሉም ፍጥረት ይዳረሳል።",
            englishTranslation = "Compassion and mercy extend to every living being.",
            meaning = "ርኅራኄና ፍቅር የሕይወት ትልቁ መመሪያ ነው። (Compassion and kindness elevate the spirit.)",
            category = "ፍቅር (Love & Mercy)"
        ),
        // Day 28
        EthiopianProverb(
            amharic = "የአማኑኤል ሰላም በልባችን ይንገሥ።",
            englishTranslation = "May peace and harmony reign within our hearts.",
            meaning = "ውስጣዊ ሰላም ለማኅበራዊ ደስታ ቁልፍ ነው። (Inner peace is the foundation of collective joy.)",
            category = "ሰላም (Peace)"
        ),
        // Day 29
        EthiopianProverb(
            amharic = "የበዓለ ወልድ ብርሃን ጨለማን ያባርራል።",
            englishTranslation = "The light of goodwill dispels all darkness.",
            meaning = "መልካምነት የትኛውንም ጭጋግ ገፎ ብርሃን ያመጣል። (Benevolence illuminates the darkest corners.)",
            category = "ተስፋ (Hope)"
        ),
        // Day 30
        EthiopianProverb(
            amharic = "ወር በወር ይተካል፣ ዘመን በዘመን ይለወጣል፤ መልካም ሥራ ግን ለዘላለም ይኖራል።",
            englishTranslation = "Months succeed months, eras replace eras; but righteous work endures forever.",
            meaning = "የሠራነው በጎ አሻራ ከጊዜ በላይ ዘላቂ ነው። (The noble legacy we build outlives time itself.)",
            category = "ዘላቂነት (Enduring Legacy)"
        )
    )

    // Pagume proverbs (Days 1 to 6)
    val PAGUME_PROVERBS = listOf(
        EthiopianProverb(
            amharic = "ጳጉሜ የዕርቅና የዝግጅት ድልድይ ናት።",
            englishTranslation = "Pagume is the bridge of reconciliation and renewal.",
            meaning = "የአሮጌውን ዓመት ስህተቶች ይቅር ብሎ ለአዲሱ ዘመን መዘጋጀት። (Reconciliation and renewal before stepping into the new dawn.)",
            category = "ዕርቅ (Renewal)"
        ),
        EthiopianProverb(
            amharic = "ጥቂቷን ቀን ያከበረ ብዙ ዘመን ይኖራል።",
            englishTranslation = "He who values the shortest day treasures a long lifetime.",
            meaning = "እያንዳንዱ ቀን ውድ ዋጋ አለው። (Every passing day holds immense value.)",
            category = "ጥበብ (Wisdom)"
        ),
        EthiopianProverb(
            amharic = "የሩፋኤል ጸበል የፈውስና የሰላም ምንጭ ነው።",
            englishTranslation = "Living springs of healing and quietude restore the soul.",
            meaning = "የአካልና የመንፈስ ፈውስ ይሁን። (May restoration and wellness touch every home.)",
            category = "ፈውስ (Healing)"
        ),
        EthiopianProverb(
            amharic = "በዕንቁጣጣሽ ዋዜማ ልቦች በይቅርታ ይሞላሉ።",
            englishTranslation = "On the eve of the New Dawn, hearts overflow with pardon.",
            meaning = "አዲስ ዓመት በአዲስ መንፈስና ፍቅር ይጀመራል። (Welcome the New Year with a clean heart.)",
            category = "ይቅርታ (Pardon)"
        ),
        EthiopianProverb(
            amharic = "የዘመን መለወጫ የተስፋ በር ይከፍታል።",
            englishTranslation = "The turning of the year unlocks the golden gates of hope.",
            meaning = "ለአገራችንና ለሕዝባችን ሰላምና በረከት ይመኝ። (A fresh horizon of peace and abundance.)",
            category = "ተስፋ (Hope)"
        ),
        EthiopianProverb(
            amharic = "ዘመነ ሉቃስ በስድስተኛዋ የጳጉሜ ቀን ፍጹም ይሆናል።",
            englishTranslation = "The leap year finds completion in Pagume's sixth day of grace.",
            meaning = "የዘመን ስሌት ፍጹምነትና የእግዚአብሔር ሥርዓት ድንቅ ነው። (The harmony of the seasons reflects divine order.)",
            category = "ጥበብ (Wisdom)"
        )
    )

    /**
     * Resolves the complete daily heritage for any given Ethiopian Date.
     */
    fun getHeritageForDate(date: EthiopianDate): DailyHeritage {
        val saint = HolidayEngine.MONTHLY_SAINTS.firstOrNull { it.day == date.day }
        val fasting = HolidayEngine.isFastingDay(date)

        val proverb = if (date.month == 13) {
            val pIdx = (date.day - 1).coerceIn(0, PAGUME_PROVERBS.lastIndex)
            PAGUME_PROVERBS[pIdx]
        } else {
            val pIdx = (date.day - 1).coerceIn(0, PROVERBS_BY_DAY.lastIndex)
            PROVERBS_BY_DAY[pIdx]
        }

        val evangelistIndex = EthiopianCalendarEngine.getEvangelist(date.year)
        val evangelist = when (evangelistIndex) {
            1 -> "ዘመነ ማቴዎስ"
            2 -> "ዘመነ ማርቆስ"
            3 -> "ዘመነ ሉቃስ"
            else -> "ዘመነ ዮሐንስ"
        }

        val solarPhase = if (date.month in 1..3) "መከር (Autumn / Harvest)"
        else if (date.month in 4..6) "በጋ (Winter / Dry Season)"
        else if (date.month in 7..9) "በልግ (Spring / Blossom)"
        else "ክረምት (Summer / Rainy Season)"

        return DailyHeritage(
            date = date,
            saint = saint,
            fasting = fasting,
            proverb = proverb,
            solarPhase = solarPhase,
            evangelist = evangelist
        )
    }
}
