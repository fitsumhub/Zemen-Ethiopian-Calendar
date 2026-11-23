import 'dart:math' as math;
import '../calendar/ethiopian_calendar_engine.dart';
import '../calendar/ethiopian_date.dart';
import '../calendar/gregorian_date.dart';

enum WorldRegion {
  all('All Cities', 'ሁሉም ከተሞች'),
  europe('🇪🇺 Europe', 'አውሮፓ'),
  americas('🌎 Americas', 'አሜሪካ'),
  middleEast('🇸🇦 Middle East', 'መካከለኛው ምስራቅ'),
  asiaOceania('🌏 Asia & Pacific', 'እስያ እና ፓሲፊክ'),
  africa('🌍 Africa', 'አፍሪካ');

  final String labelEn;
  final String labelAm;

  const WorldRegion(this.labelEn, this.labelAm);
}

enum BusinessStatus {
  open('🟢 Business Hours (Open)', 0xFF10B981),
  leisure('🟡 Morning / Evening (Active)', 0xFFF59E0B),
  sleeping('🌙 Night / Sleeping', 0xFF6B7280);

  final String label;
  final int colorHex;

  const BusinessStatus(this.label, this.colorHex);
}

class WorldCity {
  final String id;
  final String cityEn;
  final String cityAm;
  final String countryEn;
  final String countryAm;
  final String flag;
  final String timeZoneId;
  final WorldRegion region;
  final String dialCode;
  final String currency;
  final double utcOffsetHours;
  final String standardTzAbbr;

  const WorldCity({
    required this.id,
    required this.cityEn,
    required this.cityAm,
    required this.countryEn,
    required this.countryAm,
    required this.flag,
    required this.timeZoneId,
    required this.region,
    required this.dialCode,
    required this.currency,
    required this.utcOffsetHours,
    required this.standardTzAbbr,
  });
}

class WorldCityTimeResult {
  final WorldCity city;
  final int hour24;
  final int minute;
  final int hour12;
  final bool isPm;
  final String timeZoneAbbreviation;
  final double rawOffsetHours;
  final double differenceFromAddisHours;
  final int dayOffset; // -1 = yesterday, 0 = same day, +1 = tomorrow
  final BusinessStatus businessStatus;
  final String formattedTime12;
  final String formattedTime24;

  const WorldCityTimeResult({
    required this.city,
    required this.hour24,
    required this.minute,
    required this.hour12,
    required this.isPm,
    required this.timeZoneAbbreviation,
    required this.rawOffsetHours,
    required this.differenceFromAddisHours,
    required this.dayOffset,
    required this.businessStatus,
    required this.formattedTime12,
    required this.formattedTime24,
  });

  // UI-compat aliases mirroring Kotlin WorldCityTimeResult field names.
  String get flag => city.flag;
  String get cityNameAmharic => city.cityAm;
  String get cityNameEnglish => city.cityEn;
  String get countryName => city.countryEn;
  bool get isBusinessHours => businessStatus == BusinessStatus.open;
  String get formattedTime => formattedTime12;
  String get formattedOffset {
    final sign = differenceFromAddisHours >= 0 ? '+' : '';
    final hours = differenceFromAddisHours == differenceFromAddisHours.roundToDouble()
        ? differenceFromAddisHours.toInt().toString()
        : differenceFromAddisHours.toStringAsFixed(1);
    final day = dayOffset == 0
        ? ''
        : dayOffset > 0
            ? ' (+${dayOffset}d)'
            : ' (${dayOffset}d)';
    return 'EAT$sign${hours}h$day';
  }
}

class EuropeanCalendarResult {
  final String gregorianFormattedEu; // 14.11.2026
  final String gregorianFormattedUk; // 14/11/2026
  final String gregorianFormattedDe; // 14. November 2026
  final String gregorianFormattedFr; // 14/11/2026
  final String gregorianFormattedUs; // 11/14/2026
  final String iso8601; // 2026-11-14
  final String julianDateStr;
  final int julianYear;
  final int julianMonth;
  final int julianDay;
  final String copticDateStr;
  final int copticYear;
  final String copticMonthName;
  final int copticDay;
  final String hijriDateStr;
  final String europeanSeasonEn;
  final String europeanSeasonAm;
  final String europeanSeasonEmoji;
  final String europeanQuarter;
  final int dayOfYear;
  final int weekOfYear;
  final bool isEuropeanWeekend;
  final bool isEthiopianWeekend;
  final String yearOffsetExplanation;

  const EuropeanCalendarResult({
    required this.gregorianFormattedEu,
    required this.gregorianFormattedUk,
    required this.gregorianFormattedDe,
    required this.gregorianFormattedFr,
    required this.gregorianFormattedUs,
    required this.iso8601,
    required this.julianDateStr,
    required this.julianYear,
    required this.julianMonth,
    required this.julianDay,
    required this.copticDateStr,
    required this.copticYear,
    required this.copticMonthName,
    required this.copticDay,
    required this.hijriDateStr,
    required this.europeanSeasonEn,
    required this.europeanSeasonAm,
    required this.europeanSeasonEmoji,
    required this.europeanQuarter,
    required this.dayOfYear,
    required this.weekOfYear,
    required this.isEuropeanWeekend,
    required this.isEthiopianWeekend,
    required this.yearOffsetExplanation,
  });

  // UI-compat aliases
  ({int day, int month, int year}) get julianDate =>
      (day: julianDay, month: julianMonth, year: julianYear);

  int get hijriYear {
    final match = RegExp(r'(\d+)\s+AH').firstMatch(hijriDateStr);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  int get hijriDay {
    final match = RegExp(r'^(\d+)').firstMatch(hijriDateStr.trim());
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  String get hijriMonthName {
    final match = RegExp(r'^\d+\s+(.+?)\s+\d+\s+AH').firstMatch(hijriDateStr.trim());
    return match?.group(1)?.trim() ?? hijriDateStr;
  }
}

class CountryProfile {
  final String id;
  final String nameEn;
  final String nameAm;
  final String capitalEn;
  final String flag;
  final String region;
  final String timeZoneId;
  final String timeZoneName;
  final String dialCode;
  final String currencyName;
  final String currencySymbol;
  final String dateFormatExample;
  final String workweek;
  final String businessHours;
  final String callingRecommendationFromAddis;
  final String holidayDifferences;
  final String seasonDifference;

  const CountryProfile({
    required this.id,
    required this.nameEn,
    required this.nameAm,
    required this.capitalEn,
    required this.flag,
    required this.region,
    required this.timeZoneId,
    required this.timeZoneName,
    required this.dialCode,
    required this.currencyName,
    required this.currencySymbol,
    required this.dateFormatExample,
    required this.workweek,
    required this.businessHours,
    required this.callingRecommendationFromAddis,
    required this.holidayDifferences,
    required this.seasonDifference,
  });
}

class WorldCountryEngine {
  static const List<WorldCity> worldCities = [
    WorldCity(id: "lon", cityEn: "London", cityAm: "ለንደን", countryEn: "United Kingdom", countryAm: "እንግሊዝ", flag: "🇬🇧", timeZoneId: "Europe/London", region: WorldRegion.europe, dialCode: "+44", currency: "GBP (£)", utcOffsetHours: 0.0, standardTzAbbr: "GMT"),
    WorldCity(id: "ber", cityEn: "Berlin", cityAm: "በርሊን", countryEn: "Germany", countryAm: "ጀርመን", flag: "🇩🇪", timeZoneId: "Europe/Berlin", region: WorldRegion.europe, dialCode: "+49", currency: "EUR (€)", utcOffsetHours: 1.0, standardTzAbbr: "CET"),
    WorldCity(id: "par", cityEn: "Paris", cityAm: "ፓሪስ", countryEn: "France", countryAm: "ፈረንሳይ", flag: "🇫🇷", timeZoneId: "Europe/Paris", region: WorldRegion.europe, dialCode: "+33", currency: "EUR (€)", utcOffsetHours: 1.0, standardTzAbbr: "CET"),
    WorldCity(id: "rom", cityEn: "Rome", cityAm: "ሮም", countryEn: "Italy", countryAm: "ጣሊያን", flag: "🇮🇹", timeZoneId: "Europe/Rome", region: WorldRegion.europe, dialCode: "+39", currency: "EUR (€)", utcOffsetHours: 1.0, standardTzAbbr: "CET"),
    WorldCity(id: "sto", cityEn: "Stockholm", cityAm: "ስቶክሆልም", countryEn: "Sweden", countryAm: "ስዊድን", flag: "🇸🇪", timeZoneId: "Europe/Stockholm", region: WorldRegion.europe, dialCode: "+46", currency: "SEK (kr)", utcOffsetHours: 1.0, standardTzAbbr: "CET"),
    WorldCity(id: "ams", cityEn: "Amsterdam", cityAm: "አምስተርዳም", countryEn: "Netherlands", countryAm: "ኔዘርላንድስ", flag: "🇳🇱", timeZoneId: "Europe/Amsterdam", region: WorldRegion.europe, dialCode: "+31", currency: "EUR (€)", utcOffsetHours: 1.0, standardTzAbbr: "CET"),
    WorldCity(id: "zur", cityEn: "Zurich", cityAm: "ዙሪክ", countryEn: "Switzerland", countryAm: "ስዊዘርላንድ", flag: "🇨🇭", timeZoneId: "Europe/Zurich", region: WorldRegion.europe, dialCode: "+41", currency: "CHF (Fr)", utcOffsetHours: 1.0, standardTzAbbr: "CET"),
    WorldCity(id: "bru", cityEn: "Brussels", cityAm: "ብራሰልስ", countryEn: "Belgium", countryAm: "ቤልጂየም", flag: "🇧🇪", timeZoneId: "Europe/Brussels", region: WorldRegion.europe, dialCode: "+32", currency: "EUR (€)", utcOffsetHours: 1.0, standardTzAbbr: "CET"),
    WorldCity(id: "ath", cityEn: "Athens", cityAm: "አቴንስ", countryEn: "Greece", countryAm: "ግሪክ", flag: "🇬🇷", timeZoneId: "Europe/Athens", region: WorldRegion.europe, dialCode: "+30", currency: "EUR (€)", utcOffsetHours: 2.0, standardTzAbbr: "EET"),
    WorldCity(id: "hel", cityEn: "Helsinki", cityAm: "ሄልሲንኪ", countryEn: "Finland", countryAm: "ፊንላንድ", flag: "🇫🇮", timeZoneId: "Europe/Helsinki", region: WorldRegion.europe, dialCode: "+358", currency: "EUR (€)", utcOffsetHours: 2.0, standardTzAbbr: "EET"),
    WorldCity(id: "mos", cityEn: "Moscow", cityAm: "ሞስኮ", countryEn: "Russia", countryAm: "ሩሲያ", flag: "🇷🇺", timeZoneId: "Europe/Moscow", region: WorldRegion.europe, dialCode: "+7", currency: "RUB (₽)", utcOffsetHours: 3.0, standardTzAbbr: "MSK"),

    // Americas
    WorldCity(id: "was", cityEn: "Washington D.C.", cityAm: "ዋሽንግተን ዲሲ", countryEn: "United States", countryAm: "አሜሪካ", flag: "🇺🇸", timeZoneId: "America/New_York", region: WorldRegion.americas, dialCode: "+1", currency: "USD (\$)", utcOffsetHours: -5.0, standardTzAbbr: "EST"),
    WorldCity(id: "nyc", cityEn: "New York", cityAm: "ኒው ዮርክ", countryEn: "United States", countryAm: "አሜሪካ", flag: "🇺🇸", timeZoneId: "America/New_York", region: WorldRegion.americas, dialCode: "+1", currency: "USD (\$)", utcOffsetHours: -5.0, standardTzAbbr: "EST"),
    WorldCity(id: "lax", cityEn: "Los Angeles", cityAm: "ሎስ አንጀለስ", countryEn: "United States", countryAm: "አሜሪካ", flag: "🇺🇸", timeZoneId: "America/Los_Angeles", region: WorldRegion.americas, dialCode: "+1", currency: "USD (\$)", utcOffsetHours: -8.0, standardTzAbbr: "PST"),
    WorldCity(id: "tor", cityEn: "Toronto", cityAm: "ቶሮንቶ", countryEn: "Canada", countryAm: "ካናዳ", flag: "🇨🇦", timeZoneId: "America/Toronto", region: WorldRegion.americas, dialCode: "+1", currency: "CAD (\$)", utcOffsetHours: -5.0, standardTzAbbr: "EST"),

    // Middle East & Gulf
    WorldCity(id: "dxb", cityEn: "Dubai", cityAm: "ዱባይ", countryEn: "United Arab Emirates", countryAm: "የተባበሩት አረብ ኤምሬቶች", flag: "🇦🇪", timeZoneId: "Asia/Dubai", region: WorldRegion.middleEast, dialCode: "+971", currency: "AED (د.إ)", utcOffsetHours: 4.0, standardTzAbbr: "GST"),
    WorldCity(id: "ruh", cityEn: "Riyadh", cityAm: "ሪያድ", countryEn: "Saudi Arabia", countryAm: "ሳውዲ አረቢያ", flag: "🇸🇦", timeZoneId: "Asia/Riyadh", region: WorldRegion.middleEast, dialCode: "+966", currency: "SAR (﷼)", utcOffsetHours: 3.0, standardTzAbbr: "AST"),
    WorldCity(id: "doh", cityEn: "Doha", cityAm: "ዶሃ", countryEn: "Qatar", countryAm: "ኳታር", flag: "🇶🇦", timeZoneId: "Asia/Qatar", region: WorldRegion.middleEast, dialCode: "+974", currency: "QAR (﷼)", utcOffsetHours: 3.0, standardTzAbbr: "AST"),
    WorldCity(id: "kwi", cityEn: "Kuwait City", cityAm: "ኩዌት ሲቲ", countryEn: "Kuwait", countryAm: "ኩዌት", flag: "🇰🇼", timeZoneId: "Asia/Kuwait", region: WorldRegion.middleEast, dialCode: "+965", currency: "KWD (د.ك)", utcOffsetHours: 3.0, standardTzAbbr: "AST"),

    // Africa
    WorldCity(id: "cai", cityEn: "Cairo", cityAm: "ካይሮ", countryEn: "Egypt", countryAm: "ግብፅ", flag: "🇪🇬", timeZoneId: "Africa/Cairo", region: WorldRegion.africa, dialCode: "+20", currency: "EGP (E£)", utcOffsetHours: 2.0, standardTzAbbr: "EET"),
    WorldCity(id: "nbo", cityEn: "Nairobi", cityAm: "ናይሮቢ", countryEn: "Kenya", countryAm: "ኬንያ", flag: "🇰🇪", timeZoneId: "Africa/Nairobi", region: WorldRegion.africa, dialCode: "+254", currency: "KES (KSh)", utcOffsetHours: 3.0, standardTzAbbr: "EAT"),
    WorldCity(id: "jnb", cityEn: "Johannesburg", cityAm: "ጆሃንስበርግ", countryEn: "South Africa", countryAm: "ደቡብ አፍሪካ", flag: "🇿🇦", timeZoneId: "Africa/Johannesburg", region: WorldRegion.africa, dialCode: "+27", currency: "ZAR (R)", utcOffsetHours: 2.0, standardTzAbbr: "SAST"),

    // Asia & Oceania
    WorldCity(id: "syd", cityEn: "Sydney", cityAm: "ሲድኒ", countryEn: "Australia", countryAm: "አውስትራሊያ", flag: "🇦🇺", timeZoneId: "Australia/Sydney", region: WorldRegion.asiaOceania, dialCode: "+61", currency: "AUD (\$)", utcOffsetHours: 10.0, standardTzAbbr: "AEST"),
    WorldCity(id: "mel", cityEn: "Melbourne", cityAm: "ሜልበርን", countryEn: "Australia", countryAm: "አውስትራሊያ", flag: "🇦🇺", timeZoneId: "Australia/Melbourne", region: WorldRegion.asiaOceania, dialCode: "+61", currency: "AUD (\$)", utcOffsetHours: 10.0, standardTzAbbr: "AEST"),
    WorldCity(id: "tyo", cityEn: "Tokyo", cityAm: "ቶኪዮ", countryEn: "Japan", countryAm: "ጃፓን", flag: "🇯🇵", timeZoneId: "Asia/Tokyo", region: WorldRegion.asiaOceania, dialCode: "+81", currency: "JPY (¥)", utcOffsetHours: 9.0, standardTzAbbr: "JST"),
    WorldCity(id: "bjs", cityEn: "Beijing", cityAm: "ቤጂንግ", countryEn: "China", countryAm: "ቻይና", flag: "🇨🇳", timeZoneId: "Asia/Shanghai", region: WorldRegion.asiaOceania, dialCode: "+86", currency: "CNY (¥)", utcOffsetHours: 8.0, standardTzAbbr: "CST"),
  ];

  static const List<CountryProfile> countryProfiles = [
    CountryProfile(
      id: "de",
      nameEn: "Germany (Federal Republic)",
      nameAm: "ጀርመን",
      capitalEn: "Berlin",
      flag: "🇩🇪",
      region: "Central Europe",
      timeZoneId: "Europe/Berlin",
      timeZoneName: "CET (UTC+1) / CEST (UTC+2 in Summer)",
      dialCode: "+49",
      currencyName: "Euro",
      currencySymbol: "EUR (€)",
      dateFormatExample: "DD.MM.YYYY (e.g. 14.11.2026)",
      workweek: "Monday – Friday (40 hrs/wk). Saturday & Sunday closed.",
      businessHours: "08:30 – 17:00 CET",
      callingRecommendationFromAddis: "11:00 AM – 05:00 PM Addis Ababa time (corresponds to 09:00 AM – 03:00 PM in Germany).",
      holidayDifferences: "Western Christmas (Dec 25/26), German Unity Day (Oct 3). Ethiopian Genna (Jan 7) & Meskel are regular working days.",
      seasonDifference: "European Winter (Dec–Feb) is cold/snowy, while Ethiopia enjoys sunny Bega (dry harvest). European Summer (Jun–Aug) is warm, while Ethiopia has main rainy season (Kiremt).",
    ),
    CountryProfile(
      id: "uk",
      nameEn: "United Kingdom",
      nameAm: "እንግሊዝ / ብሪታንያ",
      capitalEn: "London",
      flag: "🇬🇧",
      region: "Western Europe",
      timeZoneId: "Europe/London",
      timeZoneName: "GMT (UTC+0) / BST (UTC+1 in Summer)",
      dialCode: "+44",
      currencyName: "British Pound Sterling",
      currencySymbol: "GBP (£)",
      dateFormatExample: "DD/MM/YYYY (e.g. 14/11/2026)",
      workweek: "Monday – Friday. Saturday & Sunday weekend.",
      businessHours: "09:00 – 17:30 GMT",
      callingRecommendationFromAddis: "12:00 PM – 06:00 PM Addis Ababa time (corresponds to 09:00 AM – 03:00 PM in London).",
      holidayDifferences: "Christmas (Dec 25), Boxing Day (Dec 26), Bank Holidays. Fiscal year starts April 6, whereas Ethiopian fiscal year starts Hamle 1 (July 8).",
      seasonDifference: "Temperate maritime climate. UK Spring (Mar–May) coincides with Ethiopian Belg.",
    ),
    CountryProfile(
      id: "fr",
      nameEn: "France",
      nameAm: "ፈረንሳይ",
      capitalEn: "Paris",
      flag: "🇫🇷",
      region: "Western Europe",
      timeZoneId: "Europe/Paris",
      timeZoneName: "CET (UTC+1) / CEST (UTC+2 in Summer)",
      dialCode: "+33",
      currencyName: "Euro",
      currencySymbol: "EUR (€)",
      dateFormatExample: "DD/MM/YYYY (e.g. 14/11/2026)",
      workweek: "Monday – Friday (35 hrs standard). Saturday & Sunday weekend.",
      businessHours: "09:00 – 18:00 CET",
      callingRecommendationFromAddis: "11:00 AM – 05:00 PM Addis Ababa time.",
      holidayDifferences: "Bastille Day (July 14), Assumption (Aug 15). Uses Gregorian calendar exclusively.",
      seasonDifference: "Four distinct European seasons with daylight saving time changes in late March and late October.",
    ),
    CountryProfile(
      id: "it",
      nameEn: "Italy",
      nameAm: "ጣሊያን",
      capitalEn: "Rome",
      flag: "🇮🇹",
      region: "Southern Europe",
      timeZoneId: "Europe/Rome",
      timeZoneName: "CET (UTC+1) / CEST (UTC+2 in Summer)",
      dialCode: "+39",
      currencyName: "Euro",
      currencySymbol: "EUR (€)",
      dateFormatExample: "DD/MM/YYYY (e.g. 14/11/2026)",
      workweek: "Monday – Friday. Saturday & Sunday weekend.",
      businessHours: "09:00 – 18:00 CET",
      callingRecommendationFromAddis: "11:00 AM – 05:00 PM Addis Ababa time.",
      holidayDifferences: "Ferragosto (Aug 15), Epifania (Jan 6 - one day before Ethiopian Genna).",
      seasonDifference: "Mediterranean climate. Ethiopian community in Rome/Milan celebrates Timket and Meskel with vibrant diaspora gatherings.",
    ),
    CountryProfile(
      id: "se",
      nameEn: "Sweden",
      nameAm: "ስዊድን",
      capitalEn: "Stockholm",
      flag: "🇸🇪",
      region: "Northern Europe (Scandinavia)",
      timeZoneId: "Europe/Stockholm",
      timeZoneName: "CET (UTC+1) / CEST (UTC+2 in Summer)",
      dialCode: "+46",
      currencyName: "Swedish Krona",
      currencySymbol: "SEK (kr)",
      dateFormatExample: "YYYY-MM-DD or DD.MM.YYYY",
      workweek: "Monday – Friday. Very strict family-friendly hours.",
      businessHours: "08:30 – 16:30 CET",
      callingRecommendationFromAddis: "10:30 AM – 04:30 PM Addis Ababa time.",
      holidayDifferences: "Midsummer (late June), Lucia (Dec 13). Long daylight hours in summer and short dark days in winter.",
      seasonDifference: "Subarctic/temperate climate with deep snow in winter contrasted with Ethiopia's highland subtropical warmth.",
    ),
    CountryProfile(
      id: "us",
      nameEn: "United States of America",
      nameAm: "አሜሪካ",
      capitalEn: "Washington D.C.",
      flag: "🇺🇸",
      region: "North America",
      timeZoneId: "America/New_York",
      timeZoneName: "EST (UTC-5) / EDT (UTC-4 in Summer)",
      dialCode: "+1",
      currencyName: "US Dollar",
      currencySymbol: "USD (\$)",
      dateFormatExample: "MM/DD/YYYY (e.g. 11/14/2026)",
      workweek: "Monday – Friday (40 hrs). Saturday & Sunday weekend.",
      businessHours: "09:00 – 17:00 EST",
      callingRecommendationFromAddis: "04:00 PM – 10:00 PM Addis Ababa time (corresponds to 09:00 AM – 03:00 PM US Eastern Time).",
      holidayDifferences: "Thanksgiving (4th Thursday of November), 4th of July, Memorial Day, Labor Day. Home to the largest Ethiopian diaspora globally (DC, California, Texas, Atlanta).",
      seasonDifference: "US fiscal year runs Oct 1 – Sep 30. Wide range of climate zones.",
    ),
    CountryProfile(
      id: "ca",
      nameEn: "Canada",
      nameAm: "ካናዳ",
      capitalEn: "Ottawa",
      flag: "🇨🇦",
      region: "North America",
      timeZoneId: "America/Toronto",
      timeZoneName: "EST (UTC-5) / EDT (UTC-4 in Summer)",
      dialCode: "+1",
      currencyName: "Canadian Dollar",
      currencySymbol: "CAD (\$)",
      dateFormatExample: "YYYY-MM-DD or DD/MM/YYYY",
      workweek: "Monday – Friday. Saturday & Sunday weekend.",
      businessHours: "09:00 – 17:00 EST",
      callingRecommendationFromAddis: "04:00 PM – 10:00 PM Addis Ababa time.",
      holidayDifferences: "Canada Day (July 1), Victoria Day (May), Thanksgiving (2nd Monday of October). Large Ethiopian communities in Toronto, Calgary, Edmonton, Ottawa.",
      seasonDifference: "Severe continental winter contrasted with temperate summer.",
    ),
    CountryProfile(
      id: "ae",
      nameEn: "United Arab Emirates",
      nameAm: "የተባበሩት አረብ ኤምሬቶች (ዱባይ)",
      capitalEn: "Abu Dhabi",
      flag: "🇦🇪",
      region: "Middle East / Gulf",
      timeZoneId: "Asia/Dubai",
      timeZoneName: "GST (UTC+4 all year - No DST)",
      dialCode: "+971",
      currencyName: "UAE Dirham",
      currencySymbol: "AED (د.إ)",
      dateFormatExample: "DD/MM/YYYY",
      workweek: "Monday – Thursday (full day) + Friday half day (since 2022). Saturday & Sunday weekend.",
      businessHours: "08:00 – 17:00 GST",
      callingRecommendationFromAddis: "09:00 AM – 04:00 PM Addis Ababa time (UAE is only 1 hour ahead of Ethiopia).",
      holidayDifferences: "Islamic holidays (Eid al-Fitr, Eid al-Adha, Islamic New Year, Prophet's Birthday) and National Day (Dec 2). Highly popular business and travel corridor with Addis Ababa.",
      seasonDifference: "Hot desert climate. Ethiopia is 1 hour behind Dubai all year with no daylight saving shifts.",
    ),
    CountryProfile(
      id: "sa",
      nameEn: "Saudi Arabia",
      nameAm: "ሳውዲ አረቢያ",
      capitalEn: "Riyadh",
      flag: "🇸🇦",
      region: "Middle East",
      timeZoneId: "Asia/Riyadh",
      timeZoneName: "AST (UTC+3 all year - Same as Ethiopia!)",
      dialCode: "+966",
      currencyName: "Saudi Riyal",
      currencySymbol: "SAR (﷼)",
      dateFormatExample: "DD/MM/YYYY + Umm al-Qura Hijri",
      workweek: "Sunday – Thursday. Friday & Saturday weekend.",
      businessHours: "08:00 – 16:30 AST",
      callingRecommendationFromAddis: "Exact same time as Addis Ababa (0 hours time difference)! Working hours 09:00 AM – 04:00 PM Sunday through Thursday.",
      holidayDifferences: "Official calendar uses Umm al-Qura Hijri lunar system alongside Gregorian. Major breaks on Eid al-Fitr and Hajj season.",
      seasonDifference: "Direct geographical neighbor across the Red Sea; identical standard time (UTC+3).",
    ),
    CountryProfile(
      id: "eg",
      nameEn: "Egypt (Coptic & Arab Republic)",
      nameAm: "ግብፅ",
      capitalEn: "Cairo",
      flag: "🇪🇬",
      region: "North Africa",
      timeZoneId: "Africa/Cairo",
      timeZoneName: "EET (UTC+2) / EEST (UTC+3 in Summer)",
      dialCode: "+20",
      currencyName: "Egyptian Pound",
      currencySymbol: "EGP (E£)",
      dateFormatExample: "DD/MM/YYYY",
      workweek: "Sunday – Thursday. Friday & Saturday weekend.",
      businessHours: "09:00 – 16:00 EET",
      callingRecommendationFromAddis: "10:00 AM – 04:00 PM Addis Ababa time.",
      holidayDifferences: "Coptic Christmas (Jan 7, matches Ethiopian Genna), Sham Ennessim (Easter Monday). Historic sister church of Alexandria with matching 13-month Coptic calendar.",
      seasonDifference: "Shares the ancient Nile basin connection; 1 hour behind Addis Ababa in winter, identical time during Egypt summer DST.",
    ),
    CountryProfile(
      id: "au",
      nameEn: "Australia",
      nameAm: "አውስትራሊያ",
      capitalEn: "Canberra",
      flag: "🇦🇺",
      region: "Oceania",
      timeZoneId: "Australia/Sydney",
      timeZoneName: "AEST (UTC+10) / AEDT (UTC+11 in Summer)",
      dialCode: "+61",
      currencyName: "Australian Dollar",
      currencySymbol: "AUD (\$)",
      dateFormatExample: "DD/MM/YYYY",
      workweek: "Monday – Friday. Saturday & Sunday weekend.",
      businessHours: "09:00 – 17:00 AEST",
      callingRecommendationFromAddis: "07:00 AM – 11:00 AM Addis Ababa time (corresponds to 02:00 PM – 06:00 PM in Sydney).",
      holidayDifferences: "Australia Day (Jan 26), ANZAC Day (Apr 25). Financial year runs July 1 – June 30.",
      seasonDifference: "Southern hemisphere: seasons are reversed! When it is winter in Europe/North America, it is summer in Australia.",
    ),
  ];

  /// UI alias for [convertAddisAbabaTimeToWorldCities].
  static List<WorldCityTimeResult> convertTime(int addisHour24, int addisMinute) {
    return convertAddisAbabaTimeToWorldCities(addisHour24, addisMinute);
  }

  /// UI alias wrapping multi-calendar conversion for an Ethiopian date.
  static EuropeanCalendarResult getEuropeanCalendarDetails(EthiopianDate ethiopianDate) {
    final gregorian = EthiopianCalendarEngine.toGregorian(ethiopianDate);
    final jdn = EthiopianCalendarEngine.ethiopianToJdn(ethiopianDate);
    return computeEuropeanAndWorldCalendarDetails(ethiopianDate, gregorian, jdn);
  }

  /// UI alias — date difference lives on [EthiopianCalendarEngine].
  static DateDifference calculateDifference(EthiopianDate from, EthiopianDate to) {
    return EthiopianCalendarEngine.calculateDifference(from, to);
  }

  static List<WorldCityTimeResult> convertAddisAbabaTimeToWorldCities(
    int addisHour24,
    int addisMinute, {
    int referenceYear = 2026,
    int referenceMonth = 10,
    int referenceDay = 20,
  }) {
    // Addis Ababa is UTC+3
    const double addisOffsetHours = 3.0;

    return worldCities.map((city) {
      final diffFromAddis = city.utcOffsetHours - addisOffsetHours;
      final totalAddisMinutes = addisHour24 * 60 + addisMinute;
      final totalTargetMinutes = (totalAddisMinutes + (diffFromAddis * 60)).round();

      int tHour24 = (totalTargetMinutes ~/ 60);
      final tMinute = (totalTargetMinutes % 60 + 60) % 60;
      int dayOffset = 0;

      if (tHour24 >= 24) {
        dayOffset = tHour24 ~/ 24;
        tHour24 = tHour24 % 24;
      } else if (tHour24 < 0) {
        dayOffset = ((tHour24 - 23) ~/ 24);
        tHour24 = (tHour24 % 24 + 24) % 24;
      }

      final int tHour12 = (tHour24 % 12 == 0) ? 12 : (tHour24 % 12);
      final bool isPm = tHour24 >= 12;

      final BusinessStatus status;
      if (tHour24 >= 9 && tHour24 <= 17) {
        status = BusinessStatus.open;
      } else if ((tHour24 >= 7 && tHour24 <= 8) || (tHour24 >= 18 && tHour24 <= 21)) {
        status = BusinessStatus.leisure;
      } else {
        status = BusinessStatus.sleeping;
      }

      final f12 = "$tHour12:${tMinute.toString().padLeft(2, '0')} ${isPm ? 'PM' : 'AM'}";
      final f24 = "${tHour24.toString().padLeft(2, '0')}:${tMinute.toString().padLeft(2, '0')}";

      return WorldCityTimeResult(
        city: city,
        hour24: tHour24,
        minute: tMinute,
        hour12: tHour12,
        isPm: isPm,
        timeZoneAbbreviation: city.standardTzAbbr,
        rawOffsetHours: city.utcOffsetHours,
        differenceFromAddisHours: diffFromAddis,
        dayOffset: dayOffset,
        businessStatus: status,
        formattedTime12: f12,
        formattedTime24: f24,
      );
    }).toList();
  }

  static (int, int) convertWorldCityTimeToAddisAbaba(
    String cityId,
    int hour24,
    int minute,
  ) {
    final city = worldCities.where((c) => c.id == cityId).firstOrNull ?? worldCities[0];
    const double addisOffsetHours = 3.0;
    final diffFromCityToAddis = addisOffsetHours - city.utcOffsetHours;
    final totalCityMinutes = hour24 * 60 + minute;
    final totalAddisMinutes = (totalCityMinutes + (diffFromCityToAddis * 60)).round();

    int addisHour = (totalAddisMinutes ~/ 60) % 24;
    if (addisHour < 0) addisHour += 24;
    final addisMin = (totalAddisMinutes % 60 + 60) % 60;
    return (addisHour, addisMin);
  }

  static EuropeanCalendarResult computeEuropeanAndWorldCalendarDetails(
    EthiopianDate ethiopianDate,
    GregorianDate gregorianDate,
    int jdn,
  ) {
    final gYear = gregorianDate.year;
    final gMonth = gregorianDate.month;
    final gDay = gregorianDate.day;

    final gregFormattedEu = "${gDay.toString().padLeft(2, '0')}.${gMonth.toString().padLeft(2, '0')}.$gYear";
    final gregFormattedUk = "${gDay.toString().padLeft(2, '0')}/${gMonth.toString().padLeft(2, '0')}/$gYear";

    const monthNamesDe = [
      "Januar", "Februar", "März", "April", "Mai", "Juni",
      "Juli", "August", "September", "Oktober", "November", "Dezember"
    ];
    final deMonth = (gMonth >= 1 && gMonth <= 12) ? monthNamesDe[gMonth - 1] : "";
    final gregFormattedDe = "$gDay. $deMonth $gYear";
    final gregFormattedFr = "${gDay.toString().padLeft(2, '0')}/${gMonth.toString().padLeft(2, '0')}/$gYear";
    final gregFormattedUs = "${gMonth.toString().padLeft(2, '0')}/${gDay.toString().padLeft(2, '0')}/$gYear";
    final iso8601 = "$gYear-${gMonth.toString().padLeft(2, '0')}-${gDay.toString().padLeft(2, '0')}";

    // Julian Calendar (Old Style)
    final c = jdn + 32082;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final julDay = (e - ((153 * m + 2) ~/ 5) + 1);
    final julMonth = (m + 3 - 12 * (m ~/ 10));
    final julYear = (d - 4800 + (m ~/ 10));
    final julianDateStr = "${julDay.toString().padLeft(2, '0')}/${julMonth.toString().padLeft(2, '0')}/$julYear (Old Style / 13 days behind GC)";

    // Coptic Calendar
    final copticYear = ethiopianDate.year - 276;
    final copticDay = ethiopianDate.day;
    const copticMonthsEn = [
      "Thout (ቶት)", "Paopi (ባባ)", "Hathor (ሀቱር)", "Koiak (ኪያክ)",
      "Tobi (ጡባ)", "Meshir (አምሺር)", "Paremhat (በረምሃት)", "Parmouti (በረሙዳ)",
      "Pashons (በሽንስ)", "Paoni (በአውና)", "Epip (አቢብ)", "Mesori (መስራ)",
      "Pi Kogi Enavot / Nasie (ናሲ)"
    ];
    final copticMonthName = (ethiopianDate.month >= 1 && ethiopianDate.month <= 13)
        ? copticMonthsEn[ethiopianDate.month - 1]
        : "Month ${ethiopianDate.month}";
    final copticDateStr = "$copticDay $copticMonthName $copticYear A.M.";

    // Hijri Calendar Estimation
    final days = jdn - 1948440 + 10632;
    final cycle = days ~/ 10631;
    final rem = days % 10631;
    final hYear = (cycle * 30 + ((rem * 30 + 14) ~/ 10631) - 29);
    final dayInYear = (jdn - (1948439 + (hYear - 1) * 354 + ((3 + 11 * hYear) ~/ 30)));
    final hMonth = math.min(12, ((dayInYear - 1) / 29.5).toInt() + 1);
    final monthDays = (29.5 * (hMonth - 1)).ceil();
    final hDay = (dayInYear - monthDays).clamp(1, 30);
    const hijriMonths = [
      "Muharram", "Safar", "Rabi' I", "Rabi' II", "Jumada I", "Jumada II",
      "Rajab", "Sha'ban", "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"
    ];
    final hijriDateStr = "$hDay ${(hMonth >= 1 && hMonth <= 12) ? hijriMonths[hMonth - 1] : ''} $hYear AH";

    // European Season
    final String seasonEn;
    final String seasonAm;
    final String seasonEmoji;
    if ((gMonth == 3 && gDay >= 20) || gMonth == 4 || gMonth == 5 || (gMonth == 6 && gDay < 21)) {
      seasonEn = "Spring (Frühling / Printemps)";
      seasonAm = "ፀደይ (የአውሮፓ)";
      seasonEmoji = "🌸";
    } else if ((gMonth == 6 && gDay >= 21) || gMonth == 7 || gMonth == 8 || (gMonth == 9 && gDay < 23)) {
      seasonEn = "Summer (Sommer / Été)";
      seasonAm = "በጋ (የአውሮፓ)";
      seasonEmoji = "☀️";
    } else if ((gMonth == 9 && gDay >= 23) || gMonth == 10 || gMonth == 11 || (gMonth == 12 && gDay < 22)) {
      seasonEn = "Autumn (Herbst / Automne)";
      seasonAm = "መኸር (የአውሮፓ)";
      seasonEmoji = "🍂";
    } else {
      seasonEn = "Winter (Winter / Hiver)";
      seasonAm = "ክረምት / በረዶ (የአውሮፓ)";
      seasonEmoji = "❄️";
    }

    final String quarter;
    if (gMonth >= 1 && gMonth <= 3) {
      quarter = "Q1 (Jan–Mar)";
    } else if (gMonth >= 4 && gMonth <= 6) {
      quarter = "Q2 (Apr–Jun)";
    } else if (gMonth >= 7 && gMonth <= 9) {
      quarter = "Q3 (Jul–Sep)";
    } else {
      quarter = "Q4 (Oct–Dec)";
    }

    final dt = DateTime(gYear, gMonth, gDay);
    final dayOfYear = dt.difference(DateTime(gYear, 1, 1)).inDays + 1;
    final weekOfYear = ((dayOfYear - dt.weekday + 10) / 7).floor();
    final isEuWeekend = dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;
    final isEthWeekend = dt.weekday == DateTime.sunday;

    final yearDiff = gYear - ethiopianDate.year;
    final yearOffsetExplanation = yearDiff == 7
        ? "Between Sep 11 and Dec 31, the European/Gregorian calendar is exactly 7 years ahead of the Ethiopian Calendar ($gYear - ${ethiopianDate.year} = 7 years gap)."
        : "Between Jan 1 and Sep 10, the European/Gregorian calendar is exactly 8 years ahead of the Ethiopian Calendar ($gYear - ${ethiopianDate.year} = 8 years gap).";

    return EuropeanCalendarResult(
      gregorianFormattedEu: gregFormattedEu,
      gregorianFormattedUk: gregFormattedUk,
      gregorianFormattedDe: gregFormattedDe,
      gregorianFormattedFr: gregFormattedFr,
      gregorianFormattedUs: gregFormattedUs,
      iso8601: iso8601,
      julianDateStr: julianDateStr,
      julianYear: julYear,
      julianMonth: julMonth,
      julianDay: julDay,
      copticDateStr: copticDateStr,
      copticYear: copticYear,
      copticMonthName: copticMonthName,
      copticDay: copticDay,
      hijriDateStr: hijriDateStr,
      europeanSeasonEn: seasonEn,
      europeanSeasonAm: seasonAm,
      europeanSeasonEmoji: seasonEmoji,
      europeanQuarter: quarter,
      dayOfYear: dayOfYear,
      weekOfYear: weekOfYear,
      isEuropeanWeekend: isEuWeekend,
      isEthiopianWeekend: isEthWeekend,
      yearOffsetExplanation: yearOffsetExplanation,
    );
  }
}
