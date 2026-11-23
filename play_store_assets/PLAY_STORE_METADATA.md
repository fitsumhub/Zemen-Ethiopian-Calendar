# Google Play Console Release Package & Store Metadata
## Zemen: Ethiopian Calendar (ዘመን)

- **Application ID / Package Name:** `com.zemen.calendar`
- **Default Language:** English (United States) - en-US
- **Target Audience:** Everyone (Productivity & Lifestyle)

This document contains everything needed to publish **Zemen: Ethiopian Calendar** to Google Play Console.

---

## 1. Store Listing Information

### App Title (Max 30 characters)
```text
Zemen: Ethiopian Calendar
```
*(Alternative in Amharic):* `ዘመን፡ የኢትዮጵያ ቀን መቁጠሪያ`

### Short Description (Max 80 characters)
```text
Ethiopian calendar (ዘመን) with Gregorian sync, holidays, converter & football.
```
*(Exact length: 77 characters)*

### Full Description (Max 4,000 characters)
```text
Zemen (ዘመን) is the premier dual Ethiopian and Gregorian calendar application, combining authentic Ethiopian heritage with modern, high-performance design.

Whether you need to check today’s date in the Ethiopian Calendar (ዓመተ ምሕረት / ዓመተ ዓለም), find upcoming Orthodox Christian fasting periods and national holidays, convert dates instantly, calculate exact age and date spans, or follow live football scores—Zemen is your all-in-one companion.

🌟 KEY FEATURES:

📅 Dual Ethiopian & Gregorian Calendar
• Seamlessly switch between Ethiopian (EC) and Gregorian (GC) views.
• Complete 13 months support (Meskerem to Pagume) with authentic leap-year calculations.
• Display dates in Western numerals or authentic Ge'ez numbers (፩, ፪, ፫...).
• Multi-view options: Month Grid, Year Overview, and Week View.

⛪ Bahire Hasab & Orthodox Tewahedo Heritage
• Precise astronomical and religious computus engine (ባሕረ ሐሳብ).
• Complete tracking of the 7 Great Fasts (ዐበይት አጽዋማት) including Hudadi (Abiy Tsom), Tsome Nebiyat, Filseta, and weekly Wednesday/Friday fasts.
• Daily Orthodox saints commemoration (የዕለቱ ቅዱሳን) and 30-day monthly feast cycles (Lideta, Maryam, Michael, Gebriel, Teklehaimanot, Giorgis, etc.).

🎉 Holidays & Cultural Observances
• Comprehensive catalog of Ethiopian national public holidays (Enkutatash, Meskel, Genna, Timkat, Adwa Victory Day, Patriots Day, Eid al-Fitr, Eid al-Adha).
• Detailed historical backgrounds and countdowns for all major observances.

🔄 Smart Date, Age & Span Converter
• Two-way instant converter between Ethiopian and Gregorian calendars.
• Precise Age Calculator: find your exact age in years, months, and days in both calendar systems.
• Date Span Calculator: calculate business days and intervals between any two historical or future dates.

⚽ Live Sports & Ethiopian Premier League
• Follow the Ethiopian Premier League (EPL ET), CAF Champions League, Premier League, La Liga, Serie A, and Champions League.
• Live scores, fixtures, standings, top scorers, and club badges.

📱 Modern Widgets & Customization
• Beautiful, glanceable Android Home Screen widgets in multiple styles (Minimal, Parchment, Emerald, Coral, and Noir).
• Elegant Dynamic Theming: Light, Dark, and AMOLED True Black modes with customizable accent palettes.
• Full multi-language support: English, Amharic (አማርኛ), Afaan Oromoo, and Tigrinya (ትግርኛ).
• 100% offline-first: core calendar calculations, conversions, and holidays work without internet connection.

Your Time. Your Tradition. Your Calendar.
Download Zemen today!
```

---

## 2. Categorization & Contact Details

* **Application Type:** App
* **Category:** Productivity / Tools
* **Tags / Keywords:** Calendar, Ethiopian Calendar, Zemen, Bahire Hasab, Habesha, Date Converter, Ge'ez, Orthodox Holidays.
* **Content Rating:** Everyone (3+)

---

## 3. Data Safety Declaration (Google Play Form)

Google Play requires developers to complete the Data Safety questionnaire. Based on Zemen's architecture:

| Category | Collected? | Shared? | Purpose | Optional/Required |
| :--- | :---: | :---: | :--- | :--- |
| **Personal Info (Name, Email)** | **No** | **No** | Not collected. | N/A |
| **Financial / Health / Location** | **No** | **No** | Not collected. | N/A |
| **Device or other IDs** | **Yes** | **Yes** | **Advertising & Analytics** (via Google Mobile Ads / AdMob SDK). | Required by AdMob |
| **App Activity (Crash logs)** | **No** | **No** | Not transmitted to 3rd party servers. | N/A |

### Answers to Data Safety Questions:
* **Does your app collect or share any user data?** `Yes` (Due to Google AdMob advertising ID).
* **Is all user data encrypted in transit?** `Yes` (All network communications use HTTPS).
* **Do you provide a way for users to request data deletion?** `Yes` (User can clear local preferences or reset data in Settings).

---

## 4. Required Store Graphic Assets

The following assets have been prepared in `play_store_assets/`:
1. `app_icon_512x512.png` — 512 × 512 px 32-bit PNG high-resolution store icon.
2. `feature_graphic_1024x500.png` — 1024 × 500 px promotional feature banner.
3. Screenshots — Capture 2 to 8 high-resolution screenshots from your phone or web preview (`http://localhost:5173`).

---

## 5. Privacy Policy Template (Deploy to GitHub Pages, Notion, or Website)

Google Play **mandates** a public Privacy Policy URL. You can host the markdown or HTML below on GitHub Pages, Google Sites, or any free hosting:

```markdown
# Privacy Policy for Zemen: Ethiopian Calendar
**Last updated:** November 2026

Zemen: Ethiopian Calendar ("we", "our", or "the app") respects your privacy. This policy outlines our data collection practices.

### 1. Data Collection & Local Storage
All your calendar notes, events, theme preferences, and language settings are stored locally on your device via SQLite and SharedPreferences. We do not operate user accounts, and your personal calendar data is never uploaded to any remote server.

### 2. Advertising & Analytics
The app integrates Google Mobile Ads (AdMob) to display advertisements. AdMob may collect and process device identifiers (such as Android Advertising ID), IP addresses, and diagnostic information to serve personalized or non-personalized ads in accordance with Google's Privacy Policy: https://policies.google.com/privacy.

### 3. Permissions
- **Notifications & Alarms (`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`):** Used solely to trigger user-scheduled event and holiday reminders locally on your device.
- **Internet (`INTERNET`):** Used to retrieve live football scores and serve AdMob ads.

### 4. Children’s Privacy
Our service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children.

### 5. Contact Us
If you have any questions or suggestions about our Privacy Policy, contact us at: support@zemenapp.com
```
