# Abushakir (ባሕረ ሃሳብ) 
[![GitHub stars](https://img.shields.io/github/stars/Nabute/Abushakir?style=social)](https://github.com/Nabute/Abushakir/stargazers)       [![GitHub forks](https://img.shields.io/github/forks/Nabute/Abushakir?style=social)](https://github.com/Nabute/Abushakir/network)
[![GitHub license](https://img.shields.io/github/license/Nabute/Abushakir)](https://github.com/Nabute/Abushakir/blob/master/LICENSE)

The words Bahire Hasab originate from the ancient language of Ge'ez, ( Arabic: Abu Shakir) is a
time-tracking method, devised by the 12th pope of Alexandria, Pope St. Dimitri.

## What does it mean?

"Bahire Hasab /'bəhrɛ həsəb'/  " simply means "An age with a descriptive and chronological number". In some books it can also be found as "Hasabe Bahir", in a sense giving time an analogy, resembling a sea.

This package allows developers to implement Ethiopian Calendar and Datetime System in their application(s)`.

This package is implemented using the [UNIX EPOCH](https://en.wikipedia.org/wiki/Unix_time) which
means it's not a conversion of any other calendar system into Ethiopian, for instance, Gregorian Calendar.

Unix Epoch is measured using milliseconds since 01 Jan, 1970 UTC. In unix epoch leap seconds are ignored.

## Documentation
[Abushakir](https://pub.dev/documentation/abushakir/latest/)

## Demo
[Ethiopian calendar](https://github.com/Nabute/ethiopian_calendar)

## Prerequisites

Before you begin, ensure you have met the following requirements:

* ```equatable= ^2.0.5```


## Getting started

In the `pubspec.yaml` of your flutter project, add the following dependency:

```yaml
dependencies:
  ...
  abushakir: "^1.0.0"
```

In your library add the following import:

```dart
import 'package:abushakir/abushakir.dart';
```
## Example

```dart
   /**
   * Ethiopian Datetime Module [EtDatetime]
   */
  EtDatetime now = new EtDatetime.now(); // => 2012-07-28 17:18:31.466
  print(now.date); // => {year: 2012, month: 7, day: 28}
  print(now.time); // => {h: 17, m: 18, s: 31}

  EtDatetime covidFirstConfirmed = new EtDatetime(year: 2012, month: 7, day: 4);
  EtDatetime covidFirstConfirmedEpoch =
      new EtDatetime.fromMillisecondsSinceEpoch(covidFirstConfirmed.moment);

  EtDatetime covidFirstDeath = EtDatetime.parse("2012-07-26 23:00:00");

  /// Comparison of two EtDatetime Instances
  Duration daysWithOutDeath = covidFirstConfirmed.difference(covidFirstDeath);

  assert(daysWithOutDeath.inDays == -22, true); // 22 days

  assert(covid
