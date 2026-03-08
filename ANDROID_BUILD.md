# Android build & packaging

## Prerequisites

- Flutter SDK installed and on PATH
- Android SDK (Android Studio or command-line tools)
- Backend running on your Droplet (or localhost for debug)

## 1. Point the app to your Droplet (production)

By default the app uses `http://localhost:8080/api/v1`. To use your Droplet backend (like the frontend), pass the API base URL at **build time** via `--dart-define`:

```bash
# Replace YOUR_DROPLET_IP with your server's public IP (e.g. 164.92.1.2)
export API_BASE_URL="http://YOUR_DROPLET_IP:8080/api/v1"

# Build APK (installable on devices/side-load)
flutter build apk --dart-define=API_BASE_URL=$API_BASE_URL

# Or build App Bundle (for Play Store upload)
flutter build appbundle --dart-define=API_BASE_URL=$API_BASE_URL
```

One-liner without env var:

```bash
flutter build apk --dart-define=API_BASE_URL=http://YOUR_DROPLET_IP:8080/api/v1
```

**HTTPS (recommended for production):** If your Droplet has a domain and SSL (e.g. Nginx + Let's Encrypt):

```bash
flutter build apk --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
```

All API calls and property image URLs will use this base URL. No code changes needed between debug (localhost) and release (Droplet).

## 2. Build outputs

| Command | Output path |
|--------|-------------|
| `flutter build apk` | `build/app/outputs/flutter-apk/app-release.apk` |
| `flutter build appbundle` | `build/app/outputs/bundle/release/app-release.aab` |

- **APK**: Install directly on a device or share for testing (`adb install build/app/outputs/flutter-apk/app-release.apk`).
- **AAB**: Upload to Google Play Console for distribution.

### Reduce app size

This project has **release shrinking** enabled (minify + shrinkResources in `android/app/build.gradle`). To get smaller builds:

1. **Split APKs by ABI** (recommended for sideloading) – one APK per CPU type instead of one fat APK. Each file is much smaller; users install the one that matches their device:
   ```bash
   flutter build apk --dart-define=API_BASE_URL=http://209.38.204.219:8080/api/v1 --split-per-abi
   ```
   Outputs: `app-armeabi-v7a-release.apk`, `app-arm64-v8a-release.apk`, `app-x86_64-release.apk`. Use **arm64-v8a** for most current phones.

2. **Obfuscate and strip debug info** – smaller APK, symbols saved separately for crash reports:
   ```bash
   flutter build apk --dart-define=API_BASE_URL=... --obfuscate --split-debug-info=build/app/outputs/symbols
   ```

3. **Combine for smallest release APK**:
   ```bash
   flutter build apk --dart-define=API_BASE_URL=http://209.38.204.219:8080/api/v1 --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols
   ```

4. **Play Store** – upload an **App Bundle** (`flutter build appbundle --dart-define=API_BASE_URL=...`). Google serves optimized, per-device APKs (smallest download for users).

### Flutter logos and unnecessary assets removed

To keep the app smaller and unbranded:

- **Launcher icon:** The default Flutter logo mipmaps (five PNGs in `mipmap-*`) were removed and replaced with a single **drawable** (`res/drawable/ic_launcher.xml`), a small XML shape. You can replace this with your own icon (e.g. add `mipmap-*` assets and point `AndroidManifest` back to `@mipmap/ic_launcher`, or use a vector in `drawable`).
- **Unused dependencies:** `cupertino_icons` and `flutter_svg` were removed from `pubspec.yaml` (not used in the app), which reduces font and code size.
- **Launch screen:** Uses a black drawable (no Flutter logo); see the previous section for splash behavior.

Run `flutter pub get` after pulling these changes.

## 3. Debug build (localhost)

```bash
flutter run
# or
flutter build apk --debug
```

Uses `http://localhost:8080/api/v1` (default in `lib/core/network/api_config.dart`). For an emulator, `localhost` is the host machine; for a physical device, use your machine’s LAN IP or run the app with a debug build that uses a different base URL via `--dart-define` if needed.

## 4. Network security (Android)

- **HTTP**: This project allows cleartext traffic (`network_security_config.xml` + `usesCleartextTraffic`) so that release builds can call `http://DROPLET_IP:8080` without errors. For production, prefer HTTPS and a proper domain.
- **HTTPS**: No extra config needed; use `https://` in `API_BASE_URL`.

## 5. Checklist before release

1. Set `API_BASE_URL` to your Droplet (or production API) when running `flutter build apk` or `flutter build appbundle`.
2. Ensure the Droplet firewall allows inbound traffic on the backend port (e.g. 8080 or 443).
3. For Play Store: use `app-release.aab` from `flutter build appbundle` and follow Google Play’s signing and upload steps.

## 6. Troubleshooting

### "No route to host" / "Could not GET ... dl.google.com"

This means **Gradle cannot reach Google’s servers** to download the Android Gradle Plugin and other build artifacts. It’s a **network/connectivity** issue on your machine, not a project bug.

**What to do:**

1. **Check internet** – Open `https://dl.google.com` in a browser. If it doesn’t load, your network can’t reach Google.
2. **VPN** – If you use a VPN, try turning it off or switching region; some VPNs block or misroute traffic to Google.
3. **Firewall / corporate network** – Corporate or school networks often block or restrict access to Google. Try another network (e.g. mobile hotspot or home Wi‑Fi).
4. **Retry later** – Short-lived network or DNS issues can cause this; run the same build again after a few minutes.
5. **DNS** – Try switching DNS (e.g. 8.8.8.8 or 1.1.1.1) and run the build again.

Once your machine can reach `dl.google.com`, the same `flutter build apk` command should work without changing any project files.

### Empty data on Android while iOS shows data (prod URL)

If the **same prod URL works on iOS** but the **Android app shows empty lists** (e.g. no properties, no profile), the Android build almost certainly **does not have the prod URL** baked in.

- The API base URL is set **at build time** via `--dart-define=API_BASE_URL=...`. If you build the APK without that flag, the app uses the default `http://localhost:8080/api/v1`, so on a real device it gets no data.
- **Fix:** Rebuild the APK with the prod URL and reinstall:
  ```bash
  flutter build apk --dart-define=API_BASE_URL=http://209.38.204.219:8080/api/v1
  ```
  Then install the new APK (e.g. `build/app/outputs/flutter-apk/app-release.apk`).
- **Check:** Open the app, sign in if needed, go to **Profile**. At the bottom you’ll see **API: &lt;url&gt;** (e.g. `API: http://209.38.204.219` or `API: http://localhost:8080`). That confirms which base URL this build is using.
