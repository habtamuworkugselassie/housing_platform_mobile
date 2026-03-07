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
