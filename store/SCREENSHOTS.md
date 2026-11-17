# Screenshot guidance (Google Play)

Play requires **at least 2 phone screenshots** (8 max). Requirements: PNG or JPEG, each side 320–3840 px,
longest side at most 2x the shortest side. Portrait 1080x1920 (9:16) is ideal for this portrait-only game.
Optional but recommended if you target tablets: 7-inch and 10-inch tablet screenshots.

## Ready-made starter set (generated)
`store/screenshots/` already contains 1080x1920 renders made by `scripts_tools/make_store_assets.sh`:
`01_menu`, `02_classic` (3D board, notes, a mistake), `03_dark` (dark theme), `04_cube` (Cube Sudoku),
`05_win` (celebration). Replace them with real device captures before launch if you prefer.

## Capturing from a device or emulator
```bash
scripts_tools/run_adb.sh install        # install the debug APK
scripts_tools/run_adb.sh launch
scripts_tools/run_adb.sh shot store/screenshots/device_01.png
```
Tips:
- Show real gameplay: a half-filled board with highlights, notes visible, and the number pad with badges.
- Capture both light and dark themes, the Cube mode and the win celebration.
- Keep the status bar clean (full battery, no notifications). On the emulator use *Extended controls ›
  Demo mode* or a fresh AVD.
- Do not add device frames that include third-party logos, and do not include text claims you cannot back up.

## Other graphics
| Asset | File | Size |
|---|---|---|
| App icon | `store/icon_512.png` | 512x512 PNG, 32-bit (Play applies its own mask) |
| Feature graphic | `store/feature_graphic_1024x500.png` | 1024x500 PNG/JPEG, no alpha |
| Promo video (optional) | — | YouTube URL |

Regenerate the icon and feature graphic with `scripts_tools/make_store_assets.sh`.
