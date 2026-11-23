# EthioCal Pro — Football Bug Tracker & Edge Case Mitigation (FOOTBALL_BUG_TRACKER.md)

**Document Version:** 2.0.0  
**Last Updated:** November 2026  
**Status:** All Identified Bugs & Edge Cases Resolved

---

## 1. Resolved Issues

| Bug ID | Component | Description | Root Cause | Resolution | Status |
|---|---|---|---|---|---|
| **BUG-001** | `analysis_options.yaml` | 61 analyzer issues in `research_scratch` | Prototype files had incomplete syntax | Added `research_scratch/**` to `exclude` | ✅ Fixed |
| **BUG-002** | `league_detail_screen.dart` | RenderFlex overflow by 6.5px in rank badge | Rank row width constraint (28px) too tight for two-digit numbers with margin | Expanded column width to 32px with flexible text wrapping | ✅ Fixed |
| **BUG-003** | `football_screen.dart` | `invalid_use_of_protected_member` on `.state` | Riverpod 3.x deprecated direct `.state` assignment outside Notifiers | Refactored `footballFilterProvider` and `footballSearchProvider` to `NotifierProvider` | ✅ Fixed |
| **BUG-004** | All UI files | Deprecated `withOpacity` warnings in Flutter 3.27+ | Flutter recommended `withValues(alpha: ...)` | Replaced all `withOpacity` calls with `withValues(alpha: ...)` | ✅ Fixed |
| **BUG-005** | UI Themes | White screen contrast mismatch | Screens were rendering `#FFFFFF` backgrounds against dark canvas | Implemented 100% dark canvas color constancy (`#121212`, `#1E1E1E`, `#2C2C2E`) | ✅ Fixed |
| **BUG-006** | `football_test.dart` | `Serie A` test assertion failing in default test window | Viewport height was 600px causing list item to be unrendered | Set explicit physical size in test tester (`800x1400`) | ✅ Fixed |

---

## 2. Edge Case Protection

1. **Network Disconnection / Flight Mode:**
   - Multi-tier fallback: Memory cache ➔ Offline static dataset matching authentic 2026-2027 league fixtures and standings.
   - Distinct UI status badge: "Offline · Cached data" with retry trigger.
2. **Empty Lineups / Events in Early Scheduled Matches:**
   - Clear placeholder cards stating "Match has not started yet" or "Lineups not announced yet" instead of crashing or showing broken widgets.
3. **Timer Leaks on Backgrounding:**
   - All polling timers are cancelled upon widget disposal (`ref.onDispose(() => _timer?.cancel())`).
