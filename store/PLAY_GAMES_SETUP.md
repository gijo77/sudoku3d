# Google Play Games setup — Sudoku 3D

Code side (done in v1.3.0): plugin `addons/GodotPlayGameServices` (v3.4.0, MIT), autoload `PlayGames`
(`autoload/play_games.gd`), cloud merge `scripts/game/cloud_save.gd`, IDs in `scripts/game/play_games_ids.gd`.
Game ID `209825244134` is set in both Android export presets (`godot_play_game_services/game_id`).
The app now declares the INTERNET permission (used only by Play Games).

## 1. Properties
Play Console › Play Games services › Configuration › **Edit properties** › turn **Saved games ON**.

## 2. Achievements (18) — Play Games services › Achievements › Create
All standard (not incremental), initial state **Revealed**. Points: Bronze 10, Silver 25, Gold 50 (total 510 of 1000).
Copy each achievement ID into `ACHIEVEMENTS` in `scripts/game/play_games_ids.gd` (Bronze, Silver, Gold order).

| Medal key | Name | Description | Points |
|---|---|---|---|
| winner | Bronze Winner | Win your first game | 10 |
| winner | Silver Winner | Win 10 games | 25 |
| winner | Gold Winner | Win 50 games | 50 |
| flawless | Bronze Flawless | Win a game with no mistakes | 10 |
| flawless | Silver Flawless | Win 10 games with no mistakes | 25 |
| flawless | Gold Flawless | Win 30 games with no mistakes | 50 |
| streak | Bronze Warm Streak | Solve the daily puzzle 3 days in a row | 10 |
| streak | Silver Warm Streak | Solve the daily puzzle 7 days in a row | 25 |
| streak | Gold Warm Streak | Solve the daily puzzle 30 days in a row | 50 |
| cube | Bronze Cube Explorer | Solve a Cube Sudoku | 10 |
| cube | Silver Cube Explorer | Solve 5 Cube Sudokus | 25 |
| cube | Gold Cube Explorer | Solve 20 Cube Sudokus | 50 |
| speed | Bronze Speedster | Win a classic game under par time | 10 |
| speed | Silver Speedster | Win 5 classic games under par time | 25 |
| speed | Gold Speedster | Win 20 classic games under par time | 50 |
| expert | Bronze Expert Mind | Win on Expert | 10 |
| expert | Silver Expert Mind | Win 5 games on Expert | 25 |
| expert | Gold Expert Mind | Win 15 games on Expert | 50 |

Play needs at least 5 achievements before the Play Games project can be published.

## 3. Leaderboards (5) — Play Games services › Leaderboards › Create
| Name | Score format | Ordering | Goes into |
|---|---|---|---|
| Best time · Easy | Time (milliseconds) | Smaller is better | `BEST_TIME[0]` |
| Best time · Medium | Time (milliseconds) | Smaller is better | `BEST_TIME[1]` |
| Best time · Hard | Time (milliseconds) | Smaller is better | `BEST_TIME[2]` |
| Best time · Expert | Time (milliseconds) | Smaller is better | `BEST_TIME[3]` |
| Total XP | Numeric | Larger is better | `TOTAL_XP` |

Icons are optional; Play uses a default icon.

## 4. Data safety (Play Console › App content › Data safety)
Follow Google's official guidance for the Play Games Services SDK:
https://developer.android.com/games/pgs/data-collection
The game itself sends only: achievement unlocks, leaderboard scores, and a Saved Games file with stats and
rewards progress. No ads, no analytics, no other SDKs. Data is encrypted in transit (HTTPS) and players can
delete their Play Games data from their Play Games profile.

## 5. Privacy policy
`store/privacy_policy.md` (copied to `docs/index.md` for GitHub Pages) now has a Google Play Games section.

## 6. Publish
After a build with the IDs is uploaded to closed testing and works for testers: Play Games services › **Review and publish**.
Testers listed in Play Games services › Testers can use it before publishing.
