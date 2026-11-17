# Google Play release checklist — Sudoku 3D (`com.aitechplay.sudoku3d`)

Policies change; confirm each item against the current Play Console UI/help before submitting.

## 0. Before you build
- [ ] `./scripts_tools/run_tests.sh` passes
- [ ] Try the game on a real device or emulator (`scripts_tools/run_adb.sh`), including: rotate/zoom the board,
      pause/resume, background the app and return, Android back button, a full win, a loss
- [ ] Frame rate check: play ~2 min, then `scripts_tools/run_adb.sh gfx` (aim for very few janky frames);
      if slow, turn off Settings › High quality graphics and compare
- [ ] Bump `version/code` (integer, must increase every upload) and `version/name` in `export_presets.cfg`
      (both presets)
- [ ] Target SDK is **36** (Play requires Android 16 / API 36 for new apps and updates since 2026-08-31) and min SDK 24
- [ ] No INTERNET permission in the exported manifest (`permissions/internet=false`)
- [ ] `CREDITS.md` is accurate; fill the placeholders in `store/privacy_policy.md` and `store/store_listing.md`

## 1. Build the signed bundle
- [ ] `scripts_tools/setup_android.sh` (once), `scripts_tools/make_keystore.sh` (once, **back the keystore up**)
- [ ] `scripts_tools/export_release.sh` → `build/sudoku3d-release.aab` (must be an **AAB**, 64-bit included)

## 2. Developer account and app creation
- [ ] Google Play developer account (one-time registration fee, identity verification)
- [ ] Create app: name **Sudoku 3D**, language, **Game**, **Free**; accept declarations
- [ ] Note: new personal accounts may have to run a **closed test with a minimum number of testers for 14 days**
      before applying for production access — check the current requirement in Play Console

## 3. App signing
- [ ] Use **Play App Signing** (default). Your keystore from `make_keystore.sh` is the *upload key*; Google holds the app signing key
- [ ] Keep `release.keystore` + passwords backed up (Play can reset a lost upload key, but it is slow)

## 4. App content (Policy › App content)
- [ ] **Privacy policy**: public URL to the hosted `store/privacy_policy.md`
- [ ] **Ads**: “No, my app does not contain ads”
- [ ] **App access**: all functionality available without login / special access
- [ ] **Content rating** (IARC questionnaire): category *Game*; answer **No** to violence, blood, sexual content, profanity,
      drugs/alcohol/tobacco references, gambling (real or simulated), user-generated content, user interaction/sharing,
      location sharing, digital purchases. Expected result: everyone / PEGI 3 / ESRB Everyone (shown after submitting)
- [ ] **Target audience and content**: choose age groups. If you include under-13s you must comply with the *Families* policy
      (no ads is helpful). Simplest accurate choice: 13+ (or 18+). The app has no child-directed marketing
- [ ] **Data safety form**:
  - Does your app collect or share any required user data types? → **No**
  - Data is not collected → no data-handling sections to fill; no encryption-in-transit claim needed (no network)
  - Data deletion: not applicable (nothing collected; local data removed by uninstalling)
  - Provide the privacy policy URL
- [ ] **Government apps / financial features / health / news app** declarations: all **No**
- [ ] Advertising ID declaration: the app does **not** use the advertising ID (no ads SDK)

## 5. Store listing (Grow › Store presence › Main store listing)
- [ ] App name, short + full description from `store/store_listing.md`
- [ ] App icon `store/icon_512.png`; feature graphic `store/feature_graphic_1024x500.png`
- [ ] Phone screenshots (≥2) from `store/screenshots/` (see `store/SCREENSHOTS.md`); optional tablet screenshots
- [ ] Contact email (and optional website/phone), category *Puzzle*, tags

## 6. Release
- [ ] Testing › Internal/Closed testing first: upload the `.aab`, add testers, install from the Play link, verify
- [ ] Production › Create release: upload AAB, release name (e.g. `1 (1.0.0)`), release notes
- [ ] Countries/regions, pricing = Free
- [ ] Check *Pre-launch report* warnings and the *App bundle explorer* (size, supported devices)
- [ ] Send for review; first review can take several days

## 7. After launch
- [ ] Keep targeting the newest required API level (check each summer)
- [ ] If you ever enable the AdMob hook (`autoload/ads_hook.gd`): add the INTERNET permission, update the privacy policy,
      the Data safety form and the Ads declaration **before** shipping that version
