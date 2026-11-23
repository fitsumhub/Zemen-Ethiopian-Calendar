import 'package:ethiocal/core/calendar/ethiopian_date.dart';
import 'package:ethiocal/core/holidays/holiday_engine.dart';
import 'package:ethiocal/core/localization/app_language.dart';
import 'package:ethiocal/core/widgets/home_widget_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('basic snapshot has dual calendar fields', () {
    final s = HomeWidgetEngine.build(
      HomeWidgetKind.basicDate,
      lang: AppLanguage.amharic,
      forDate: EthiopianDate(2018, 4, 20),
    );
    expect(s.eth.day, 20);
    expect(s.monthName.isNotEmpty, isTrue);
    expect(s.weekdayName.isNotEmpty, isTrue);
    expect(s.geezDay.isNotEmpty, isTrue);
    expect(s.gregLabel.contains('202'), isTrue);
    expect(s.saintName.isNotEmpty, isTrue);
  });

  test('amharic gregorian label uses ethiopic month name', () {
    final s = HomeWidgetEngine.build(
      HomeWidgetKind.basicDate,
      lang: AppLanguage.amharic,
      forDate: EthiopianDate(2018, 4, 29),
    );
    expect(s.gregLabel.contains(RegExp(r'[ሀ-፼]')), isTrue);
  });

  test('nativity countdown is non-negative', () {
    final s = HomeWidgetEngine.build(
      HomeWidgetKind.nativityCountdown,
      forDate: EthiopianDate(2018, 3, 10),
    );
    expect(s.daysUntilGenna, isNotNull);
    expect(s.daysUntilGenna! >= 0, isTrue);
    expect(s.gennaLabel.isNotEmpty, isTrue);
  });

  test('prophets progress during advent', () {
    final s = HomeWidgetEngine.build(
      HomeWidgetKind.prophetsFast,
      forDate: EthiopianDate(2018, 3, 20),
    );
    expect(s.prophetsDayIndex, isNotNull);
    expect(s.prophetsDayIndex! > 0, isTrue);
    expect(s.prophetsTotalDays, greaterThan(30));
    expect(s.prophetsProgress, greaterThan(0));
  });

  test('prophets before advent reports days until start', () {
    final s = HomeWidgetEngine.build(
      HomeWidgetKind.prophetsFast,
      forDate: EthiopianDate(2018, 2, 1),
    );
    expect(s.prophetsDayIndex, isNull);
    expect(s.daysUntilAdvent, isNotNull);
    expect(s.daysUntilAdvent! > 0, isTrue);
  });

  test('genna day itself has zero countdown', () {
    final year = 2018;
    final day = HolidayEngine.gennaDay(year);
    final s = HomeWidgetEngine.build(
      HomeWidgetKind.nativityCountdown,
      forDate: EthiopianDate(year, 4, day),
    );
    expect(s.daysUntilGenna, 0);
  });

  test('atelier kinds produce snapshots', () {
    for (final kind in HomeWidgetKind.values) {
      final s = HomeWidgetEngine.build(kind, forDate: EthiopianDate(2018, 4, 20));
      expect(s.kind, kind);
      expect(s.saintName.isNotEmpty, isTrue);
      expect(s.monthName.isNotEmpty, isTrue);
    }
    expect(HomeWidgetKindX.lastIndex, HomeWidgetKind.values.length - 1);
    expect(HomeWidgetKindX.fromIndex(99), HomeWidgetKind.values.last);
  });

  test('preference map includes sync keys', () {
    final s = HomeWidgetEngine.build(HomeWidgetKind.classicDate);
    final map = HomeWidgetEngine.toPreferenceMap(
      s,
      size: 'wide',
      themeFamily: 'parchmentClassic',
    );
    expect(map['widget_eth_d'], isNotEmpty);
    expect(map['widget_kind'], isNotEmpty);
    expect(map['widget_size'], 'wide');
    expect(map['widget_theme_family'], 'parchmentClassic');
    expect(map.containsKey('widget_updated_ms'), isTrue);
    expect(map['widget_days_in_month'], isNotEmpty);
    expect(map['widget_month_start_dow'], isNotEmpty);
    expect(int.parse(map['widget_month_start_dow']!), inInclusiveRange(1, 7));
  });

  test('preference map month grid matches Ethiopian month length', () {
    final s = HomeWidgetEngine.build(
      HomeWidgetKind.basicDate,
      forDate: EthiopianDate(2018, 13, 3),
    );
    final map = HomeWidgetEngine.toPreferenceMap(s);
    expect(map['widget_days_in_month'], '${s.eth.daysInMonth()}');
    expect(map['widget_eth_d'], '3');
    expect(map['widget_eth_m'], '13');
  });
}
