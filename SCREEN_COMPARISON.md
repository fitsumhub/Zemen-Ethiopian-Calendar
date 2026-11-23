# Screen Comparison — EthioCal vs Nati Calendar (benchmark)

**Date:** 2026-11-15  
**Note:** Nati UI details are inferred from public Play Store copy and reviews. Exact layouts unavailable without installing Nati.

| Screen | Nati (publicly known) | EthioCal before | EthioCal target |
|--------|----------------------|-----------------|-----------------|
| Entry / Home | Calendar-first; dual dates | Separate Home dashboard + Calendar | **Calendar is primary tab** |
| Month grid | Dual Eth/Greg; swipe months | Dual cells; no swipe pager | Swipeable months + clearer cells |
| Day view | Dedicated day agenda | Day mode + inspector list | Selected-day panel under grid |
| Converter | Simple Eth↔Greg | 6 sub-tabs (powerful but busy) | Keep power; cleaner chrome |
| Holidays | Saints, national, Islamic | Annual + fasting + saints + cards | Keep; clearer categories |
| Events / Agenda | Tasks, events, notes, filters | Events CRUD + ICS | Agenda polish; notes later |
| Settings | Themes, languages | Strong prefs; stub widgets/sync | Themes + real widgets/sync P0 |
| Widgets | Praised | Dialog stub only | Native widgets P0 |
| News / Weather / PL | Present | Absent | **Not in core v1** |
| Onboarding | Unknown | 4-page premium dark | Keep; align tokens |

## Information architecture

| | Before | After |
|--|--------|-------|
| Tabs | 6 (Home, Cal, Convert, Holidays, Events, Settings) | **5** (Calendar, Convert, Holidays, Agenda, More) |
| Redundancy | Home vs Calendar compete | Single calendar-first surface |

## Visual hierarchy goals

1. Month name + year (Eth) primary  
2. Gregorian range secondary  
3. Grid dual numerals  
4. Selected day title + events  
5. FAB add event  
