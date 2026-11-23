# ZEMEN (ዘመን) — Play Store Launch Guide

**Brand:** ZEMEN · ዘመን  
**Tagline:** Your Time. Your Tradition. Your Calendar.  
**Package:** `com.zemen.calendar`  
**Version:** `1.0.0+1`  
**Status:** Release-ready after the checklist below

---

## What was fixed for production

1. **Upload signing** — `android/upload-keystore.jks` + `android/key.properties` wired in `build.gradle.kts`
2. **R8 minify/shrink** enabled for release with ProGuard keep rules
3. **Ads safety** — release builds request ads only when real AdMob unit IDs are set; otherwise ad-free
4. **AdMob App ID** injectable via `android/admob.properties`
5. **Removed unused** `READ_CALENDAR` / `WRITE_CALENDAR` permissions
6. **Privacy policy** file at `docs/privacy-policy.html`
7. **Listing docs** aligned with actual ads behavior

---

## Before you click “Send for review”

### A. Host privacy policy
1. Upload `docs/privacy-policy.html` to `https://ethiocal.app/privacy-policy.html`
2. Paste that URL in Play Console → App content → Privacy policy

### B. Signing (already generated locally)
- Keystore: `android/upload-keystore.jks`
- Alias: `upload`
- Passwords are in `android/key.properties` (gitignored)
- **Back up the keystore + passwords offline.** Losing them blocks updates.

### C. Ads (optional for v1)
**Current release behavior:** ad-free until production IDs are filled.

To monetize later:
1. Create AdMob app + ad units
2. Copy `android/admob.properties.example` → `android/admob.properties` with real App ID
3. Replace placeholders in `lib/core/ads/ad_config.dart`
4. Set `forceTestAds = false` (already false)
5. Rebuild AAB

### D. Play Console Data Safety
Declare:
- Approx. location / device IDs **only if ads enabled** (AdMob)
- App functionality data stored on device (events/preferences) — not shared
- Internet for optional football + optional ads

### E. Store listing (honest copy)

**App name:** ZEMEN  
**Short description:**  
ZEMEN — Ethiopian Calendar. Your Time. Your Tradition. Your Calendar.

**Full description highlights:**
- Dual Ethiopian / Gregorian calendar (Month, Week, Year, Day)
- Bahire Hasab movable feasts & Orthodox fasting
- National, Orthodox, Islamic & cultural holidays
- Date / time / age / Geez converters
- Local events + reminders + home widget
- Optional football scores (network)
- Works offline for core calendar features

Do **not** claim “100% ad-free forever” if you plan to enable AdMob later.  
For this build with placeholder AdMob units, you may say: “v1.0 launches without ads.”

---

## Build commands

```bash
flutter analyze
flutter test
flutter build appbundle --release
```

AAB output: `build/app/outputs/bundle/release/app-release.aab`

---

## Store assets checklist

- [ ] Feature graphic 1024×500
- [ ] Phone screenshots (at least 2)
- [ ] Hi-res icon 512×512
- [ ] Privacy policy URL live
- [ ] Content rating questionnaire
- [ ] Target audience / news apps declarations if prompted
