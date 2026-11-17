# Sudoku 3D

Offline 3D Sudoku for Android, built with Godot 4 (GDScript, Mobile renderer).
Package: `com.aitechplay.sudoku3d`. No internet permission, ads, analytics or accounts.

## Status
- [x] Milestone 1: logic and tests
- [x] Milestone 2: 2D playable prototype
- [x] Milestone 3: 3D board, orbit camera, animations
- [x] Milestone 4: menus, daily puzzle, stats, settings, autosave/resume, pause/win/lose, safe area, back button
- [x] Milestone 5: audio, themes, quality setting, 3D Cube Sudoku (4x4x4)
- [x] Milestone 6: Android export preset, scripts, store assets and release checklist (build itself needs setup, see below)

## Run the tests
Requires Godot 4.7+ (installed at `~/Applications/Godot.app`, or set `GODOT=/path/to/godot`).

    ./scripts_tools/run_tests.sh

Test files live in `tests/test_*.gd`; every `test_*` method is run by `tests/run_tests.gd`.

## Logic (`scripts/logic/`)
- `solver.gd`: validator, conflict finder, MRV backtracking solver, solution counter, hints
- `generator.gd`: seeded generator; clues are removed only while the solution stays unique
- `daily.gd`: date-seeded daily puzzle (Mon/Tue Easy, Wed/Thu Medium, Fri/Sat Hard, Sun Expert)

## Play (3D by default; scenes/game_2d.tscn is the 2D fallback)
Open the project in Godot and press F5, or run:

    ~/Applications/Godot.app/Contents/MacOS/Godot --path .

Desktop shortcuts: 1-9 enter a digit, Backspace erase, arrows move, N notes, Z undo, H hint.

`scripts/game/game_model.gd` holds all game rules (shared by the future 3D view).

## 3D controls
Drag = rotate slightly, pinch (or mouse wheel / trackpad pinch) = zoom, double tap = reset view, tap = select a cell
(ray/plane picking). Screenshot helper: `godot --path . --write-movie out.png -- --demo` (add `--win` for the celebration).
3D code lives in `scripts/board3d/`.

## App flow (M4)
Splash -> Main menu (Continue / New Game / Daily Puzzle / Statistics / Settings) -> Difficulty -> Game
(pause, win, lose overlays). Autoload singletons live in `autoload/` (Settings, Stats, SaveGame, Nav, ThemeManager,
AdsHook - the AdMob hook is a disabled no-op). The game autosaves after every move and when the app loses focus;
Android back button / Esc pauses in-game and goes back in menus. Data is stored in Godot's `user://` folder
(settings.cfg, stats.json, savegame.json).

## Audio, themes, Cube Sudoku (M5)
- Audio is generated, original and CC0: `python3 scripts_tools/generate_audio.py` rewrites `assets/audio/`.
  `autoload/audio.gd` plays SFX (pooled) and the music loop, honouring the Sound / Music settings.
- Themes (Light, Dark, Ocean, Forest, Sunset) are palettes in `autoload/theme_manager.gd` and colour the UI and the 3D tiles.
- Settings -> "High quality graphics" toggles shadows and anti-aliasing for slower phones.
- Bonus mode **Cube Sudoku**: a 4x4x4 cube, digits 1-4. Each of the 4 layers is a 4x4 Sudoku (rows, columns, 2x2 boxes)
  and every vertical pillar contains 1-4 once. Logic: `scripts/logic/cube_sudoku.gd`; view: `scripts/board3d/cube_board_view.gd`.
  `GameModel` is shared by both modes through a small "rules" adapter. Drag to rotate (lower the camera to see the layers).
- Screenshot helpers (dev only): `-- --demo`, `--cube`, `--dark`, `--win`, `--top` after `--write-movie`.

## Android build and release (M6)
Package `com.aitechplay.sudoku3d`, min SDK 24, target SDK 36, portrait, no INTERNET permission, arm64 + armv7 (debug also x86_64).
Presets are in `export_presets.cfg`: **Android Debug APK** and **Android Release AAB** (Gradle build).

1. **Toolchain (once):** `scripts_tools/setup_android.sh` installs/checks, asking before each large download:
   Godot export templates (~1 GB), JDK 17 (~190 MB), Android SDK packages (build-tools 35.0.1, platform 35/36, CMake, NDK r28b ~1.5 GB),
   sets the Godot editor Java/SDK paths, installs the Gradle build template into `android/build`, and creates a debug keystore.
   Use `--yes` to skip prompts or `--skip-ndk` to skip the NDK.
2. **Debug APK + device:** `scripts_tools/export_debug.sh`, then `scripts_tools/run_adb.sh install` and `launch`
   (`logs`, `gfx` for frame stats, `shot` for screenshots).
3. **Release keystore (once):** `scripts_tools/make_keystore.sh` creates `~/sudoku3d-keystore/release.keystore` and `keystore.env`
   (outside the repo; `*.keystore`/`*.jks` are also gitignored). **Back it up. Never commit it.**
4. **Signed AAB:** bump `version/code` in `export_presets.cfg`, then `scripts_tools/export_release.sh` -> `build/sudoku3d-release.aab`.
5. **Play Console:** follow `store/RELEASE_CHECKLIST.md`. Listing text: `store/store_listing.md`; privacy policy template:
   `store/privacy_policy.md`; graphics: `store/icon_512.png`, `store/feature_graphic_1024x500.png`, `store/screenshots/`
   (regenerate with `scripts_tools/make_store_assets.sh`).
