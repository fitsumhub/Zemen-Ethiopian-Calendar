# EthioCal Pro — UI/UX Design System

**Identity name:** Abyssinian Atelier  
**Benchmark quality:** Nati Calendar (principles only)  
**Updated:** 2026-11-15

---

## 1. Brand personality

- **Heritage-modern:** Ethiopian calendar culture, contemporary productivity.
- **Calm authority:** Accurate, trustworthy, quiet chrome.
- **Readable first:** Dual dates must never fight for attention.

Tagline tone: “ቀን መቁጠሪያ · Clear dual calendar”

---

## 2. Color tokens

Defined in `lib/core/theme/app_colors.dart`.

| Role | Light | Dark |
|------|-------|------|
| Background | Cool stone `#F2F4F7` | Ink `#0A0E14` |
| Surface | `#FFFFFF` | `#121821` |
| Elevated | `#E8ECF1` | `#1A2230` |
| Primary (default) | Brass dark `#8B6914` | Brass `#C9A227` |
| Secondary | Highland green `#0D6B4C` | Emerald `#1FA87A` |
| Danger / Sunday | `#B42318` / `#DC2626` | same family |
| Outline | `#D5DCE5` | `#2A3548` |

**Accent palettes (settings):** GOLD_EMERALD (default), ROYAL_INDIGO → sapphire navy, CRIMSON, TERRACOTTA (clay).

**Avoid:** purple-on-white clichés, warm cream newspaper layouts, glow stacks.

---

## 3. Typography

| Role | Family | Use |
|------|--------|-----|
| Display | Fraunces (Google Fonts) | Large Eth day numbers, hero titles |
| UI | Outfit (Google Fonts) | Labels, body, nav, buttons |

Scale via `AppTheme._textTheme` in `lib/core/theme/app_theme.dart`.

---

## 4. Spacing & radius

| Token | Value |
|-------|-------|
| Page padding | 16 |
| Section gap | 12–16 |
| Card radius | 20 |
| Cell radius | 12–14 |
| Pill radius | 999 |
| Nav height | 68 |

---

## 5. Components

| Component | File / location |
|-----------|-----------------|
| Atmosphere gradient | `AppAtmosphere` |
| Panel / section / pill | `AppPanel`, `AppSectionLabel`, `AppPill` |
| Logo | `EthioCalLogo` |
| Dual day cell | `DualDateDayCell` (premium calendar) |
| Month pager | `SwipeableMonthPager` |

**Interaction rules**

- Selected day: primary border + soft fill.
- Today: filled primary circle on Eth numeral.
- Holiday: red numeral or red ribbon/dot.
- Event: brass/amber dot.
- Fasting: green micro-dot (when enabled).

---

## 6. Navigation IA (Nati-inspired simplicity)

**5 destinations** (reduced from 6):

1. **Calendar** — primary product (month grid + day agenda)
2. **Convert** — Eth ↔ Greg, time, tools
3. **Holidays** — feasts, fasting, saints
4. **Agenda** — personal events/tasks
5. **More** — settings, appearance, about

Home dashboard content (heritage proverb, fasting strip) lives in the **selected-day / today panel** on Calendar to avoid dual competing “homes.”

---

## 7. Motion

- Month change: horizontal `PageView` (300–350ms easeOutCubic)
- Day selection: ink + subtle scale ≤ 1.02
- Bottom sheets for day detail when needed
- Prefer `InkSparkle` / Material 3 defaults over decorative glow

---

## 8. Accessibility

- Min tap target 44×44 logical px for day cells (via aspect ratio + padding)
- Sunday/holiday red never sole information carrier (also dots/labels)
- Contrast: primary on surface checked for light/dark themes
- Amharic/Geez: allow slightly larger numerals when Geez mode on

---

## 9. Originality checklist

- [x] Original palette & logo painter
- [x] Original typography pairing
- [ ] No Nati screenshot assets in repo
- [ ] No Nati package names / trademarks in store listing
