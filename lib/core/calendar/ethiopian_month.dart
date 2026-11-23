/// Enumeration representing all 13 months of the Ethiopian calendar (አውራኅ).
/// Includes the 12 regular 30-day months and Pagume (ጳጉሜ / the epagomenal month).
enum EthiopianMonth {
  meskerem(1, 'መስከረም', 'Meskerem', 'ወርኀ መስከረም', 'Fulbaana', 'መስከረም', 'መጸው', 'Autumn'),
  tikimt(2, 'ጥቅምት', 'Tikimt', 'ወርኀ ጥቅምት', 'Onkololeessa', 'ጥቅምቲ', 'መጸው', 'Autumn'),
  hidar(3, 'ኅዳር', 'Hidar', 'ወርኀ ኅዳር', 'Sadaasa', 'ሕዳር', 'መጸው', 'Autumn'),
  tahsas(4, 'ታኅሣሥ', 'Tahsas', 'ወርኀ ታኅሣሥ', 'Muddee', 'ታሕሳስ', 'በጋ', 'Winter'),
  tir(5, 'ጥር', 'Tir', 'ወርኀ ጥር', 'Amajjii', 'ጥሪ', 'በጋ', 'Winter'),
  yakatit(6, 'የካቲት', 'Yakatit', 'ወርኀ የካቲት', 'Guraandhala', 'የካቲት', 'በጋ', 'Winter'),
  megabit(7, 'መጋቢት', 'Megabit', 'ወርኀ መጋቢት', 'Bitooteessa', 'መጋቢት', 'ጸደይ', 'Spring'),
  miazia(8, 'ሚያዝያ', 'Miazia', 'ወርኀ ሚያዝያ', 'Ebla', 'ሚያዝያ', 'ጸደይ', 'Spring'),
  ginbot(9, 'ግንቦት', 'Ginbot', 'ወርኀ ግንቦት', 'Caamsaa', 'ግንቦት', 'ጸደይ', 'Spring'),
  sene(10, 'ሰኔ', 'Sene', 'ወርኀ ሰኔ', 'Waxabajjii', 'ሰነ', 'ክረምት', 'Summer'),
  hamle(11, 'ሐምሌ', 'Hamle', 'ወርኀ ሐምሌ', 'Adooleessa', 'ሓምለ', 'ክረምት', 'Summer'),
  nehase(12, 'ነሐሴ', 'Nehase', 'ወርኀ ነሐሴ', 'Hagayya', 'ነሓሰ', 'ክረምት', 'Summer'),
  pagume(13, 'ጳጉሜ', 'Pagume', 'ወርኀ ጳጉሜን', 'Qaammee', 'ጳጉሜን', 'ክረምት', 'Summer');

  final int number;
  final String amharicName;
  final String englishName;
  final String geezName;
  final String oromoName;
  final String tigrinyaName;
  final String seasonAmharic;
  final String seasonEnglish;

  const EthiopianMonth(
    this.number,
    this.amharicName,
    this.englishName,
    this.geezName,
    this.oromoName,
    this.tigrinyaName,
    this.seasonAmharic,
    this.seasonEnglish,
  );

  /// Returns the number of days in this month for a given year.
  /// Regular months (1..12) always have 30 days.
  /// Pagume (13) has 6 days in an Ethiopian leap year, 5 days otherwise.
  int daysInMonth(bool isLeapYear) {
    if (this == EthiopianMonth.pagume) {
      return isLeapYear ? 6 : 5;
    } else {
      return 30;
    }
  }

  static EthiopianMonth fromNumber(int monthNumber) {
    if (monthNumber < 1 || monthNumber > 13) {
      throw ArgumentError('Month number must be between 1 and 13, received: $monthNumber');
    }
    return EthiopianMonth.values[monthNumber - 1];
  }
}
