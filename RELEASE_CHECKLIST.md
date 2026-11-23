# EthioCal Pro — Google Play Store Production Release Checklist

**Target Application:** EthioCal Pro  
**Package / Application ID:** `com.zemen.calendar`  
**Version:** 1.0.0 (Build 1)  
**Min SDK:** 24 · **Target SDK:** 37 · **Compile SDK:** 37

---

## 1. Production readiness matrix

| Item | Status | Notes |
|---|---|---|
| Application ID | ✅ | `com.zemen.calendar` |
| App label | ✅ | EthioCal Pro |
| Launcher icons | ✅ | Adaptive + density mipmaps |
| Target SDK 34+ | ✅ | targetSdk 37 |
| Upload keystore | ✅ | `android/upload-keystore.jks` + `key.properties` |
| R8 minify / shrink | ✅ | release buildType |
| Unused calendar perms removed | ✅ | No READ/WRITE_CALENDAR |
| Ads policy-safe without prod IDs | ✅ | `AdConfig.canRequestAds` gates all loaders |
| Privacy policy document | ✅ | Hosted: `https://zemen-football-proxy.aplusethiopia1.workers.dev/privacy-policy.html` |
| Honest store listing | ✅ | See `PLAY_STORE_LAUNCH.md` |

---

## 2. Permissions (declared)

| Permission | Purpose |
|---|---|
| `INTERNET` | Optional football + optional AdMob |
| `POST_NOTIFICATIONS` | User-scheduled reminders |
| `SCHEDULE_EXACT_ALARM` | Exact reminder timing |
| `RECEIVE_BOOT_COMPLETED` | Reschedule reminders after reboot |
| `VIBRATE` / `WAKE_LOCK` | Reminder UX |

---

## 3. Privacy & ads (accurate)

- Core calendar/events data stays on-device.
- AdMob is integrated but **release builds stay ad-free** until real unit IDs are supplied via `admob_defines.json` and `android/admob.properties`.
- UMP consent is used when ads are enabled in required regions.
- Hosted policy URL: `https://zemen-football-proxy.aplusethiopia1.workers.dev/privacy-policy.html`
- Football web proxy: `https://zemen-football-proxy.aplusethiopia1.workers.dev`

---

## 4. Build

```bash
flutter analyze
flutter test
# optional: copy admob_defines.json.example → admob_defines.json
flutter build appbundle --release --dart-define-from-file=admob_defines.json
./tool/build_web_release.ps1
```

Upload: `build/app/outputs/bundle/release/app-release.aab`

Full operator steps: `PLAY_STORE_LAUNCH.md`
