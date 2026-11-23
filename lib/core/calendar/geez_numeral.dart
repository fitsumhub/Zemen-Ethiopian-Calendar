/// High-fidelity converter between Arabic numerals (1, 2, 3...)
/// and traditional Ethiopian Ge'ez numerals (፩, ፪, ፫, ፲, ፻, ፼).
///
/// Implements canonical Ethiopian numeral formatting rules:
/// - 1..9: ፩ .. ፱
/// - 10..90: ፲ .. ፺
/// - 100: ፻ (single hundred does not use prefix ፩)
/// - 10,000: ፼ (single ten-thousand does not use prefix ፩)
class GeezNumeral {
  static const List<String> geezOnes = [
    '', '፩', '፪', '፫', '፬', '፭', '፮', '፯', '፰', '፱'
  ];

  static const List<String> geezTens = [
    '', '፲', '፳', '፴', '፵', '፶', '፷', '፸', '፹', '፺'
  ];

  static const String geezHundred = '፻';
  static const String geezTenThousand = '፼';
  static const String allGeezChars = '፩፪፫፬፭፮፯፰፱፲፳፴፵፶፷፸፹፺፻፼';

  /// Converts a positive integer into its traditional Ge'ez numeral representation.
  static String toGeez(int num) {
    if (num <= 0) return num.toString();

    // 1 to 99
    if (num < 100) {
      final tens = num ~/ 10;
      final ones = num % 10;
      return geezTens[tens] + geezOnes[ones];
    }

    // 100 to 9,999
    if (num < 10000) {
      final hundreds = num ~/ 100;
      final remainder = num % 100;
      final prefix = hundreds == 1 ? geezHundred : toGeez(hundreds) + geezHundred;
      final suffix = remainder > 0 ? toGeez(remainder) : '';
      return prefix + suffix;
    }

    // 10,000 and above
    final tenThousands = num ~/ 10000;
    final remainder = num % 10000;
    final prefix =
        tenThousands == 1 ? geezTenThousand : toGeez(tenThousands) + geezTenThousand;
    final suffix = remainder > 0 ? toGeez(remainder) : '';
    return prefix + suffix;
  }

  /// Checks if a string contains valid Ge'ez numerals.
  static bool isGeez(String text) {
    if (text.isEmpty) return false;
    for (int i = 0; i < text.length; i++) {
      if (!allGeezChars.contains(text[i])) {
        return false;
      }
    }
    return true;
  }

  /// Parses standard Ge'ez numerals back into an integer.
  static int? fromGeez(String geez) {
    if (geez.isEmpty) return null;
    int total = 0;
    int currentChunk = 0;

    int i = 0;
    while (i < geez.length) {
      final c = geez[i];
      if (c == geezTenThousand) {
        final multiplier = currentChunk == 0 ? 1 : currentChunk;
        total += multiplier * 10000;
        currentChunk = 0;
      } else if (c == geezHundred) {
        final multiplier = currentChunk == 0 ? 1 : currentChunk;
        total += multiplier * 100;
        currentChunk = 0;
      } else {
        final oneIdx = geezOnes.indexOf(c);
        if (oneIdx > 0) {
          currentChunk += oneIdx;
        } else {
          final tenIdx = geezTens.indexOf(c);
          if (tenIdx > 0) {
            currentChunk += tenIdx * 10;
          }
        }
      }
      i++;
    }
    total += currentChunk;
    return total > 0 ? total : null;
  }
}
