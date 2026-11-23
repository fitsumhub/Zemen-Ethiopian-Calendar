import 'ethiopian_date.dart';

/// The Four Canonical Seasons of Ethiopia (አራቱ የኢትዮጵያ ወቅቶች):
/// - Metsew / Meher (መፀው / መኸር - Autumn / Harvest): Meskerem 26 - Tahsas 25
/// - Bega (በጋ - Winter / Dry): Tahsas 26 - Megabit 25
/// - Tseday / Belg (ጸደይ / በልግ - Spring / Blossom): Megabit 26 - Sene 25
/// - Kiremt (ክረምት - Summer / Rainy): Sene 26 - Meskerem 25 (including Pagume)
enum EthiopianSeason {
  metsewMeher(
    'መፀው (መኸር)',
    'Autumn / Harvest (Meher)',
    'ከመስከረም 26 እስከ ታኅሣሥ 25። የአዝመራ፣ የአበባና የምስጋና ወቅት።',
    'From Meskerem 26 to Tahsas 25. The season of harvest, blooming Adey Abeba, and thanksgiving.',
    '🌾',
  ),
  bega(
    'በጋ',
    'Winter / Dry (Bega)',
    'ከታኅሣሥ 26 እስከ መጋቢት 25። ፀሐያማ፣ ደረቅና የጥምቀት በዓላት ወቅት።',
    'From Tahsas 26 to Megabit 25. The sunny and dry season marked by Timkat and Kana ZeGalila.',
    '☀️',
  ),
  tsedayBelg(
    'ጸደይ (በልግ)',
    'Spring / Blossom (Tseday / Belg)',
    'ከመጋቢት 26 እስከ ሰኔ 25። የትንሣኤ (ፋሲካ) እና የልምላሜ ወቅት።',
    'From Megabit 26 to Sene 25. The season of spring blossoms, green growth, and Easter (Fasika).',
    '🌱',
  ),
  kiremt(
    'ክረምት',
    'Summer / Rainy (Kiremt)',
    'ከሰኔ 26 እስከ መስከረም 25 (ጳጉሜን ጨምሮ)። የዝናብ፣ የጎርፍና የጾመ ፍልሰታ ወቅት።',
    'From Sene 26 to Meskerem 25 (including Pagume). The season of heavy rains, lush greenery, and Filseta.',
    '🌧️',
  );

  final String amharicName;
  final String englishName;
  final String descriptionAmharic;
  final String descriptionEnglish;
  final String emoji;

  const EthiopianSeason(
    this.amharicName,
    this.englishName,
    this.descriptionAmharic,
    this.descriptionEnglish,
    this.emoji,
  );

  static EthiopianSeason fromEthiopianDate(int month, int day) {
    switch (month) {
      case 1:
        return day <= 25 ? EthiopianSeason.kiremt : EthiopianSeason.metsewMeher;
      case 2:
      case 3:
        return EthiopianSeason.metsewMeher;
      case 4:
        return day <= 25 ? EthiopianSeason.metsewMeher : EthiopianSeason.bega;
      case 5:
      case 6:
        return EthiopianSeason.bega;
      case 7:
        return day <= 25 ? EthiopianSeason.bega : EthiopianSeason.tsedayBelg;
      case 8:
      case 9:
        return EthiopianSeason.tsedayBelg;
      case 10:
        return day <= 25 ? EthiopianSeason.tsedayBelg : EthiopianSeason.kiremt;
      case 11:
      case 12:
      case 13:
        return EthiopianSeason.kiremt;
      default:
        return EthiopianSeason.kiremt;
    }
  }

  static EthiopianSeason fromDate(EthiopianDate date) {
    return fromEthiopianDate(date.month, date.day);
  }

  /// Mid-month approximation used by converter UI when only a month is known.
  static EthiopianSeason fromMonth(int month) {
    return fromEthiopianDate(month, 15);
  }
}
