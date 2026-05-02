# Pre-release checklist — Ethio Build Connect (`housing_platform_mobile`)

Use this before uploading to **Google Play** or the **App Store**. Fill the **Evidence** column (screenshot, PR link, or tester initials).

| # | Item | Where / how | Owner | Evidence |
|---|------|-------------|-------|----------|
| **Production config** |
| 1 | API points to **production** HTTPS base URL | `lib/core/network/api_config.dart` uses `String.fromEnvironment('API_BASE_URL', ...)`. Default is a dev/Droplet URL — **store builds must override** with `--dart-define`. | | |
| 2 | Release build smoke test | Install artifact built with the **same** `dart-define` as upload; verify login, listings, maps, image upload, share/open links. | | |
| 3 | No debug-only shortcuts | Search for TODO/FIXME, mock auth, hardcoded test users. | | |
| **Android** |
| 4 | **Release signing** (blocking for Play) | Copy `android/key.properties.example` → `android/key.properties`, add your `.jks`, set passwords/alias. **Without** `key.properties`, release still signs with **debug** (Play upload will fail until configured). | | |
| 5 | Version monotonicity | `pubspec.yaml` → `version: x.y.z+build` (`build` = Play `versionCode`). Or override: `flutter build appbundle --build-name x.y.z --build-number N`. Every Play upload needs a **higher** `versionCode`. | | |
| 6 | cleartext / network policy | **Release** builds merge `android/app/src/release/` → cleartext **off** + HTTPS-only network config. Debug/profile keep cleartext for local HTTP. Store **must** use `https://` `API_BASE_URL`. | | |
| **iOS** |
| 7 | Bundle ID matches App Store Connect | Xcode / `ios/Runner.xcodeproj` → `PRODUCT_BUNDLE_IDENTIFIER` must match the created app ID. | | |
| 8 | Display name | `Info.plist` → `CFBundleDisplayName` = **Ethio Build Connect** (already set). | | |
| 9 | **Privacy usage strings** | `ios/Runner/Info.plist` includes camera, photo library, add-photo, and microphone strings for `image_picker` / video. Adjust copy if product scope changes. | | |
| 10 | Version/build | Driven by Flutter: same `pubspec.yaml` or `--build-name` / `--build-number` on `flutter build ipa`. | | |
| **Legal & store listings** |
| 11 | Privacy policy URL | Live HTTPS page; linked in Play / App Store Connect. | | |
| 12 | Support contact | Email or URL monitored for store/user issues. | | |
| 13 | Screenshots & icon | Icon from `flutter_launcher_icons` (`assets/branding/ethio-build-connect-logo.png`). Capture screenshots per store size requirements. | | |
| **Quality** |
| 14 | Device matrix | At least: one older Android, one current Android, one iPhone size you target; test offline / permissions denied. | | |
| 15 | Backend / TLS | Prod API certificate valid; CORS/auth if web callbacks matter. | | |
| **Observability** |
| 16 | Crash reporting | **Not wired in `pubspec.yaml` today** — add Crashlytics or Sentry for release, upload symbols (iOS dSYM; Android mapping if minify stays on). | | |

---

## Commands aligned with this repo

**Production API base** (replace with your real HTTPS URL):

```bash
cd housing_platform_mobile

# Android App Bundle (Play Store)
flutter build appbundle \
  --dart-define=API_BASE_URL=https://YOUR_DOMAIN/api/v1 \
  --build-name 1.0.0 \
  --build-number 2

# Android APK (local QA)
flutter build apk --release \
  --dart-define=API_BASE_URL=https://YOUR_DOMAIN/api/v1

# iOS (after signing setup in Xcode)
flutter build ipa \
  --dart-define=API_BASE_URL=https://YOUR_DOMAIN/api/v1 \
  --build-name 1.0.0 \
  --build-number 2
```

**Single source of truth for version:** prefer bumping `version:` in `pubspec.yaml` (e.g. `1.0.1+2`) so Android and iOS stay in sync unless you intentionally override at build time.

---

## Critical gaps to close before first store submission

1. **Android:** Create `android/key.properties` from the example and use an upload/release keystore (Play rejects debug-signed uploads).
2. **API:** Ship store builds with `--dart-define=API_BASE_URL=...` pointing to **stable HTTPS** production; release Android builds disallow HTTP cleartext.
3. **Monitoring:** Add crash reporting before scaling traffic (still not in `pubspec.yaml`).

---

## Optional next steps (not in this checklist file)

- CI job that builds `appbundle` / `ipa` with pinned `API_BASE_URL` and secrets from a vault.
- Internal track / TestFlight for one full regression cycle before production rollout.
