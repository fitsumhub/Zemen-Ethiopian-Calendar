# Google Play Store Deployment Guide: Zemen Ethiopian Calendar

This document provides a step-by-step procedure to publish **Zemen: Ethiopian Calendar** (`com.zemen.calendar`) to the Google Play Store.

---

## 1. Release Status & Pre-Configured Assets

Your project is already configured and verified for release:

| Configuration Item | Status / Value | Location |
| :--- | :--- | :--- |
| **Application ID** | `com.zemen.calendar` | `android/app/build.gradle.kts` |
| **Current Version** | `1.0.0+1` (Version Code 1) | `pubspec.yaml` |
| **Target SDK** | `Android 15 (API 37)` | `android/app/build.gradle.kts` |
| **Min SDK** | `Android 7.0 (API 24)` | `android/app/build.gradle.kts` |
| **Keystore File** | `upload-keystore.jks` | `android/upload-keystore.jks` |
| **Keystore Credentials** | Configured | `android/key.properties` |
| **Production Bundle** | **Built & Signed** | `build/app/outputs/bundle/release/app-release.aab` |
| **Privacy Policy** | HTML Ready | `docs/privacy-policy.html` |
| **R8 / ProGuard** | Minified & Kept | `android/app/proguard-rules.pro` |

---

## 2. Step 1: Building Future App Bundles (.aab)

Whenever you make updates and want to release a new version:

1. Open `pubspec.yaml` and increment the version and build number:
   ```yaml
   version: 1.0.1+2 # Next release: version 1.0.1, build code 2
   ```
2. Run the release build command in your terminal:
   ```bash
   flutter build appbundle --release
   ```
3. Your signed production bundle will be output to:
   ```
   build\app\outputs\bundle\release\app-release.aab
   ```

---

## 3. Step 2: Host Your Privacy Policy

Google Play requires a publicly accessible HTTPS URL for your privacy policy before publishing.

### Recommended Free Hosting (GitHub Pages):
1. Push your repository to GitHub.
2. In your GitHub repository:
   - Go to **Settings** → **Pages**.
   - Under **Build and deployment**, select **Deploy from a branch**.
   - Set Branch to `main` (or your default branch) and folder to `/docs`.
   - Click **Save**.
3. Your privacy policy URL will be:
   ```
   https://<your-username>.github.io/<repo-name>/privacy-policy.html
   ```

*(Alternative: You can host `docs/privacy-policy.html` on Firebase Hosting, Vercel, Netlify, or Google Sites).*

---

## 4. Step 3: Google Play Console Setup

1. **Sign in / Create Account**:
   - Go to [Google Play Console](https://play.google.com/console).
   - If you don't have an account, register as an Individual or Organization ($25 one-time fee).
2. **Create New Application**:
   - Click **Create app** (top-right).
   - **App name**: `Zemen: Ethiopian Calendar (ዘመን)`
   - **Default language**: `English (United States)` or `Amharic (አማርኛ)`
   - **App or Game**: `App`
   - **Free or Paid**: `Free`
   - Accept the Developer Program Policies and US export laws, then click **Create app**.

---

## 5. Step 4: Complete the "Set up your app" Tasks

In the Google Play Console sidebar, go to **Dashboard** and complete the mandatory policy declarations:

### 1. Privacy Policy
- Paste your public HTTPS privacy policy URL:
  `https://<your-domain-or-github-pages>/privacy-policy.html`

### 2. App Access
- Select: **All functionality is available without special access** (no login or subscription required).

### 3. Ads
- Select: **Yes, my app contains ads** (Google AdMob SDK is integrated).

### 4. Content Ratings (IARC)
- Enter your email address.
- Select Category: **Utility, Productivity, Communication, or other**.
- Answer the questionnaire:
  - Violence, Sex, Language, Controlled Substances: **No**
  - Miscellaneous (User location sharing, physical goods): **No**
- Click **Save** and **Calculate Rating** (Typically receives `PEGI 3`, `Everyone / ESRB`, `USK 0`).

### 5. Target Audience & Content
- Target age group: Check **18 and over** and/or **13–17**.
  *(Tip: Selecting 13+ avoids the strict Designed for Families review program).*
- Could the store listing unintentionally appeal to children? Select **No**.

### 6. News Apps
- Select: **No, my app is not a news app**.

### 7. COVID-19 Contact Tracing
- Select: **My app is not publicly available COVID-19 tracing or status app**.

### 8. Data Safety Questionnaire
Based on the libraries used in Zemen Calendar (`google_mobile_ads`, `shared_preferences`, `sqflite`):
- Does your app collect or share any of the required user data types? Select **Yes**.
- Is all user data encrypted in transit? Select **Yes**.
- Do you provide a way for users to request data deletion? Select **Yes**.
- **Data Types Declared**:
  - **Device or other IDs**:
    - Under *Device or other IDs*, check *Device or other IDs*.
    - Collected: **Yes** (Shared: **Yes**, by Google AdMob).
    - Ephemeral: **No**.
    - Required / Optional: **Optional** (User can opt out via personalized ads settings).
    - Purpose: **Advertising or marketing**, **Analytics**.
  - **Calendar / User Events**:
    - Note: Your user events and notes are stored **strictly on-device in local SQLite**. They are **not** transmitted to external servers.

### 9. Government Apps
- Select: **No**.

### 10. Financial Features
- Select: **My app doesn't provide any financial features**.

---

## 6. Step 5: Store Listing (Metadata & Graphics)

Navigate to **Grow** → **Store presence** → **Main store listing**.

### Text Metadata:
- **App name** (up to 30 chars):
  ```
  Zemen: Ethiopian Calendar
  ```
- **Short description** (up to 80 chars):
  ```
  Dual Ethiopian & Gregorian calendar with Bahire Hasab, holidays, and widgets.
  ```
- **Full description**:
  ```text
  Zemen (ዘመን) is an authentic, executive Ethiopian and Gregorian calendar application designed for elegance, cultural precision, and daily utility.

  KEY FEATURES:
  • Dual Calendar View: Seamlessly switch between Ethiopian (ዓመተ ምሕረት) and Gregorian calendars.
  • Bahire Hasab Computus (ባሕረ ሐሳብ): Complete movable feast and fast calculations across centuries (ዓመተ ዓለም, ወንበር, አበቅቴ, መጥቅዕ, ጾመ ነቢያት, ዓቢይ ጾም, ፋሲካ).
  • Daily Commemorated Saints (የወሩ በዓላት): Full 1–30 Orthodox Tewahedo daily saint commemorations (ቅዱስ ሚካኤል, ማርያም, ጊዮርጊስ, ተክለ ሃይማኖት, መድኃኔ ዓለም).
  • Ethiopian Timekeeping (የኢትዮጵያ ሰዓት): Real-time conversion between 12-hour sunrise Ethiopian time and standard 24-hour time.
  • Date & Age Converter: Bidirectional date conversion with Ge'ez numeral support and exact age calculator.
  • Luxury Home-Screen Widgets: Android One UI-optimized widgets featuring interactive 1-tap refresh, daily saint badges, and Ge'ez numerals.
  • Event Management & Reminders: Schedule personal events and receive timely notifications without battery drain.
  • Offline First: Complete calendar conversion, computations, and saint lookups work 100% offline.
  ```

### Graphic Assets:
- **App Icon**: 512 × 512 px (PNG 32-bit, up to 1 MB).
- **Feature Graphic**: 1024 × 500 px (JPEG or 24-bit PNG, up to 15 MB).
- **Phone Screenshots**:
  - At least 2 screenshots (Recommended: 4–8 screenshots).
  - JPEG or 24-bit PNG, 16:9 or 9:16 aspect ratio (e.g. 1080 × 1920 px or 1080 × 2400 px).

---

## 7. Step 6: Uploading the Bundle & Release Tracks

Google Play offers several release tracks:

### Recommended Path:
1. **Internal Testing Track** (Immediate):
   - In Google Play Console sidebar, go to **Testing** → **Internal testing**.
   - Click **Create new release**.
   - Upload `build\app\outputs\bundle\release\app-release.aab`.
   - Enter Release name: `1.0.0 (1)`.
   - Release notes:
     ```text
     Initial release of Zemen Ethiopian Calendar with dual-date engine, Bahire Hasab computus, luxury widgets, and event management.
     ```
   - Click **Save** and **Review release**, then **Start rollout to Internal testing**.
   - Internal test builds are approved and installable within minutes on your test devices.

2. **Closed Testing Track** (Required for Personal Accounts created after Nov 2023):
   - Google requires 20 opt-in testers who test the app continuously for 14 days before applying for Production.
   - Go to **Testing** → **Closed testing** and create a track with your tester email list.

3. **Production Track**:
   - Go to **Release** → **Production**.
   - Click **Create new release** (or promote from Closed/Internal testing).
   - Select your uploaded `.aab`.
   - Click **Review release** → **Start rollout to Production**.
   - Google typically reviews new production releases within 1 to 3 business days.

---

## 8. Safety & Keystore Backup Notice

> [!CAUTION]
> **Never lose `android/upload-keystore.jks` or `android/key.properties`**.
> Google Play associates your `com.zemen.calendar` package with this exact signing key. If you lose this key, you will not be able to publish future updates to your app.
>
> Keep an offline backup of:
> 1. `android/upload-keystore.jks`
> 2. `android/key.properties`
> 3. `android/KEYSTORE_BACKUP.txt`
