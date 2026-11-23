/// Traditional Ethiopian timekeeping converter and models.
///
/// In Ethiopia, a 12-hour cycle begins at sunrise (approx 6:00 AM Gregorian = 12:00 morning Ethiopian)
/// and the night cycle begins at sunset (approx 6:00 PM Gregorian = 12:00 night Ethiopian).
enum TimePeriod {
  dawn('ንጋት', 'Dawn', 'Barii', 'ወጋሕታ'),
  morning('ጧት', 'Morning', 'Ganama', 'ንግሆ'),
  midday('ቀትር', 'Midday / Noon', 'Guyyaa', 'ቀትሪ'),
  afternoon('ከሰዓት', 'Afternoon', 'Waaree booda', 'ድሕሪ ቀትሪ'),
  evening('ምሽት', 'Evening', 'Galgala', 'ምሸት'),
  night('ሌሊት', 'Night', 'Halkan', 'ለይቲ'),
  midnight('እኩለ ሌሊት', 'Midnight', 'Halkan walakkaa', 'ፍርቂ ለይቲ');

  final String amharic;
  final String english;
  final String afaanOromo;
  final String tigrinya;

  const TimePeriod(this.amharic, this.english, this.afaanOromo, this.tigrinya);
}

class EthiopianTime {
  final int hour; // 1..12
  final int minute;
  final bool isDaytime; // true = daytime (ቀን), false = nighttime (ሌሊት)
  final TimePeriod period;

  const EthiopianTime({
    required this.hour,
    required this.minute,
    required this.isDaytime,
    required this.period,
  });

  String formatted() {
    final hStr = hour.toString();
    final mStr = minute.toString().padLeft(2, '0');
    final periodStr = isDaytime ? 'ቀን' : 'ሌሊት';
    return '${period.amharic} $hStr:$mStr ($periodStr)';
  }
}

class GregorianTime {
  final int hour24; // 0..23
  final int minute;

  const GregorianTime({
    required this.hour24,
    required this.minute,
  });

  int get hour12 {
    final h = hour24 % 12;
    return h == 0 ? 12 : h;
  }

  bool get isPm => hour24 >= 12;

  String formatted() {
    final amPm = isPm ? 'PM' : 'AM';
    final h12 = hour12;
    final m = minute.toString().padLeft(2, '0');
    final h24 = hour24.toString().padLeft(2, '0');
    return '$h12:$m $amPm ($h24:$m)';
  }
}

class EthiopianTimeConverter {
  /// Converts 24-hour Gregorian time to Ethiopian time.
  static EthiopianTime gregorianToEthiopian(int gHour, int gMinute) {
    if (gHour < 0 || gHour > 23) {
      throw ArgumentError('Hour must be between 0 and 23, was: $gHour');
    }
    if (gMinute < 0 || gMinute > 59) {
      throw ArgumentError('Minute must be between 0 and 59, was: $gMinute');
    }

    final isDaytime = gHour >= 6 && gHour <= 17;
    final int ethHour;
    if (gHour >= 6) {
      final h = gHour - 6;
      ethHour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    } else {
      final h = gHour + 6;
      ethHour = h == 0 ? 12 : h;
    }

    final TimePeriod period;
    switch (gHour) {
      case 5:
        period = TimePeriod.dawn;
        break;
      case 6:
      case 7:
      case 8:
      case 9:
      case 10:
      case 11:
        period = TimePeriod.morning;
        break;
      case 12:
        period = TimePeriod.midday;
        break;
      case 13:
      case 14:
      case 15:
      case 16:
      case 17:
        period = TimePeriod.afternoon;
        break;
      case 18:
      case 19:
      case 20:
        period = TimePeriod.evening;
        break;
      case 21:
      case 22:
      case 23:
        period = TimePeriod.night;
        break;
      case 0:
        period = TimePeriod.midnight;
        break;
      default:
        period = TimePeriod.night;
        break;
    }

    return EthiopianTime(
      hour: ethHour,
      minute: gMinute,
      isDaytime: isDaytime,
      period: period,
    );
  }

  /// Converts 12-hour Ethiopian time to 24-hour Gregorian time.
  static GregorianTime ethiopianToGregorian(int ethHour, int ethMinute, {required bool isDaytime}) {
    if (ethHour < 1 || ethHour > 12) {
      throw ArgumentError('Ethiopian hour must be between 1 and 12, was: $ethHour');
    }
    if (ethMinute < 0 || ethMinute > 59) {
      throw ArgumentError('Minute must be between 0 and 59, was: $ethMinute');
    }

    final int gHour;
    if (isDaytime) {
      gHour = (ethHour % 12) + 6;
    } else {
      gHour = ((ethHour % 12) + 18) % 24;
    }

    return GregorianTime(hour24: gHour, minute: ethMinute);
  }
}
