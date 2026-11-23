# Nati Calendar — Product & Design Analysis

**Reference app:** Ethiopian Calendar & Converter (`com.nati.cal`) by Nati Gossaye  
**Play Store:** https://play.google.com/store/apps/details?id=com.nati.cal  
**Analyzed:** 2026-11-15  
**Sources:** Google Play listing, AppBrain/Uptodown/APK mirrors, public reviews, historical feature blurbs  
**Method constraint:** No APK reverse-engineering; no proprietary assets copied. UI layout inferences are from public marketing copy + user reviews only.

---

## 1. Product summary

| Metric | Public data |
|--------|-------------|
| Rating | ~4.6–4.7 ★ (14K+ reviews) |
| Installs | 1M–2M+ |
| Platform | Android 7.0+ |
| Monetization | Free; contains ads; in-app purchases |
| Positioning | Dual Eth/Greg calendar + converter + holidays + productivity for Ethiopians worldwide |

**Positioning takeaway:** Nati wins on *simplicity of the calendar-first experience*, multilingual offline core, and habit-forming daily use—not on exotic niche tools alone.

---

## 2. Feature inventory (publicly documented)

### Confirmed (Play Store / change logs)

| Area | Capability |
|------|------------|
| Dual calendar | Ethiopian + Gregorian shown together; instant conversion |
| Languages | Amharic, Tigrinya, Oromo, English |
| Offline | Calendar, tasks, conversion work offline |
| Holidays | Orthodox saint days, national holidays, Islamic/Hijri dates |
| Fasting | Tsom tracking / notifications (changelog) |
| Productivity | Tasks (due dates, subtasks), events (reminders), notes, filtered agenda |
| Widgets | Home-screen widgets (users praise cleanliness) |
| Date tools | Age calculator, date arithmetic (changelog) |
| Sync | Device / Google Calendar sync (changelog) |
| Extras | Weather tab, news tab, Premier League fixtures/standings |

### Historical / older blurbs (may still apply)

- Month View + Day View
- Swipe left/right between months/days
- Event days marked with a ribbon/marker
- Simple Eth ↔ Greg converter

### Unavailable / not verifiable from public sources

| Item | Status |
|------|--------|
| Exact pixel layouts, spacing, type scales | **Not available** without installing the app |
| Exact color hex values / component library | **Unknown** |
| Exact bottom-nav IA | **Inferred only** |
| Animation curves / motion specs | **Unknown** |
| Onboarding flow screens | **Unknown** |
| Settings taxonomy | **Unknown** |
| Proprietary icons / branding | **Must not be copied** |

---

## 3. Design principles inferred (quality bar)

These are **principles**, not copies of Nati UI:

1. **Calendar-first** — The month grid is the product, not a secondary tab behind a marketing dashboard.
2. **Dual dates everywhere** — Ethiopian primary, Gregorian secondary (or reverse via setting), always at a glance.
3. **Glanceable markers** — Holidays/events readable as small ribbons/dots without cluttering cells.
4. **Swipe navigation** — Muscle memory: swipe months / days.
5. **Month + Day duality** — Month for overview; Day for agenda depth.
6. **Low chrome** — Few competing toolbars; clear hierarchy.
7. **Offline trust** — Core calendar never depends on network.
8. **Multilingual** — Language feels first-class, not bolted on.
9. **Widget as brand** — Home screen presence drives retention.
10. **Polished themes** — Users explicitly praise theme/widget polish after updates.

---

## 4. What users love (reviews)

- Organized religious / fasting dates
- Smooth UI and clean widgets
- “Best Ethiopian calendar” sentiment among fans
- Weather + fasting remaining days as helpful extras

## 5. What users criticize (competitive openings for EthioCal)

- Elapsed-time / age arithmetic inconsistencies between Eth↔Greg paths
- Occasional “wrong date” reports (often device Gregorian settings)
- Desire for richer calendar imagery (hardcopy-style visuals)
- Ads / progressive quality concerns from some reviewers

**EthioCal strategy:** Match Nati’s *clarity and calendar-first UX*, then win on **calculation accuracy**, **Bahire Hasab depth**, **ad-free / privacy-first offline core**, and **heritage content**—without copying news/football extras unless they serve our brand later.

---

## 6. EthioCal response (product decisions)

| Nati strength | EthioCal response |
|---------------|-------------------|
| Calendar-first home | Make **Calendar** the primary tab; fold today/heritage into selected-day panel |
| Swipe months | `PageView` month navigation |
| Dual Eth/Greg cells | Premium dual-number day cells |
| Simple converter | Keep converter; reduce tab chrome |
| Agenda | Keep Events as Agenda; improve cards |
| Widgets | Port native widgets (P0 native gap) |
| Themes | Original Abyssinian Atelier system |
| News / PL / Weather | **Out of scope for v1 premium core** (optional later) |

---

## 7. Legal / originality

- Do **not** copy Nati logos, screenshots as assets, or proprietary code.
- Recreate **underlying UX principles** with EthioCal branding (logo painter, brass/highland palette, Fraunces+Outfit type).
