import '../calendar/bahire_hasab.dart';
import '../calendar/ethiopian_calendar_engine.dart';
import '../calendar/ethiopian_date.dart';

enum HolidayType {
  nationalPublic,
  orthodoxMajor,
  orthodoxMovable,
  orthodoxFasting,
  islamic,
  culturalRegional,
  monthlySaint,
}

class Holiday {
  final String id;
  final String titleAmharic;
  final String titleEnglish;
  final String titleOromo;
  final String titleTigrinya;
  final EthiopianDate ethiopianDate;
  final HolidayType type;
  final String description;
  final bool isPublicHoliday;
  final bool isFasting;

  const Holiday({
    required this.id,
    required this.titleAmharic,
    required this.titleEnglish,
    required this.titleOromo,
    required this.titleTigrinya,
    required this.ethiopianDate,
    required this.type,
    required this.description,
    this.isPublicHoliday = false,
    this.isFasting = false,
  });
}

class MonthlySaintDay {
  final int day;
  final String nameAmharic;
  final String nameEnglish;
  final String nameOromo;
  final String nameTigrinya;
  final String significance;

  const MonthlySaintDay({
    required this.day,
    required this.nameAmharic,
    required this.nameEnglish,
    required this.nameOromo,
    required this.nameTigrinya,
    required this.significance,
  });

  String get description => significance;
}

class CanonicalFast {
  final String id;
  final String nameAmharic;
  final String nameEnglish;
  final String nameOromo;
  final String nameTigrinya;
  final int durationDays;
  final EthiopianDate startDate;
  final EthiopianDate endDate;
  final String significance;
  final String dietaryRules;
  final String biblicalFoundation;

  const CanonicalFast({
    required this.id,
    required this.nameAmharic,
    required this.nameEnglish,
    required this.nameOromo,
    required this.nameTigrinya,
    required this.durationDays,
    required this.startDate,
    required this.endDate,
    required this.significance,
    required this.dietaryRules,
    required this.biblicalFoundation,
  });

  int get totalDays => durationDays;
  String get description => significance;
}

class FastingLevel {
  final String amharic;
  final String description;

  const FastingLevel({
    required this.amharic,
    required this.description,
  });
}

class FastingStatus {
  final bool isFasting;
  final String reason;
  final FastingLevel level;

  const FastingStatus({
    required this.isFasting,
    required this.reason,
    this.level = const FastingLevel(
      amharic: 'መደበኛ',
      description: 'Standard fasting',
    ),
  });
}

class DetailedFastingInfo {
  final bool isFasting;
  final String seasonNameAmharic;
  final String seasonNameEnglish;
  final String fastingLevel;
  final String description;

  const DetailedFastingInfo({
    required this.isFasting,
    required this.seasonNameAmharic,
    required this.seasonNameEnglish,
    required this.fastingLevel,
    required this.description,
  });
}

class HolidayEngine {
  static const List<MonthlySaintDay> monthlySaints = [
    MonthlySaintDay(day: 1, nameAmharic: "ልደታ ለማርያም እና ኤልያስ", nameEnglish: "Lideta & Elias", nameOromo: "Lidataa fi Eeliyaas", nameTigrinya: "ልደታን ኤልያስን", significance: "Birth of Virgin Mary and Prophet Elijah"),
    MonthlySaintDay(day: 2, nameAmharic: "ታዴዎስ ሐዋርያ", nameEnglish: "Thaddaeus the Apostle", nameOromo: "Taadewoos Ergamaa", nameTigrinya: "ታዴዎስ ሃዋርያ", significance: "Commemoration of Apostle St. Jude Thaddaeus"),
    MonthlySaintDay(day: 3, nameAmharic: "በዓታ ለማርያም", nameEnglish: "Ba'eta leMaryam", nameOromo: "Ba'ataa Maariyaam", nameTigrinya: "በዓታ ለማርያም", significance: "Entry of the Virgin Mary into the Temple"),
    MonthlySaintDay(day: 4, nameAmharic: "ዮሐንስ ወልደ ነጎድጓድ", nameEnglish: "St. John the Evangelist", nameOromo: "Yohaannis Ilma Qaqawweessaa", nameTigrinya: "ዮሃንስ ወልደ ነጎድጓድ", significance: "Apostle John the Theologian, beloved disciple of Christ"),
    MonthlySaintDay(day: 5, nameAmharic: "አቡነ ገብረ መንፈስ ቅዱስ (አቦ)", nameEnglish: "Abune Gebre Menfes Kidus (Abo)", nameOromo: "Abbaa Gabra Manfas Qulqulluu", nameTigrinya: "አቡነ ገብረ መንፈስ ቅዱስ", significance: "Desert Monk & Hermit of Mount Ziquala"),
    MonthlySaintDay(day: 6, nameAmharic: "ቁስቋም ማርያም እና ኢየሱስ", nameEnglish: "Qusqwam Maryam", nameOromo: "Maariyaam Qusquwaam", nameTigrinya: "ቁስቋም ማርያም", significance: "Holy Family's exile and refuge in Mount Qusqwam, Egypt"),
    MonthlySaintDay(day: 7, nameAmharic: "ቅድስት ሥላሴ", nameEnglish: "Holy Trinity (Selassie)", nameOromo: "Sillaasee Qulqulluu", nameTigrinya: "ቅድስት ሥላሴ", significance: "Solemnity of the Holy Trinity: Father, Son, and Holy Spirit"),
    MonthlySaintDay(day: 8, nameAmharic: "አባ ኪሮስ እና ዮሐንስ አፈወርቅ", nameEnglish: "Abba Kiros & John Chrysostom", nameOromo: "Abbaa Kiroos", nameTigrinya: "ኣባ ኪሮስ", significance: "St. Kiros the Ascetic and St. John Chrysostom Golden-mouthed"),
    MonthlySaintDay(day: 9, nameAmharic: "ሠለስቱ ምዕት (318ቱ አባቶች)", nameEnglish: "318 Church Fathers of Nicaea", nameOromo: "Abbootii 318 Niiqiyaa", nameTigrinya: "ሰለስቱ ምእት", significance: "Defenders of orthodox doctrine at the First Council of Nicaea"),
    MonthlySaintDay(day: 10, nameAmharic: "መስቀለ ክርስቶስ", nameEnglish: "Feast of the Holy Cross", nameOromo: "Fannoo Masqalaa", nameTigrinya: "መስቀለ ክርስቶስ", significance: "Commemoration of the Cross of Salvation"),
    MonthlySaintDay(day: 11, nameAmharic: "ሐና እና ኢያቄም", nameEnglish: "St. Anne & St. Joachim", nameOromo: "Haannaa fi Iyaaqeem", nameTigrinya: "ሃናን ኢያቄምን", significance: "Righteous parents of the Blessed Virgin Mary"),
    MonthlySaintDay(day: 12, nameAmharic: "ቅዱስ ሚካኤል ሊቀ መላእክት", nameEnglish: "Archangel Michael", nameOromo: "Qulqulluu Mikaa'el", nameTigrinya: "ቅዱስ ሚካኤል", significance: "Feast of Archangel Michael, protector and defender of God's people"),
    MonthlySaintDay(day: 13, nameAmharic: "እግዚአብሔር አብ እና ሩፋኤል", nameEnglish: "God the Father & Raphael", nameOromo: "Waaqayyo Abbaa fi Rufaa'eel", nameTigrinya: "እግዚአብሔር ኣብ", significance: "Providence of God the Father & Archangel Raphael the Healer"),
    MonthlySaintDay(day: 14, nameAmharic: "አባ አረጋዊ እና ገብረ ክርስቶስ", nameEnglish: "Abba Aregawi & Gebre Kristos", nameOromo: "Abbaa Aragawwii", nameTigrinya: "ኣባ ኣረጋዊ", significance: "Leader of the Nine Saints, founder of Debre Damo monastery"),
    MonthlySaintDay(day: 15, nameAmharic: "ቅዱስ ቂርቆስ እና ኢየሉጣ", nameEnglish: "St. Cyricus & Julitta", nameOromo: "Qulqulluu Qirqoos", nameTigrinya: "ቅዱስ ቂርቆስ", significance: "Holy Child Martyr Quiricus and his mother Julitta"),
    MonthlySaintDay(day: 16, nameAmharic: "ኪዳነ ምሕረት", nameEnglish: "Kidane Mihret (Covenant of Mercy)", nameOromo: "Kidaana Mihrat", nameTigrinya: "ኪዳነ ምሕረት", significance: "Our Lady's Covenant of Mercy with humanity"),
    MonthlySaintDay(day: 17, nameAmharic: "ቅዱስ እስጢፋኖስ ቀዳሜ ሰማዕት", nameEnglish: "St. Stephen Protomartyr", nameOromo: "Qulqulluu Isxifaanos", nameTigrinya: "ቅዱስ እስጢፋኖስ", significance: "First Christian deacon and protomartyr"),
    MonthlySaintDay(day: 18, nameAmharic: "አቡነ ኤዎስጣቴዎስ", nameEnglish: "Abune Ewostatewos", nameOromo: "Abbaa Ewosxaatewoos", nameTigrinya: "ኣቡነ ኤዎስጣቴዎስ", significance: "Monastic reformer and founder of the Sabbath movement"),
    MonthlySaintDay(day: 19, nameAmharic: "ቅዱስ ገብርኤል ሊቀ መላእክት", nameEnglish: "Archangel Gabriel", nameOromo: "Qulqulluu Gabri'eel", nameTigrinya: "ቅዱስ ገብርኤል", significance: "Angel of the Annunciation & deliverance from the fiery furnace"),
    MonthlySaintDay(day: 20, nameAmharic: "ሕንፀተ ቤተክርስቲያን", nameEnglish: "Dedication of St. Mary Church", nameOromo: "Ijaarsa Bataskaanaa", nameTigrinya: "ህንጸተ ቤተክርስቲያን", significance: "Commemoration of the miraculous building of the first Marian church"),
    MonthlySaintDay(day: 21, nameAmharic: "እመቤታችን ቅድስት ድንግል ማርያም", nameEnglish: "Virgin Mary (Mariam)", nameOromo: "Qulqulleettii Maariyaam", nameTigrinya: "ቅድስት ድንግል ማርያም", significance: "Mother of God, Queen of Heaven, greatest intercessor"),
    MonthlySaintDay(day: 22, nameAmharic: "ቅዱስ ዑራኤል እና ደቅስዮስ", nameEnglish: "Archangel Uriel & Daqsios", nameOromo: "Qulqulluu Uraa'eel", nameTigrinya: "ቅዱስ ዑራኤል", significance: "Archangel Uriel, angel of illumination, and St. Dexius"),
    MonthlySaintDay(day: 23, nameAmharic: "ቅዱስ ጊዮርጊስ ሰማዕት", nameEnglish: "St. George the Martyr", nameOromo: "Qulqulluu Giyoorgis", nameTigrinya: "ቅዱስ ጊዮርጊስ", significance: "Great Martyr St. George of Lydda, vanquisher of the dragon"),
    MonthlySaintDay(day: 24, nameAmharic: "አቡነ ተክለ ሃይማኖት", nameEnglish: "Abune Tekle Haymanot", nameOromo: "Abbaa Takla Haaymaanoot", nameTigrinya: "ኣቡነ ተክለ ሃይማኖት", significance: "Beloved monastic father of Ethiopia and founder of Debre Libanos"),
    MonthlySaintDay(day: 25, nameAmharic: "ቅዱስ መርቆሬዎስ ሰማዕት", nameEnglish: "St. Mercurius (Abu Seifein)", nameOromo: "Qulqulluu Marqorewoos", nameTigrinya: "ቅዱስ መርቆሬዎስ", significance: "Great soldier-martyr with the two swords"),
    MonthlySaintDay(day: 26, nameAmharic: "ቅዱስ ቶማስ ሐዋርያ", nameEnglish: "St. Thomas the Apostle", nameOromo: "Qulqulluu Toomaas", nameTigrinya: "ቅዱስ ቶማስ", significance: "Apostle of Christ who proclaimed 'My Lord and my God'"),
    MonthlySaintDay(day: 27, nameAmharic: "መድኃኔ ዓለም", nameEnglish: "Medhane Alem (Savior of the World)", nameOromo: "Madhaanee Alam", nameTigrinya: "መድኃኔ ዓለም", significance: "Feast of our Lord and Savior Jesus Christ, Redeemer of all"),
    MonthlySaintDay(day: 28, nameAmharic: "አማኑኤል", nameEnglish: "Emmanuel", nameOromo: "Imaanu'eel", nameTigrinya: "ኣማኑኤል", significance: "Commemoration of God with Us, the Incarnate Christ"),
    MonthlySaintDay(day: 29, nameAmharic: "በዓለ ወልድ / ልደት", nameEnglish: "Balewold (Feast of God the Son)", nameOromo: "Ayyaana Ilmaa", nameTigrinya: "በዓለ ወልድ", significance: "Monthly celebration of the Holy Incarnation and Nativity"),
    MonthlySaintDay(day: 30, nameAmharic: "ቅዱስ ማርቆስ ወንጌላዊ", nameEnglish: "St. Mark the Evangelist", nameOromo: "Qulqulluu Maarqoos", nameTigrinya: "ቅዱስ ማርቆስ", significance: "Author of the Gospel of Mark and first Patriarch of Alexandria"),
  ];

  /// Day of Tahsas on which Genna (Lidet, Ethiopian Christmas) falls.
  ///
  /// Genna is Tahsas 29, except in the year that FOLLOWS an Ethiopian leap
  /// year (ዘመነ ዮሐንስ, `year % 4 == 0`): the six-day Pagume just before that
  /// year moves the feast to Tahsas 28. Either way it lands on 7 January
  /// Gregorian (25 December Julian) throughout 1901–2099, e.g.
  /// Tahsas 29, 2015 = 7 Jan 2023 and Tahsas 28, 2016 = 7 Jan 2024.
  ///
  /// The original Kotlin engine keyed this on the leap year itself
  /// (`year % 4 == 3`), which put Genna one day off in two years out of four.
  static int gennaDay(int year) => year % 4 == 0 ? 28 : 29;

  static List<Holiday> getHolidaysForYear(int year) {
    final list = <Holiday>[];

    // 1. National & Public Fixed Holidays
    list.add(
      Holiday(
        id: "enkutatash_$year",
        titleAmharic: "እንቁጣጣሽ (የኢትዮጵያ አዲስ ዓመት)",
        titleEnglish: "Enkutatash (Ethiopian New Year)",
        titleOromo: "Enquxaaxaash (Bara Haaraa Itoophiyaa)",
        titleTigrinya: "እንቁጣጣሽ (ሓድሽ ዓመት)",
        ethiopianDate: EthiopianDate(year, 1, 1),
        type: HolidayType.nationalPublic,
        description: "The Ethiopian New Year marks the end of the rainy season and arrival of sunshine and Adey Abeba flowers.",
        isPublicHoliday: true,
      ),
    );
    list.add(
      Holiday(
        id: "meskel_$year",
        titleAmharic: "መስቀል (የደመራ በዓል)",
        titleEnglish: "Meskel (Finding of the True Cross)",
        titleOromo: "Masqala (Ayyaana Dambaraa)",
        titleTigrinya: "መስቀል (ደመራ)",
        ethiopianDate: EthiopianDate(year, 1, 17),
        type: HolidayType.nationalPublic,
        description: "UNESCO-inscribed festival celebrating Queen Helena finding the True Cross with bonfires (Demera).",
        isPublicHoliday: true,
      ),
    );
    list.add(
      Holiday(
        id: "genna_$year",
        titleAmharic: "ገና (የጌታችን ልደት)",
        titleEnglish: "Genna (Ethiopian Christmas)",
        titleOromo: "Gannaa (Dhaloota Gooftaa)",
        titleTigrinya: "ገና (ልደት)",
        ethiopianDate: EthiopianDate(year, 4, gennaDay(year)),
        type: HolidayType.nationalPublic,
        description: "Feast of the Nativity of Jesus Christ, celebrated with traditional games and worship.",
        isPublicHoliday: true,
      ),
    );
    list.add(
      Holiday(
        id: "timket_$year",
        titleAmharic: "ጥምቀት (ኤጲፋንያ)",
        titleEnglish: "Timket (Epiphany)",
        titleOromo: "Cuuphaa",
        titleTigrinya: "ጥምቀት",
        ethiopianDate: EthiopianDate(year, 5, 11),
        type: HolidayType.nationalPublic,
        description: "UNESCO-inscribed commemoration of the Baptism of Jesus in the Jordan River by John the Baptist.",
        isPublicHoliday: true,
      ),
    );
    list.add(
      Holiday(
        id: "kana_zegelila_$year",
        titleAmharic: "ቃና ዘገሊላ",
        titleEnglish: "Kana ZeGelila (Wedding of Cana)",
        titleOromo: "Qanaa Zagaliilaa",
        titleTigrinya: "ቃና ዘገሊላ",
        ethiopianDate: EthiopianDate(year, 5, 12),
        type: HolidayType.orthodoxMajor,
        description: "Commemoration of Christ's first miracle turning water into wine at the wedding of Cana.",
        isPublicHoliday: false,
      ),
    );
    list.add(
      Holiday(
        id: "nations_nationalities_$year",
        titleAmharic: "የብሔር ብሔረሰቦች ቀን",
        titleEnglish: "Nations, Nationalities and Peoples' Day",
        titleOromo: "Guyyaa Sabootaa fi Uummatootaa",
        titleTigrinya: "መዓልቲ ብሄራት ብሄረሰባትን ህዝብታትን",
        ethiopianDate: EthiopianDate(year, 3, 29),
        type: HolidayType.nationalPublic,
        description: "National day celebrating Ethiopia's nations, nationalities and peoples (Hidar 29).",
        isPublicHoliday: true,
      ),
    );
    list.add(
      Holiday(
        id: "martyrs_day_$year",
        titleAmharic: "የሰማዕታት ቀን",
        titleEnglish: "Martyrs' Day",
        titleOromo: "Guyyaa Shaheedotaa",
        titleTigrinya: "መዓልቲ ሰማእታት",
        ethiopianDate: EthiopianDate(year, 6, 12),
        type: HolidayType.nationalPublic,
        description: "Remembrance day for victims of the Red Terror and national martyrs (Yekatit 12).",
        isPublicHoliday: true,
      ),
    );
    list.add(
      Holiday(
        id: "adwa_$year",
        titleAmharic: "የዓድዋ ድል በዓል",
        titleEnglish: "Victory of Adwa",
        titleOromo: "Injifannoo Adwaa",
        titleTigrinya: "መዓልቲ ዓወት ዓድዋ",
        ethiopianDate: EthiopianDate(year, 6, 23),
        type: HolidayType.nationalPublic,
        description: "Celebrates Ethiopia's historic 1896 defeat of Italian colonial forces, symbol of African freedom.",
        isPublicHoliday: true,
      ),
    );
    list.add(
      Holiday(
        id: "labour_day_$year",
        titleAmharic: "የሰራተኞች ቀን",
        titleEnglish: "International Labour Day",
        titleOromo: "Guyyaa Hojjettootaa",
        titleTigrinya: "መዓልቲ ሰራሕተኛታት",
        ethiopianDate: EthiopianDate(year, 8, 23),
        type: HolidayType.nationalPublic,
        description: "International Workers' Day (Miazia 23 / 1 May Gregorian in modern alignment).",
        isPublicHoliday: true,
      ),
    );
    list.add(
      Holiday(
        id: "patriots_day_$year",
        titleAmharic: "የአርበኞች ቀን",
        titleEnglish: "Ethiopian Patriots' Victory Day",
        titleOromo: "Guyyaa Goototaa",
        titleTigrinya: "መዓልቲ ሓርበኛታት",
        ethiopianDate: EthiopianDate(year, 8, 27),
        type: HolidayType.nationalPublic,
        description: "Honors the patriots who resisted the 1936-1941 fascist occupation.",
        isPublicHoliday: true,
      ),
    );
    list.add(
      Holiday(
        id: "ginbot_20_$year",
        titleAmharic: "ግንቦት 20",
        titleEnglish: "Ginbot 20 (Downfall of Derg)",
        titleOromo: "Ginboot 20",
        titleTigrinya: "ግንቦት 20",
        ethiopianDate: EthiopianDate(year, 9, 20),
        type: HolidayType.nationalPublic,
        description: "National day commemorating the fall of the military Derg regime.",
        isPublicHoliday: true,
      ),
    );

    // Additional fixed Orthodox & cultural observances (annual)
    list.addAll(_fixedOrthodoxAndCulturalHolidays(year));

    // 2. Movable Orthodox Feasts from Bahire Hasab
    final bahireHasab = BahireHasab.calculate(year);
    for (final feast in bahireHasab.movableFeasts) {
      final isPublic = feast.nameEnglish.contains("Easter") || feast.nameEnglish.contains("Good Friday");
      list.add(
        Holiday(
          id: "bh_${feast.ethiopianDate.month}_${feast.ethiopianDate.day}_$year",
          titleAmharic: feast.nameAmharic,
          titleEnglish: feast.nameEnglish,
          titleOromo: feast.nameOromo,
          titleTigrinya: feast.nameTigrinya,
          ethiopianDate: feast.ethiopianDate,
          type: feast.isFast ? HolidayType.orthodoxFasting : HolidayType.orthodoxMovable,
          description: feast.description,
          isPublicHoliday: isPublic,
          isFasting: feast.isFast,
        ),
      );
    }

    // 3. Cultural & Regional Celebrations
    // Irreecha (Usually first Sunday after Meskel / early Tikimt)
    final meskelDow = EthiopianCalendarEngine.getDayOfWeek(EthiopianDate(year, 1, 17));
    final daysToSunday = (7 - meskelDow + 7) % 7;
    final irreechaJdn = EthiopianCalendarEngine.ethiopianToJdn(EthiopianDate(year, 1, 17)) + (daysToSunday == 0 ? 7 : daysToSunday);
    final irreechaDate = EthiopianCalendarEngine.jdnToEthiopian(irreechaJdn);
    list.add(
      Holiday(
        id: "irreecha_$year",
        titleAmharic: "ኢሬቻ (የኦሮሞ የምስጋና በዓል)",
        titleEnglish: "Irreecha (Oromo Thanksgiving)",
        titleOromo: "Irreechaa (Ayyaana Galataa)",
        titleTigrinya: "ኢሬቻ",
        ethiopianDate: irreechaDate,
        type: HolidayType.culturalRegional,
        description: "Historic Oromo thanksgiving celebration at Hora Harsadi (Bishoftu) and Hora Finfinnee (Addis Ababa).",
        isPublicHoliday: false,
      ),
    );

    // Ashenda / Shadey / Solel (Nehase 16 - 19)
    list.add(
      Holiday(
        id: "ashenda_$year",
        titleAmharic: "አሸንዳ / ሻደይ / ሶለል",
        titleEnglish: "Ashenda / Shadey / Solel Festival",
        titleOromo: "Ayyaana Ashendaa",
        titleTigrinya: "ኣሸንዳ (ማርያም)",
        ethiopianDate: EthiopianDate(year, 12, 16),
        type: HolidayType.culturalRegional,
        description: "Joyous girls and young women's cultural festival celebrated across northern Ethiopia.",
        isPublicHoliday: false,
      ),
    );

    // Fichee-Chambalaalla (Around early Ginbot/Sene depending on Sidama elders Qeda)
    list.add(
      Holiday(
        id: "fichee_$year",
        titleAmharic: "ፊቼ ጫምባላላ (የሲዳማ አዲስ ዓመት)",
        titleEnglish: "Fichee-Chambalaalla (Sidama New Year)",
        titleOromo: "Ayyaana Fiichee Cambalaallaa",
        titleTigrinya: "ፊቼ ጫምባላላ",
        ethiopianDate: EthiopianDate(year, 9, 15),
        type: HolidayType.culturalRegional,
        description: "UNESCO-inscribed intangible cultural heritage: Sidama New Year festival.",
        isPublicHoliday: false,
      ),
    );

    // 4. Islamic Celebrations
    list.addAll(_calculateIslamicHolidaysForYear(year));

    list.sort((a, b) => a.ethiopianDate.compareTo(b.ethiopianDate));
    return list;
  }

  /// Returns all holidays occurring on the specified Ethiopian date.
  static List<Holiday> getHolidaysForDate(EthiopianDate date) {
    return getHolidaysForYear(date.year)
        .where((h) => h.ethiopianDate == date)
        .toList();
  }

  /// Holidays spanning an inclusive Ethiopian year range (e.g. today → +20).
  static List<Holiday> getHolidaysForYearRange(int startYear, int endYear) {
    final from = startYear <= endYear ? startYear : endYear;
    final to = startYear <= endYear ? endYear : startYear;
    final list = <Holiday>[];
    for (var y = from; y <= to; y++) {
      list.addAll(getHolidaysForYear(y));
    }
    list.sort((a, b) => a.ethiopianDate.compareTo(b.ethiopianDate));
    return list;
  }

  /// Upcoming holidays from [fromDate] across the next [yearsAhead] Ethiopian years.
  static List<Holiday> getUpcomingHolidays({
    EthiopianDate? fromDate,
    int yearsAhead = 20,
    bool publicOnly = false,
  }) {
    final start = fromDate ?? EthiopianCalendarEngine.todayEthiopian();
    final endYear = start.year + yearsAhead.clamp(1, 30);
    final list = getHolidaysForYearRange(start.year, endYear).where((h) {
      if (h.ethiopianDate < start) return false;
      if (publicOnly && !h.isPublicHoliday) return false;
      return true;
    }).toList();
    return list;
  }

  static List<Holiday> _fixedOrthodoxAndCulturalHolidays(int year) {
    return [
      Holiday(
        id: "hidar_tsion_$year",
        titleAmharic: "ኅዳር ጽዮን (ቅድስት ማርያም)",
        titleEnglish: "Hidar Tsion (St Mary of Zion)",
        titleOromo: "Hidara Xi'oon",
        titleTigrinya: "ኅዳር ጽዮን",
        ethiopianDate: EthiopianDate(year, 3, 21),
        type: HolidayType.orthodoxMajor,
        description: "Major feast of Our Lady Mary of Zion, celebrated widely including at Axum.",
        isPublicHoliday: false,
      ),
      Holiday(
        id: "kulubi_gabriel_$year",
        titleAmharic: "ቁልቢ ገብርኤል",
        titleEnglish: "Kulubi Gabriel",
        titleOromo: "Qulubii Gabrael",
        titleTigrinya: "ቁልቢ ገብርኤል",
        ethiopianDate: EthiopianDate(year, 4, 19),
        type: HolidayType.orthodoxMajor,
        description: "Great pilgrimage feast of Archangel Gabriel at Kulubi, East Hararghe.",
        isPublicHoliday: false,
      ),
      Holiday(
        id: "lideta_mary_$year",
        titleAmharic: "ልደታ ለማርያም",
        titleEnglish: "Lideta (Nativity of St Mary)",
        titleOromo: "Lidataa Marinyaam",
        titleTigrinya: "ልደታ ማርያም",
        ethiopianDate: EthiopianDate(year, 9, 1),
        type: HolidayType.orthodoxMajor,
        description: "Feast of the Nativity of the Virgin Mary (Ginbot 1).",
        isPublicHoliday: false,
      ),
      Holiday(
        id: "debre_tabor_$year",
        titleAmharic: "ደብረ ታቦር (የጌታ መለወጥ)",
        titleEnglish: "Debre Tabor (Transfiguration)",
        titleOromo: "Dabra Taabor",
        titleTigrinya: "ደብረ ታቦር",
        ethiopianDate: EthiopianDate(year, 12, 13),
        type: HolidayType.orthodoxMajor,
        description: "Feast of the Transfiguration of Christ on Mount Tabor (Nehasse 13).",
        isPublicHoliday: false,
      ),
      Holiday(
        id: "filseta_feast_$year",
        titleAmharic: "ፍልሰታ (ዕርገተ ማርያም)",
        titleEnglish: "Filseta (Assumption of St Mary)",
        titleOromo: "Filsetaa",
        titleTigrinya: "ፍልሰታ",
        ethiopianDate: EthiopianDate(year, 12, 16),
        type: HolidayType.orthodoxMajor,
        description: "Feast of the Assumption of the Virgin Mary, closing the Filseta fast (Nehasse 16).",
        isPublicHoliday: false,
      ),
      Holiday(
        id: "buhe_$year",
        titleAmharic: "ቡሄ",
        titleEnglish: "Buhe",
        titleOromo: "Buhee",
        titleTigrinya: "ቡሄ",
        ethiopianDate: EthiopianDate(year, 12, 19),
        type: HolidayType.culturalRegional,
        description: "Traditional children's festival with songs and roasted grain, linked to the Transfiguration season.",
        isPublicHoliday: false,
      ),
      Holiday(
        id: "tekle_haymanot_$year",
        titleAmharic: "አቡነ ተክለ ሃይማኖት",
        titleEnglish: "Abune Tekle Haymanot",
        titleOromo: "Abbaa Takla Haaymaanoot",
        titleTigrinya: "ኣቡነ ተክለ ሃይማኖት",
        ethiopianDate: EthiopianDate(year, 12, 24),
        type: HolidayType.orthodoxMajor,
        description: "Annual feast of Abune Tekle Haymanot, founder of Debre Libanos.",
        isPublicHoliday: false,
      ),
      Holiday(
        id: "st_michael_sene_$year",
        titleAmharic: "ቅዱስ ሚካኤል (ሰኔ)",
        titleEnglish: "St Michael (Sene)",
        titleOromo: "Qulqulluu Mikaa'el (Sanee)",
        titleTigrinya: "ቅዱስ ሚካኤል (ሰኔ)",
        ethiopianDate: EthiopianDate(year, 10, 12),
        type: HolidayType.orthodoxMajor,
        description: "Major annual feast of Archangel Michael in Sene.",
        isPublicHoliday: false,
      ),
      Holiday(
        id: "st_george_miazia_$year",
        titleAmharic: "ቅዱስ ጊዮርጊስ",
        titleEnglish: "St George",
        titleOromo: "Qulqulluu Giyorgis",
        titleTigrinya: "ቅዱስ ጊዮርጊስ",
        ethiopianDate: EthiopianDate(year, 8, 23),
        type: HolidayType.orthodoxMajor,
        description: "Feast of St George the Martyr (Miazia 23), widely celebrated across Ethiopia.",
        isPublicHoliday: false,
      ),
      Holiday(
        id: "epiphany_eve_$year",
        titleAmharic: "የጥምቀት ዋዜማ (ጋድ)",
        titleEnglish: "Timket Eve (Gahad)",
        titleOromo: "Halkan Cuuphaa",
        titleTigrinya: "ዋዜማ ጥምቀት",
        ethiopianDate: EthiopianDate(year, 5, 10),
        type: HolidayType.orthodoxMajor,
        description: "Eve vigil before Timket, when tabots process to the baptismal pool.",
        isPublicHoliday: false,
        isFasting: true,
      ),
      Holiday(
        id: "eve_genna_$year",
        titleAmharic: "የገና ዋዜማ (ጋድ)",
        titleEnglish: "Genna Eve (Gahad)",
        titleOromo: "Halkan Gannaa",
        titleTigrinya: "ዋዜማ ገና",
        ethiopianDate: EthiopianDate(year, 4, gennaDay(year) - 1),
        type: HolidayType.orthodoxMajor,
        description: "Christmas Eve vigil before Genna celebrations.",
        isPublicHoliday: false,
        isFasting: true,
      ),
      Holiday(
        id: "pagume_new_year_eve_$year",
        titleAmharic: "የአዲስ ዓመት ዋዜማ",
        titleEnglish: "New Year's Eve (Pagumen)",
        titleOromo: "Halkan Bara Haaraa",
        titleTigrinya: "ዋዜማ ሓድሽ ዓመት",
        ethiopianDate: EthiopianDate(
          year,
          13,
          EthiopianDate.isLeapYearFor(year) ? 6 : 5,
        ),
        type: HolidayType.culturalRegional,
        description: "Last day of Pagumen, eve of Enkutatash (Ethiopian New Year).",
        isPublicHoliday: false,
      ),
    ];
  }

  static FastingStatus isFastingDay(EthiopianDate date) {
    final dow = EthiopianCalendarEngine.getDayOfWeek(date);
    final bh = BahireHasab.calculate(date.year);

    final dateJdn = EthiopianCalendarEngine.ethiopianToJdn(date);
    final easter = bh.movableFeasts.where((f) => f.nameEnglish.contains("Easter")).firstOrNull;
    final pentecost = bh.movableFeasts.where((f) => f.nameEnglish.contains("Pentecost")).firstOrNull;

    // The feasts of the Nativity (Genna) and Epiphany (Timket) are never fast
    // days, even on a Wednesday or Friday; that fast is kept on the eve (ጋድ).
    if (date.month == 4 && date.day == gennaDay(date.year)) {
      return const FastingStatus(isFasting: false, reason: "የልደት በዓል (Feast of the Nativity - No Fasting)");
    }
    if (date.month == 5 && date.day == 11) {
      return const FastingStatus(isFasting: false, reason: "የጥምቀት በዓል (Feast of Epiphany - No Fasting)");
    }

    // Fiseha 50 (ሃምሳ ፌስሐ): 50 days between Easter and Pentecost are NOT fast days
    if (easter != null && pentecost != null) {
      final easterJdn = EthiopianCalendarEngine.ethiopianToJdn(easter.ethiopianDate);
      final pentecostJdn = EthiopianCalendarEngine.ethiopianToJdn(pentecost.ethiopianDate);
      if (dateJdn >= easterJdn && dateJdn <= pentecostJdn) {
        return const FastingStatus(isFasting: false, reason: "የሃምሳ ፌስሐ (Fifty Days of Joy - No Fasting)");
      }
    }

    // 1. Great Lent (ዓቢይ ጾም): 55 days ending on Holy Saturday eve
    final lentStart = bh.movableFeasts.where((f) => f.nameEnglish.contains("Great Lent")).firstOrNull;
    if (lentStart != null && easter != null) {
      final lentJdn = EthiopianCalendarEngine.ethiopianToJdn(lentStart.ethiopianDate);
      final easterJdn = EthiopianCalendarEngine.ethiopianToJdn(easter.ethiopianDate);
      if (dateJdn >= lentJdn && dateJdn < easterJdn) {
        return const FastingStatus(isFasting: true, reason: "ዓቢይ ጾም (Great Lent / Hudade)");
      }
    }

    // 2. Fast of Nineveh (ጾመ ነነዌ): 3 days
    final neneweJdn = EthiopianCalendarEngine.ethiopianToJdn(bh.nenewe);
    if (dateJdn >= neneweJdn && dateJdn <= (neneweJdn + 2)) {
      return const FastingStatus(isFasting: true, reason: "ጾመ ነነዌ (Fast of Nineveh)");
    }

    // 3. Fast of the Prophets (ጾመ ነቢያት): Hidar 15 up to Genna (handled above)
    final adventEndDay = gennaDay(date.year);
    if ((date.month == 3 && date.day >= 15) || (date.month == 4 && date.day <= adventEndDay)) {
      return const FastingStatus(isFasting: true, reason: "ጾመ ነቢያት (Fast of the Prophets / Advent)");
    }

    // 4. Filseta (ጾመ ፍልሰታ): Nehase 1 to Nehase 16
    if (date.month == 12 && date.day >= 1 && date.day <= 16) {
      return const FastingStatus(isFasting: true, reason: "ጾመ ፍልሰታ (Fast of the Assumption)");
    }

    // 5. Apostles Fast (ጾመ ሐዋርያት): Monday after Pentecost until Hamle 5
    final apostlesStart = bh.movableFeasts.where((f) => f.nameEnglish.contains("Fast of the Apostles")).firstOrNull;
    if (apostlesStart != null) {
      final apStartJdn = EthiopianCalendarEngine.ethiopianToJdn(apostlesStart.ethiopianDate);
      final apEndJdn = EthiopianCalendarEngine.ethiopianToJdn(EthiopianDate(date.year, 11, 5));
      if (dateJdn >= apStartJdn && dateJdn <= apEndJdn) {
        return const FastingStatus(isFasting: true, reason: "ጾመ ሐዋርያት (Fast of the Apostles / የሰኔ ጾም)");
      }
    }

    // 6. Weekly Fasting: Wednesday (ረቡዕ = 3) and Friday (ዓርብ = 5)
    if (dow == 3) {
      return const FastingStatus(isFasting: true, reason: "የረቡዕ ጾም (Wednesday Fast of Salvation)");
    }
    if (dow == 5) {
      return const FastingStatus(isFasting: true, reason: "የዓርብ ጾም (Friday Fast of the Crucifixion)");
    }

    return const FastingStatus(isFasting: false, reason: "ጾም የለም (Regular day)");
  }

  static List<CanonicalFast> getCanonicalFastsForYear(int year) {
    final bh = BahireHasab.calculate(year);
    final isLeap = EthiopianDate.isLeapYearFor(year);
    final list = <CanonicalFast>[];

    // 1. ጾመ ነቢያት (Fast of the Prophets / Advent) - 43 days
    final gennaDayOfTahsas = gennaDay(year);
    final adventStart = EthiopianDate(year, 3, 15);
    final adventEnd = EthiopianDate(year, 4, gennaDayOfTahsas);
    list.add(
      CanonicalFast(
        id: "fast_prophets_$year",
        nameAmharic: "ጾመ ነቢያት (የገና ጾም)",
        nameEnglish: "Fast of the Prophets (Advent)",
        nameOromo: "Sooma Raajotaa",
        nameTigrinya: "ጾመ ነብያት",
        durationDays: 43,
        startDate: adventStart,
        endDate: adventEnd,
        significance: "Commemorates the holy prophets who longed for, prayed, and prophesied the Incarnation of Christ.",
        dietaryRules: "Strict vegan diet (no meat, dairy, or eggs). Fasting daily until 3:00 PM.",
        biblicalFoundation: "Isaiah 7:14; Micah 5:2",
      ),
    );

    // 2. ጾመ ጋድ (Gahad Fast of Genna & Timket)
    list.add(
      CanonicalFast(
        id: "fast_gahad_$year",
        nameAmharic: "ጾመ ጋድ (የልደትና ጥምቀት ዋዜማ)",
        nameEnglish: "Gahad Fast (Christmas & Epiphany Eves)",
        nameOromo: "Sooma Gaad",
        nameTigrinya: "ጾመ ጋድ",
        durationDays: 2,
        startDate: EthiopianDate(year, 4, gennaDayOfTahsas - 1),
        endDate: EthiopianDate(year, 5, 10),
        significance: "Strict vigils observed on the eves of Christmas and Epiphany before midnight celebrations.",
        dietaryRules: "Complete fasting until the evening liturgy and Holy Communion.",
        biblicalFoundation: "Luke 2:7; Matthew 3:13",
      ),
    );

    // 3. ጾመ ነነዌ (Fast of Nineveh) - 3 days
    final neneweStart = bh.nenewe;
    final neneweEndJdn = EthiopianCalendarEngine.ethiopianToJdn(neneweStart) + 2;
    final neneweEnd = EthiopianCalendarEngine.jdnToEthiopian(neneweEndJdn);
    list.add(
      CanonicalFast(
        id: "fast_nineveh_$year",
        nameAmharic: "ጾመ ነነዌ (የነነዌ ጾም)",
        nameEnglish: "Fast of Nineveh",
        nameOromo: "Sooma Nannawwee",
        nameTigrinya: "ጾመ ነነዌ",
        durationDays: 3,
        startDate: neneweStart,
        endDate: neneweEnd,
        significance: "Remembrance of the repentance of the citizens of Nineveh following Prophet Jonah's preaching.",
        dietaryRules: "Strict fasting from sunrise to 3:00 PM or dusk, followed by a purely vegan meal.",
        biblicalFoundation: "Jonah 3:5-10",
      ),
    );

    // 4. ዓቢይ ጾም / ሁዳዴ (Great Lent) - 55 days
    final lentStart = bh.movableFeasts.where((f) => f.nameEnglish.contains("Great Lent")).firstOrNull?.ethiopianDate ?? BahireHasab.abiyTsom(year);
    final easter = bh.movableFeasts.where((f) => f.nameEnglish.contains("Easter")).firstOrNull?.ethiopianDate ?? BahireHasab.fasika(year);
    final lentEndJdn = EthiopianCalendarEngine.ethiopianToJdn(easter) - 1;
    final lentEnd = EthiopianCalendarEngine.jdnToEthiopian(lentEndJdn);
    list.add(
      CanonicalFast(
        id: "fast_great_lent_$year",
        nameAmharic: "ዓቢይ ጾም (ሁዳዴ)",
        nameEnglish: "Great Lent (Hudade)",
        nameOromo: "Sooma Guddaa (Hudaadee)",
        nameTigrinya: "ዓቢይ ጾም",
        durationDays: 55,
        startDate: lentStart,
        endDate: lentEnd,
        significance: "The 55-day fast honoring Christ's 40-day wilderness fast, culminating in Holy Week (Himamat).",
        dietaryRules: "Strict abstinence from all animal products. Fasting until 3:00 PM daily; sunset during Holy Week.",
        biblicalFoundation: "Matthew 4:1-2; Mark 1:12-13",
      ),
    );

    // 5. ጾመ ሐዋርያት (Fast of the Apostles - የሰኔ ጾም)
    final apostlesStart = bh.movableFeasts.where((f) => f.nameEnglish.contains("Fast of the Apostles")).firstOrNull?.ethiopianDate ?? BahireHasab.tsomeHawaryat(year);
    final apostlesEnd = EthiopianDate(year, 11, 5); // Hamle 5
    final apostlesDuration = BahireHasab.apostlesFastDuration(year);
    list.add(
      CanonicalFast(
        id: "fast_apostles_$year",
        nameAmharic: "ጾመ ሐዋርያት (የሰኔ ጾም)",
        nameEnglish: "Fast of the Apostles",
        nameOromo: "Sooma Ergamootaa",
        nameTigrinya: "ጾመ ሃዋርያት",
        durationDays: apostlesDuration,
        startDate: apostlesStart,
        endDate: apostlesEnd,
        significance: "Follows Pentecost, honoring the Apostles who fasted before proclaiming the Gospel across the nations.",
        dietaryRules: "Vegan diet, abstinence from dairy and meat, daily fasting until 3:00 PM.",
        biblicalFoundation: "Acts 13:2-3; Matthew 9:15",
      ),
    );

    // 6. ጾመ ድኅነት (Fast of Salvation - ረቡዕ እና ዓርብ)
    list.add(
      CanonicalFast(
        id: "fast_salvation_$year",
        nameAmharic: "ጾመ ድኅነት (የረቡዕና ዓርብ ጾም)",
        nameEnglish: "Fast of Salvation (Wed & Fri)",
        nameOromo: "Sooma Fayyinaa (Roobii fi Jimmata)",
        nameTigrinya: "ጾመ ድሕነት (ረቡዕን ዓርብን)",
        durationDays: 104,
        startDate: EthiopianDate(year, 1, 1),
        endDate: EthiopianDate(year, 13, isLeap ? 6 : 5),
        significance: "Observed every Wednesday (Betrayal by Judas) and Friday (Crucifixion), except the 50 Days of Joy.",
        dietaryRules: "Abstaining from all meat, fish, and dairy; fasting until 3:00 PM.",
        biblicalFoundation: "Zechariah 8:19; Didache 8:1",
      ),
    );

    // 7. ጾመ ፍልሰታ (Fast of the Assumption) - 16 days
    list.add(
      CanonicalFast(
        id: "fast_filseta_$year",
        nameAmharic: "ጾመ ፍልሰታ ለማርያም",
        nameEnglish: "Fast of the Assumption (Filseta)",
        nameOromo: "Sooma Baqannaa Maariyaam",
        nameTigrinya: "ጾመ ፍልሰታ",
        durationDays: 16,
        startDate: EthiopianDate(year, 12, 1),
        endDate: EthiopianDate(year, 12, 16),
        significance: "16 days commemorating the bodily Assumption of the Blessed Virgin Mary into Heaven.",
        dietaryRules: "Strict veganism accompanied by devout prayers, prostrations, and holy liturgy.",
        biblicalFoundation: "Psalm 45:9; Revelation 12:1",
      ),
    );

    return list;
  }

  static DetailedFastingInfo getDetailedFastingInfo(EthiopianDate date) {
    final basic = isFastingDay(date);
    final bh = BahireHasab.calculate(date.year);
    final dateJdn = EthiopianCalendarEngine.ethiopianToJdn(date);

    final easter = bh.movableFeasts.where((f) => f.nameEnglish.contains("Easter")).firstOrNull;
    final pentecost = bh.movableFeasts.where((f) => f.nameEnglish.contains("Pentecost")).firstOrNull;
    if (easter != null && pentecost != null) {
      final easterJdn = EthiopianCalendarEngine.ethiopianToJdn(easter.ethiopianDate);
      final pentecostJdn = EthiopianCalendarEngine.ethiopianToJdn(pentecost.ethiopianDate);
      if (dateJdn >= easterJdn && dateJdn <= pentecostJdn) {
        return const DetailedFastingInfo(
          isFasting: false,
          seasonNameAmharic: "የሃምሳ ፌስሐ (Fifty Days of Joy)",
          seasonNameEnglish: "Fifty Days of Joy (Pentecost Season)",
          fastingLevel: "No Fasting Allowed (በዓለ ፌስሐ)",
          description: "Fifty glorious days celebrating the Resurrection and Ascension of Christ. Fasting is prohibited.",
        );
      }
    }

    if (basic.isFasting) {
      final level = basic.reason.contains("ዓቢይ ጾም") || basic.reason.contains("ነነዌ")
          ? "Strict Fasting until 3:00 PM (Vegan only)"
          : "Fasting until 3:00 PM (Abstaining from meat & dairy)";
      return DetailedFastingInfo(
        isFasting: true,
        seasonNameAmharic: basic.reason,
        seasonNameEnglish: "Orthodox Fasting Day",
        fastingLevel: level,
        description: "Abstaining from all animal products in prayer, repentance, and communion with God.",
      );
    } else {
      return const DetailedFastingInfo(
        isFasting: false,
        seasonNameAmharic: "ጾም የለም (Regular Day)",
        seasonNameEnglish: "Regular Day (Non-Fasting)",
        fastingLevel: "No fasting restriction",
        description: "Regular non-fasting day. Food may be enjoyed according to customary practices.",
      );
    }
  }

  static int _hijriToJdn(int hYear, int hMonth, int hDay) {
    final monthDays = (29.5 * (hMonth - 1)).ceil();
    final yearDays = (hYear - 1) * 354 + ((3 + 11 * hYear) ~/ 30);
    return hDay + monthDays + yearDays + 1948439;
  }

  static int _jdnToHijriYear(int jdn) {
    final days = jdn - 1948440 + 10632;
    final cycle = days ~/ 10631;
    final rem = days % 10631;
    return (cycle * 30 + ((rem * 30 + 14) ~/ 10631) - 29);
  }

  static List<Holiday> _calculateIslamicHolidaysForYear(int year) {
    final list = <Holiday>[];
    final ethYearStartJdn = EthiopianCalendarEngine.ethiopianToJdn(EthiopianDate(year, 1, 1));
    final daysInYear = EthiopianDate.isLeapYearFor(year) ? 366 : 365;
    final ethYearEndJdn = ethYearStartJdn + daysInYear - 1;

    final startHijriYear = _jdnToHijriYear(ethYearStartJdn) - 1;
    final endHijriYear = _jdnToHijriYear(ethYearEndJdn) + 1;

    for (int hYear = startHijriYear; hYear <= endHijriYear; hYear++) {
      // 1. Mawlid (12 Rabi' al-Awwal = Month 3, Day 12)
      final mawlidJdn = _hijriToJdn(hYear, 3, 12);
      if (mawlidJdn >= ethYearStartJdn && mawlidJdn <= ethYearEndJdn) {
        final mawlidDate = EthiopianCalendarEngine.jdnToEthiopian(mawlidJdn);
        list.add(
          Holiday(
            id: "mawlid_${hYear}_$year",
            titleAmharic: "መውሊድ (የነቢዩ መሐመድ ልደት)",
            titleEnglish: "Mawlid an-Nabi ($hYear AH)",
            titleOromo: "Ayyaana Mawliidaa",
            titleTigrinya: "መውሊድ",
            ethiopianDate: mawlidDate,
            type: HolidayType.islamic,
            description: "Commemoration of the birth of Prophet Muhammad ($hYear AH), observed across Ethiopian Muslim communities.",
            isPublicHoliday: true,
          ),
        );
      }

      // 2. Ramadan Start (1 Ramadan = Month 9, Day 1)
      final ramadanJdn = _hijriToJdn(hYear, 9, 1);
      if (ramadanJdn >= ethYearStartJdn && ramadanJdn <= ethYearEndJdn) {
        final ramadanDate = EthiopianCalendarEngine.jdnToEthiopian(ramadanJdn);
        list.add(
          Holiday(
            id: "ramadan_${hYear}_$year",
            titleAmharic: "የረመዳን መጀመሪያ",
            titleEnglish: "Start of Ramadan ($hYear AH)",
            titleOromo: "Jalqaba Sooma Ramadaanaa",
            titleTigrinya: "መጀመርታ ረመዳን",
            ethiopianDate: ramadanDate,
            type: HolidayType.islamic,
            description: "Beginning of the holy fasting month of Ramadan for the year $hYear AH.",
            isPublicHoliday: false,
            isFasting: true,
          ),
        );
      }

      // 3. Eid al-Fitr (1 Shawwal = Month 10, Day 1)
      final eidFitrJdn = _hijriToJdn(hYear, 10, 1);
      if (eidFitrJdn >= ethYearStartJdn && eidFitrJdn <= ethYearEndJdn) {
        final eidFitrDate = EthiopianCalendarEngine.jdnToEthiopian(eidFitrJdn);
        list.add(
          Holiday(
            id: "eid_fitr_${hYear}_$year",
            titleAmharic: "ዒድ አል-ፊጥር (የጾም መፍቻ በዓል)",
            titleEnglish: "Eid al-Fitr ($hYear AH)",
            titleOromo: "Ayyaana Iid Al-Fixrii",
            titleTigrinya: "ዒድ አል-ፊጥር",
            ethiopianDate: eidFitrDate,
            type: HolidayType.islamic,
            description: "Celebration concluding the holy month of Ramadan ($hYear AH), marked with prayers, family feasts, and charity.",
            isPublicHoliday: true,
          ),
        );
      }

      // 4. Eid al-Adha / Arafa (10 Dhu al-Hijjah = Month 12, Day 10)
      final eidAdhaJdn = _hijriToJdn(hYear, 12, 10);
      if (eidAdhaJdn >= ethYearStartJdn && eidAdhaJdn <= ethYearEndJdn) {
        final eidAdhaDate = EthiopianCalendarEngine.jdnToEthiopian(eidAdhaJdn);
        list.add(
          Holiday(
            id: "eid_adha_${hYear}_$year",
            titleAmharic: "ዒድ አል-አድሃ (አረፋ)",
            titleEnglish: "Eid al-Adha / Arafa ($hYear AH)",
            titleOromo: "Ayyaana Iid Al-Adhaa (Arafa)",
            titleTigrinya: "ዒድ አል-አድሓ (ዓረፋ)",
            ethiopianDate: eidAdhaDate,
            type: HolidayType.islamic,
            description: "Feast of the Sacrifice ($hYear AH) commemorating Ibrahim's devotion, also concluding the annual Hajj pilgrimage.",
            isPublicHoliday: true,
          ),
        );
      }
    }

    return list;
  }
}
