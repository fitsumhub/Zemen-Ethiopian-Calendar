# Kenat / ቀናት ![NPM Version](https://img.shields.io/npm/v/kenat)

![banner](assets/img/kenatBanner.png)

![Build Status](https://github.com/MelakuDemeke/kenat/actions/workflows/test.yml/badge.svg?branch=main)
![npm bundle size](https://img.shields.io/bundlephobia/min/kenat)
![GitHub issues](https://img.shields.io/github/issues/MelakuDemeke/kenat)
![GitHub Repo stars](https://img.shields.io/github/stars/MelakuDemeke/kenat?logo=github&style=flat)
![GitHub forks](https://img.shields.io/github/forks/MelakuDemeke/kenat?logo=github&style=flat)
![GitHub commit activity](https://img.shields.io/github/commit-activity/m/MelakuDemeke/kenat?logo=github)
[![npm downloads](https://img.shields.io/npm/dm/kenat.svg?style=flat-square)](https://www.npmjs.com/package/kenat)

---

# Kenat / ቀናት

📌 **Overview**  
Kenat (Amharic: ቀናት) is a comprehensive JavaScript library for the Ethiopian calendar. It provides a complete toolset for developers, handling date conversions, advanced formatting, full date arithmetic, and a powerful, authentic holiday calculation system based on the traditional **Bahire Hasab (ባሕረ ሃሳብ)**.

---

## 📚 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
  - [Requirements](#requirements)
  - [TypeScript Support](#typescript-support)
  - [Import Options](#import-options)
- [Quick Start](#-quick-start)
- [Design Principles](#-design-principles)
- [Bahire Hasab & Holiday System](#-bahire-hasab--holiday-system)
- [More API Examples](#-more-api-examples)
  - [Date Arithmetic](#date-arithmetic)
  - [Comparing Dates](#comparing-dates)
  - [Start / End of a Period](#start--end-of-a-period)
  - [Date Difference & Distance API](#date-difference--distance-api)
  - [Calendar Generation](#calendar-generation)
  - [Fasting Periods](#fasting-periods)
  - [Holiday Distance Helpers](#holiday-distance-helpers)
  - [Geez Numerals & Formatting](#geez-numerals--formatting)
  - [Calendar Preference (Ethiopian / Gregorian)](#calendar-preference-ethiopian--gregorian)
  - [Time Handling](#time-handling)
  - [Serialization](#serialization)
- [API Reference](#-api-reference)
- [Contribution Guide](#-contribution-guide)
- [Author](#-author)
- [Contributors](#-contributors)
- [License](#-license)

---

## ✨ Features

- 🔄 **Bidirectional Conversion**: Seamlessly convert between Ethiopian and Gregorian calendars with high precision.
- 🌓 **Calendar Preference**: Read or format any date as Ethiopian *or* Gregorian with a single `{ calendar }` option — no `i
