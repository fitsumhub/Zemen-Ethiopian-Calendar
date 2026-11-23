# Kenat / ቀናት [![PyPI Version](https://img.shields.io/pypi/v/kenat)](https://pypi.org/project/kenat/)

![banner](https://raw.githubusercontent.com/MelakuDemeke/kenat_py/master/assets/img/py_banner.png)

![GitHub issues](https://img.shields.io/github/issues/MelakuDemeke/kenat_py)
![GitHub Repo stars](https://img.shields.io/github/stars/MelakuDemeke/kenat_py?logo=github&style=flat)
![GitHub forks](https://img.shields.io/github/forks/MelakuDemeke/kenat_py?logo=github&style=falt)
![GitHub commit activity](https://img.shields.io/github/commit-activity/m/MelakuDemeke/kenat_py?logo=github)


**A complete Ethiopian Calendar & Bahire Hasab toolkit for Python**

---

## 📌 Overview

**Kenat** (Amharic: ቀናት) is a powerful and authentic Ethiopian calendar library for Python. It offers full support for date conversion, holiday computation (including Bahire Hasab), localized formatting, Geez numerals, and more — all without external dependencies.

> 🚀 Ported from the original [kenat JS library](https://github.com/MelakuDemeke/kenat).

---

## ✨ Features

* 🔄 **Bidirectional Conversion**: Ethiopian ↔ Gregorian calendars
* 📅 **Full Holiday System**: Christian, Muslim, cultural, and public holidays
* ⛪ **Bahire Hasab**: Accurate movable feast calculations (e.g. Fasika, Tsome Nebiyat)
* 🙏 **Fasting Periods**: Abiy Tsome, Nineveh, Tsome Nebiyat, Filseta, Tsome Hawaryat, Tsome Dihnet, Ramadan
* 🏛️ **Orthodox Saints (Nigs)**: Monthly commemoration/saints-day data for calendar grids
* 🏷️ **Holiday Filtering**: Filter holidays by type (`public`, `christian`, `muslim`, etc.)
* 📆 **Date Arithmetic**: Add/subtract days, months, years (13-month calendar support)
* 📏 **Date Difference & Distance**: Precise diffs plus human-friendly "distance to date/holiday" strings
* 🌐 **Calendar Preference**: Render dates in Ethiopian or Gregorian on demand
* 🔠 **Localized Formatting**: Amharic and English support
* 🔢 **Geez Numerals**: Convert integers to ግዕዝ numeral strings
* ⏰ **Ethiopian Time Support**: 12-hour Ethiopian ↔ 24-hour Gregorian
* 🗓️ **Calendar Grids**: Monthly/yearly calendar generation, with holiday/saint overlays and console printing
* 🧾 **Serialization**: `to_json()` for clean `Kenat` → dict/JSON output
* ⚠️ **Structured Errors**: Typed exceptions with `to_json()` for consistent error handling

---

## 🚀 Installation

Install the library from source:

```bash
pip install kenat
```

For development/testing:

```bash
pip install -e ".[test]"
```

---

## 🟢 Quick Sta
