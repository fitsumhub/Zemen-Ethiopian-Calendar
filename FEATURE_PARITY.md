# Feature Parity Matrix

**Updated:** 2026-11-15

Legend: ✅ Present · 🟡 Partial · ❌ Missing · 🚫 Out of scope (v1)

## vs Nati Calendar (product benchmark)

| Feature | Nati | EthioCal Flutter | Notes |
|---------|------|------------------|-------|
| Dual Eth/Greg month view | ✅ | ✅ | Improving cell clarity |
| Swipe month navigation | ✅ | 🟡 → ✅ | PageView month pager |
| Day view / agenda | ✅ | ✅ | Under-grid panel |
| Date converter | ✅ | ✅ | Plus time, age, Bahire Hasab, Geez, world |
| Holidays + saints | ✅ | ✅ | |
| Islamic/Hijri holidays | ✅ | 🟡 | Limited vs Nati |
| Fasting tracking | ✅ | ✅ | Markers + guide |
| Personal events + reminders | ✅ | ✅ | |
| Tasks + subtasks + notes | ✅ | 🟡 | Events only; no notes/subtasks yet |
| Agenda filters | ✅ | 🟡 | Category chips |
| Home widgets | ✅ | ❌ | Kotlin reference exists; Flutter gap |
| Google/device calendar sync | ✅ | ❌ | Permissions only |
| Multilingual (Am/Tir/Orm/En) | ✅ | ✅ | + French; incomplete string coverage |
| Offline core | ✅ | ✅ | |
| Age / date arithmetic | ✅ | ✅ | Age tab; harden tests |
| Weather / News | ✅ | 🚫 | Removed from EthioCal |
| Football | ✅ | ✅ | Offline mock leagues, schedule, standings |
| Ads | ✅ | 🚫 | Stay ad-free for premium trust |

## vs Original Kotlin app (`app/`)

| Feature | Kotlin | Flutter |
|---------|--------|---------|
| Calendar engines | ✅ | ✅ Ported + tests |
| 6 main screens | ✅ | ✅ (now 5-tab IA) |
| Room events | ✅ | sqflite |
| Widgets | ✅ | ❌ |
| Calendar sync | ✅ | ❌ |
| Alarm snooze/done | ✅ | 🟡 |
| Onboarding | ✅ | ✅ |

## Migration status

Flutter is the **primary** shippable app. Kotlin under `app/` and `calendar-core/` remains reference. Migration of engines/UI screens is largely complete; **native platform features** (widgets, sync) remain.
