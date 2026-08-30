# Live video broadcasting (mobile)

In-app live streaming for the Ethio Build Connect exhibition, backed by the
self-hosted **LiveKit** SFU. Visitors, exhibitors and organizers can broadcast
from their phone camera; anyone can watch the public "Live now" wall.

## User flow

- **Home → "Live from the exhibition"** banner → `LiveBroadcastsScreen`
  (the public wall of currently-live streams + a **Go live** button).
- **Watch:** tap a live card → `LiveViewerScreen` connects with a subscribe-only
  viewer token and renders the broadcaster's video.
- **Broadcast:** **Go live** → `GoLiveScreen`:
  1. Preview the camera, fill name + stream title, pick a role.
  2. **Request to go live** → creates a `REQUESTED` broadcast.
  3. The app polls status until an organizer **approves** it, then connects to
     LiveKit and publishes camera + mic.
  4. While live: switch front/back camera, mute/unmute, **End broadcast**.

### Role gating (matches the backend)

| Role       | Requirement                                   |
|------------|-----------------------------------------------|
| Visitor    | Anonymous — allowed                           |
| Exhibitor  | Must be **signed in**                         |
| Organizer  | Reserved for **admin / super-admin** accounts |

The UI enforces this up front; the backend re-checks it from the bearer token.

## API (base URL already includes `/api/v1`)

| Method | Path                                    | Purpose                       |
|--------|-----------------------------------------|-------------------------------|
| POST   | `/exhibition/live/request`              | Create a pending request      |
| GET    | `/exhibition/live`                      | Public wall of live streams   |
| GET    | `/exhibition/live/{id}`                 | Poll status (for approval)    |
| GET    | `/exhibition/live/{id}/publish-token`   | Broadcaster token (approved)  |
| GET    | `/exhibition/live/{id}/viewer-token`    | Subscribe-only viewer token   |

Implemented in `lib/core/services/live_service.dart`
(`liveServiceProvider` in `lib/core/providers/auth_provider.dart`).

## Native configuration

- **pubspec:** `livekit_client`, `permission_handler`.
- **Android:** `CAMERA`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS` in the manifest;
  `minSdkVersion` raised to ≥ 21 (LiveKit / WebRTC requirement).
- **iOS:** `NSCameraUsageDescription` + `NSMicrophoneUsageDescription` are already
  present in `ios/Runner/Info.plist`.

Run `flutter pub get` after pulling. If dependency resolution asks for a newer
Dart SDK, bump the `environment: sdk:` lower bound in `pubspec.yaml`.

## Notes

- The camera/publish path can only be exercised on a real device against a
  deployed LiveKit server (see the backend repo's `infra/livekit/`), not in a
  simulator without a camera.
- Broadcasts stay `REQUESTED` until an organizer approves them from the admin
  portal; nothing goes live unattended.
