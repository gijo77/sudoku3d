# Sudoku 3D

Offline 3D Sudoku for Android, built with Godot 4 (GDScript, Mobile renderer).
Package: `com.aitechplay.sudoku3d`. No internet permission, ads, analytics or accounts.

## Status
- [x] Milestone 1: logic and tests
- [x] Milestone 2: 2D playable prototype
- [ ] 3: 3D visuals, 4: UI/menus, 5: polish/audio/themes, 6: Android release

## Run the tests
Requires Godot 4.7+ (installed at `~/Applications/Godot.app`, or set `GODOT=/path/to/godot`).

    ./scripts_tools/run_tests.sh

Test files live in `tests/test_*.gd`; every `test_*` method is run by `tests/run_tests.gd`.

## Logic (`scripts/logic/`)
- `solver.gd`: validator, conflict finder, MRV backtracking solver, solution counter, hints
- `generator.gd`: seeded generator; clues are removed only while the solution stays unique
- `daily.gd`: date-seeded daily puzzle (Mon/Tue Easy, Wed/Thu Medium, Fri/Sat Hard, Sun Expert)

## Play the 2D prototype
Open the project in Godot and press F5, or run:

    ~/Applications/Godot.app/Contents/MacOS/Godot --path .

Desktop shortcuts: 1-9 enter a digit, Backspace erase, arrows move, N notes, Z undo, H hint.

`scripts/game/game_model.gd` holds all game rules (shared by the future 3D view).
