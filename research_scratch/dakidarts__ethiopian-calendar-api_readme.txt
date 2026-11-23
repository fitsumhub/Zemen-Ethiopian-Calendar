# Ethiopian Calendar API

[![Dakidarts](https://img.shields.io/badge/Dakidarts-Docs-blue)](https://dakidarts.com/api/ethiopian-calendar-api/)
[![GitHub Issues](https://img.shields.io/badge/GitHub-Issues-orange)](https://github.com/dakidarts/ethiopian-calendar-api)
[![Version](https://img.shields.io/badge/version-0.0.2-green)](https://github.com/dakidarts/ethiopian-calendar-api)

![Ethiopian Calendar API](https://res.cloudinary.com/ds64xs2lp/image/upload/v1761298650/ethiopian-calendar-api_r3m1et.gif)


A **production-ready REST API** for converting between Ethiopian and Gregorian calendars, detecting leap years, retrieving full calendar information, holidays, Ethiopian time, and batch conversions. Supports optional language translation, timezone-aware responses, and full month/year lookups.


---


## What's New in v0.0.2 (Aug 26, 2026)

- **13 new endpoints**: `/status`, `/convert`, `/convert-year`, `/date-range`, `/year`, `/year/gregorian`, `/holidays`, `/next-holiday`, `/countdown`, `/difference`, `/time`, `/month-names`, `/batch`
- **Fixed core conversion**: replaced buggy `ethiopian_date` library with a correct, dependency-free Julian-based implementation — no more crashes on early September dates or Pagumen
- **Consistent error format**: all errors now return `{"status": "error", "code", "error", "request_id"}` with stable codes
- **Holidays**: fixed Ethiopian feasts, movable Orthodox (Siklet, Fasika, Rikbe Kahinat via Julian Easter), fixed Gregorian national days, and approximate Islamic holidays (Eid al-Fitr, Eid al-Adha, Mawlid)
- **Ethiopian 12-hour sunrise clock**: convert standard time to the Ethiopian time system (6:00 AM = 12:00)
- **Batch conversion**: up to 100 dates in a single request
- **Month names in 4 scripts**: English, Ge'ez/Amharic, romanized Oromo, romanized Tigrinya
- **Request tracing**: every response includes `X-Request-ID` and `X-API-Version` headers


---


## Features

* Convert **Ethiopian ↔ Gregorian** dates (bidirectional)
* Get **current date** in both calendars with optional timezone support
* Detect **Ethiopian leap years** with next/previous leap year info
* Retrieve **full month calendars** for Ethiopian or Gregorian months
* Full **year views** for both calendars with day-level entries
* **Date range** conversion (up to 366 days)
* **Holiday calendar**: Ethiopian Orthodox, national, and Islamic holidays
* **Next holiday** countdown from any date
* **Date difference** calculator
* **Ethiopian time** (12-hour sunrise 
