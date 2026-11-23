# EthioCal Pro — Football API Coverage Map (FOOTBALL_API_COVERAGE.md)

**Document Version:** 1.0.0  
**Scope:** Verified Competition, Club, and Feature Coverage  

---

## 1. Supported Competitions

| Competition | Country / Region | Provider Source | Live Scores | Events Timeline | Lineups & Pitch | Match Stats | Standings Table | Ethiopian Date Support |
|---|---|---|---|---|---|---|---|---|
| **Ethiopian Premier League** | Ethiopia | Ethiopian Engine / API-Football (ID 556) | ✅ | ✅ | ✅ | ✅ | ✅ (18 Clubs) | ✅ Native |
| **English Premier League** | England | ESPN (`eng.1`) / API-Football (ID 39) | ✅ | ✅ | ✅ | ✅ | ✅ (20 Clubs) | ✅ Dual Display |
| **UEFA Champions League** | Europe | ESPN (`uefa.champions`) / API-Football (ID 2) | ✅ | ✅ | ✅ | ✅ | ✅ (League Phase) | ✅ Dual Display |
| **La Liga** | Spain | ESPN (`esp.1`) / API-Football (ID 140) | ✅ | ✅ | ✅ | ✅ | ✅ (20 Clubs) | ✅ Dual Display |
| **Serie A** | Italy | ESPN (`ita.1`) / API-Football (ID 135) | ✅ | ✅ | ✅ | ✅ | ✅ (20 Clubs) | ✅ Dual Display |
| **Bundesliga** | Germany | ESPN (`ger.1`) / API-Football (ID 78) | ✅ | ✅ | ✅ | ✅ | ✅ (18 Clubs) | ✅ Dual Display |
| **Ligue 1** | France | ESPN (`fra.1`) / API-Football (ID 61) | ✅ | ✅ | ✅ | ✅ | ✅ (18 Clubs) | ✅ Dual Display |
| **Ethiopia National Team (Walias)** | International | ESPN / API-Football (ID 31) | ✅ | ✅ | ✅ | ✅ | ✅ (Group Stage) | ✅ Dual Display |

---

## 2. Ethiopian Premier League Verified Clubs

The following Ethiopian Premier League clubs have verified badges, stadiums, and complete metadata:

1. **Saint George SC (Kidus Giorgis)** — Addis Ababa
2. **Ethiopia Nigd Bank (Commercial Bank of Ethiopia - CBE SA)** — Addis Ababa
3. **Mekelakeya SC (Defence Force)** — Addis Ababa
4. **Fasil Kenema SC** — Gondar
5. **Bahir Dar Kenema SC** — Bahir Dar
6. **Awassa Kenema SC (Hawassa City)** — Hawassa
7. **Sidama Bunna SC (Sidama Coffee)** — Hawassa
8. **Adama Kenema SC** — Adama
9. **Welwalo Adigrat University SC** — Adigrat
10. **Halaba Ketema SC** — Halaba
11. **Negelle Arsi SC** — Arsi
12. **Gamo Chencha SC** — Arba Minch
13. **Sheger Ketema SC** — Sheger
14. **Hadiya Hosaena SC** — Hosaena
15. **Ethiopian Medhin SC (Ethiopian Insurance)** — Addis Ababa
16. **Mebrat Hayl (Ethio Electric)** — Addis Ababa
17. **Welayta Dicha SC** — Sodo
18. **Dire Dawa City SC** — Dire Dawa

---

## 3. Data Field Mapping & Fallback Behavior

| Entity | Primary API Field | Fallback Behavior when Field is Missing |
|---|---|---|
| Match Score | `competitions[0].competitors[i].score` | Defaults to scheduled state or displays match time if score is null |
| Match Minute | `status.displayClock` | Uses match phase label (`1H`, `HT`, `2H`, `FT`) |
| Team Crest | `team.logos[0].href` or `team.logo` | Falls back to custom vector crest with official team lettermark and brand color |
| Event Minute | `keyEvents[i].clock.displayValue` | Calculated from elapsed match seconds |
| Lineup Formation | `rosters[i].formation` | Defaults to standard 4-3-3 if formation string is not provided |
| Venue Name | `gameInfo.venue.fullName` | Displays city/country or falls back to home stadium |
