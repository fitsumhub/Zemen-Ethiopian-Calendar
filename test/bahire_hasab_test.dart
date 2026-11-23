import 'package:flutter_test/flutter_test.dart';
import 'package:ethiocal/core/calendar/ethiopian_date.dart';
import 'package:ethiocal/core/calendar/ethiopian_date_converter.dart';
import 'package:ethiocal/core/calendar/leap_year_calculator.dart';
import 'package:ethiocal/core/calendar/bahire_hasab.dart';

void main() {
  group('BahireHasab Tests', () {
    test('testAmeteAlemAndEvangelistCycle', () {
      // 2015 E.C. (Luke / ሉቃስ - Leap Year)
      expect(BahireHasab.ameteAlem(2015), 7515);
      expect(BahireHasab.evangelist(2015), Evangelist.luke);
      expect(BahireHasab.evangelist(2015).isLeapYear, isTrue);

      // 2016 E.C. (John / ዮሐንስ)
      expect(BahireHasab.ameteAlem(2016), 7516);
      expect(BahireHasab.evangelist(2016), Evangelist.john);
      expect(BahireHasab.evangelist(2016).isLeapYear, isFalse);

      // 2017 E.C. (Matthew / ማቴዎስ)
      expect(BahireHasab.ameteAlem(2017), 7517);
      expect(BahireHasab.evangelist(2017), Evangelist.matthew);
      expect(BahireHasab.evangelist(2017).isLeapYear, isFalse);

      // 2018 E.C. (Mark / ማርቆስ)
      expect(BahireHasab.ameteAlem(2018), 7518);
      expect(BahireHasab.evangelist(2018), Evangelist.mark);
      expect(BahireHasab.evangelist(2018).isLeapYear, isFalse);
    });

    test('testComputusMathematicalProperties2017', () {
      // Year 2017 E.C. canonical values:
      // Amete Alem = 2017 + 5500 = 7517
      // Medeb = 7517 % 19 = 12
      // Wenber = 12 - 1 = 11
      // Abekte = (11 * 11) % 30 = 121 % 30 = 1
      // Metqi = 30 - 1 = 29 (in Meskerem since > 14)
      expect(BahireHasab.wenber(2017), 11);
      expect(BahireHasab.abeqte(2017), 1);
      expect(BahireHasab.metqi(2017), 29);
      expect(BahireHasab.metqiMonth(2017), 1); // Meskerem
      expect(BahireHasab.metqiDate(2017), EthiopianDate(2017, 1, 29));

      // Nineveh: Yakatit 3, 2017 E.C.
      final nenewe = BahireHasab.nenewe(2017);
      expect(nenewe, EthiopianDate(2017, 6, 3));

      // Fasika: Miazia 12, 2017 E.C. (April 20, 2025 G.C.)
      final fasika = BahireHasab.fasika(2017);
      expect(fasika, EthiopianDate(2017, 8, 12));

      // Great Lent starts: Yakatit 17, 2017 E.C.
      final abiyTsom = BahireHasab.abiyTsom(2017);
      expect(abiyTsom, EthiopianDate(2017, 6, 17));

      // Good Friday: Miazia 10, 2017 E.C.
      final siklet = BahireHasab.siklet(2017);
      expect(siklet, EthiopianDate(2017, 8, 10));
    });

    test('testComputusMathematicalProperties2016', () {
      // Year 2016 E.C. canonical values:
      // Amete Alem = 7516
      // Medeb = 7516 % 19 = 11
      // Wenber = 10
      // Abekte = (10 * 11) % 30 = 20
      // Metqi = 30 - 20 = 10 (in Tikimt since <= 14)
      expect(BahireHasab.wenber(2016), 10);
      expect(BahireHasab.abeqte(2016), 20);
      expect(BahireHasab.metqi(2016), 10);
      expect(BahireHasab.metqiMonth(2016), 2); // Tikimt
      expect(BahireHasab.metqiDate(2016), EthiopianDate(2016, 2, 10));

      // Nineveh: Yakatit 18, 2016 E.C. (Feb 26, 2024 G.C.)
      final nenewe = BahireHasab.nenewe(2016);
      expect(nenewe, EthiopianDate(2016, 6, 18));

      // Fasika: Miazia 27, 2016 E.C. (May 5, 2024 G.C.)
      final fasika = BahireHasab.fasika(2016);
      expect(fasika, EthiopianDate(2016, 8, 27));
    });

    test('testComputusMathematicalProperties2015', () {
      // Year 2015 E.C. canonical values:
      // Amete Alem = 7515
      // Wenber = 9
      // Abekte = (9 * 11) % 30 = 9
      // Metqi = 30 - 9 = 21 (in Meskerem)
      expect(BahireHasab.wenber(2015), 9);
      expect(BahireHasab.abeqte(2015), 9);
      expect(BahireHasab.metqi(2015), 21);
      expect(BahireHasab.metqiMonth(2015), 1);

      // Nineveh: Tir 29, 2015 E.C. (Feb 6, 2023 G.C.)
      final nenewe = BahireHasab.nenewe(2015);
      expect(nenewe, EthiopianDate(2015, 5, 29));

      // Fasika: Miazia 8, 2015 E.C. (April 16, 2023 G.C.)
      final fasika = BahireHasab.fasika(2015);
      expect(fasika, EthiopianDate(2015, 8, 8));
    });

    test('testCanonicalDayOfWeekPropertiesForAllFeastsAcrossCenturies', () {
      for (int year = 2000; year <= 2050; year++) {
        final nenewe = BahireHasab.nenewe(year);
        expect(EthiopianDateConverter.getDayOfWeek(nenewe), 1,
            reason: 'Nineveh must be Monday in $year');

        final abiyTsom = BahireHasab.abiyTsom(year);
        expect(EthiopianDateConverter.getDayOfWeek(abiyTsom), 1,
            reason: 'Great Lent must be Monday in $year');

        final debreZeit = BahireHasab.debreZeit(year);
        expect(EthiopianDateConverter.getDayOfWeek(debreZeit), 7,
            reason: 'Debre Zeit must be Sunday in $year');

        final hosanna = BahireHasab.hosanna(year);
        expect(EthiopianDateConverter.getDayOfWeek(hosanna), 7,
            reason: 'Hosanna must be Sunday in $year');

        final siklet = BahireHasab.siklet(year);
        expect(EthiopianDateConverter.getDayOfWeek(siklet), 5,
            reason: 'Good Friday must be Friday in $year');

        final fasika = BahireHasab.fasika(year);
        expect(EthiopianDateConverter.getDayOfWeek(fasika), 7,
            reason: 'Fasika must be Sunday in $year');

        final rikbeKahnat = BahireHasab.rikbeKahnat(year);
        expect(EthiopianDateConverter.getDayOfWeek(rikbeKahnat), 3,
            reason: 'Rikbe Kahnat must be Wednesday in $year');

        final erget = BahireHasab.erget(year);
        expect(EthiopianDateConverter.getDayOfWeek(erget), 4,
            reason: 'Erget must be Thursday in $year');

        final paraclete = BahireHasab.paraclete(year);
        expect(EthiopianDateConverter.getDayOfWeek(paraclete), 7,
            reason: 'Pentecost must be Sunday in $year');

        final hawaryat = BahireHasab.tsomeHawaryat(year);
        expect(EthiopianDateConverter.getDayOfWeek(hawaryat), 1,
            reason: 'Apostles\' Fast must be Monday in $year');

        final dihnet = BahireHasab.tsomeDihnet(year);
        expect(EthiopianDateConverter.getDayOfWeek(dihnet), 3,
            reason: 'Fast of Salvation must be Wednesday in $year');
      }
    });

    test('testFastingPeriodDetectors', () {
      // Fast of Nineveh 2017: Yakatit 3, 4, 5
      expect(BahireHasab.isNinevehFast(EthiopianDate(2017, 6, 3)), isTrue);
      expect(BahireHasab.isNinevehFast(EthiopianDate(2017, 6, 4)), isTrue);
      expect(BahireHasab.isNinevehFast(EthiopianDate(2017, 6, 5)), isTrue);
      expect(BahireHasab.isNinevehFast(EthiopianDate(2017, 6, 6)), isFalse);

      // Great Lent 2017: Yakatit 17 through Miazia 11
      expect(BahireHasab.isGreatLent(EthiopianDate(2017, 6, 17)), isTrue);
      expect(BahireHasab.isGreatLent(EthiopianDate(2017, 7, 15)), isTrue);
      expect(BahireHasab.isGreatLent(EthiopianDate(2017, 8, 11)), isTrue); // Holy Saturday
      expect(BahireHasab.isGreatLent(EthiopianDate(2017, 8, 12)), isFalse); // Easter Day

      // Fifty Days of Joy (Easter to Pentecost)
      expect(BahireHasab.isFiftyDaysOfJoy(EthiopianDate(2017, 8, 12)), isTrue); // Easter
      expect(BahireHasab.isFiftyDaysOfJoy(EthiopianDate(2017, 9, 1)), isTrue);
      expect(BahireHasab.isFiftyDaysOfJoy(EthiopianDate(2017, 10, 1)), isTrue); // Pentecost
      expect(BahireHasab.isFiftyDaysOfJoy(EthiopianDate(2017, 10, 2)), isFalse);
    });
  });
}
