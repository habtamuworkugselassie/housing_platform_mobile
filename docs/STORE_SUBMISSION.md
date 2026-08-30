# Publishing Ethio Build Connect to the App Store & Google Play

This is the end-to-end guide to get the mobile app onto **Google Play** and the
**Apple App Store**. It covers build/signing, the store listings, the privacy
declarations both stores now require, and the blockers to clear first.

> Companion docs: `ANDROID_BUILD.md` (build commands), `PRE_RELEASE_CHECKLIST.md`,
> `LIVE_BROADCASTING.md` (the live feature reviewers will test).

---

## 0. App identity (already configured)

| Field | Value |
|---|---|
| App name | **Ethio Build Connect** |
| Android application id | `com.ethio_properties.housing_platform_mobile` |
| iOS bundle id | `com.ethiobuildconnect.housingplatformapp` |
| Version (pubspec) | `1.0.0+1` → marketing version `1.0.0`, build `1` |
| Launcher icon | `assets/branding/ethio-build-connect-logo.png` (via `flutter_launcher_icons`) |

The application/bundle IDs are permanent once published — don't change them.

---

## 1. Blockers to clear BEFORE you submit

These will get the app **rejected** or make it unusable if ignored.

### 1a. HTTPS backend (critical) 🚨
The app currently points at a cleartext HTTP IP (`http://209.38.204.219:8080`).
- **Apple** blocks cleartext HTTP by default (App Transport Security). A build
  talking to `http://<ip>` will fail network calls and be **rejected**.
- **Android** works today only because the manifest sets
  `usesCleartextTraffic="true"` — acceptable for side-loading, but poor practice
  for a public release.

**Fix:** put the backend behind a domain with TLS (e.g. `https://api.ethiobuildconnect.et`)
and build with that URL:
```bash
--dart-define=API_BASE_URL=https://api.ethiobuildconnect.et/api/v1
```
Then remove `android:usesCleartextTraffic="true"` from the Android manifest.
(If you truly must ship cleartext temporarily, iOS needs an ATS exception in
`Info.plist` — Apple requires a written justification and often rejects it, so
HTTPS is the real answer.)

### 1b. Privacy policy URL (mandatory) 🚨
Both stores require a public privacy-policy URL, and it's non-negotiable here
because the app collects **account data** (name, email, phone) and **camera/mic**
for live broadcasting. Host one at e.g. `https://ethiobuildconnect.et/privacy`
and have it cover: what's collected, why, retention, third parties (LiveKit for
live video), and how users request deletion.

### 1c. Live streaming needs LiveKit reachable
The live feature only works against a deployed LiveKit server (see the backend
`infra/livekit/`). Reviewers **will** try it, so it must be live and reachable
over TLS/WSS at review time — or the feature must be toggled off in Admin →
Display Settings so it isn't visible during review. Decide which before you submit.

### 1d. Account deletion (both stores now require it)
If the app supports sign-in, Apple and Google require an **in-app way to delete
the account** (or a clearly linked web flow). Make sure Profile → delete account
exists, or provide a deletion URL in both listings.

---

## 2. Versioning

`pubspec.yaml` → `version: <marketing>+<build>` (e.g. `1.0.0+1`).
- **Marketing** (`1.0.0`) is what users see; bump for releases.
- **Build** (`+1`) must **strictly increase** for every upload to either store,
  even for the same marketing version. Play rejects a re-used `versionCode`;
  App Store Connect rejects a re-used build number.

Override at build time without editing the file:
```bash
flutter build appbundle --build-name=1.0.0 --build-number=1 --dart-define=...
```

---

## 3. Android → Google Play

### 3.1 Signing (upload key + Play App Signing)
Release signing reads `android/key.properties` (already wired in
`android/app/build.gradle`). It is now **gitignored** — never commit it or the
keystore.

1. Generate an upload keystore (one-time, keep it backed up safely):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Copy `android/key.properties.example` → `android/key.properties` and fill in
   `storePassword`, `keyPassword`, `keyAlias`, `storeFile` (put the `.jks` in
   `android/app/` and set `storeFile=upload-keystore.jks`).
3. Enrol in **Play App Signing** (default for new apps) — Google holds the app
   signing key; you keep the upload key. If you lose the upload key you can reset
   it with Google's help; **do not lose the keystore** otherwise.

### 3.2 Build the App Bundle (.aab — required by Play)
```bash
flutter build appbundle \
  --release \
  --build-name=1.0.0 --build-number=1 \
  --dart-define=API_BASE_URL=https://api.ethiobuildconnect.et/api/v1
# output: build/app/outputs/bundle/release/app-release.aab
```
This is a **minified/R8** release; `android/app/proguard-rules.pro` now keeps the
LiveKit/WebRTC, OkHttp, permission_handler and secure-storage classes so the
release build doesn't strip them. **Test the release build on a device**
(`flutter build apk --release` and install) before uploading — R8 issues only
show at runtime.

### 3.3 Play Console setup
1. Create the app in the **Play Console** (default language, app name "Ethio Build Connect").
2. **Internal testing** track first → upload the `.aab` → add testers → validate
   on real devices, especially the live camera path.
3. Complete these before production rollout:
   - **Data safety** form — see §5.
   - **Content rating** questionnaire (IARC) — see §5.
   - **App access** — give reviewers a test account (email/OTP) so they can reach
     signed-in features and the "Go live" flow. Note in review comments that live
     broadcasting requires an approved request (or that an organizer approves).
   - **Target audience & content** — not directed at children.
   - **Privacy policy** URL (§1b).
   - **Store listing** assets + copy — §4 and §6.
4. Promote to **Closed → Open → Production** as you gain confidence.

### 3.4 Android permissions (declared) & why
| Permission | Why (for the Play listing) |
|---|---|
| `INTERNET`, `ACCESS_NETWORK_STATE` | Talk to the backend / stream video |
| `CAMERA` | Live broadcasting + capturing listing photos |
| `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS` | Live audio while broadcasting |
No background location, no contacts, no SMS — keep it that way to avoid extra
Play declarations.

---

## 4. Required graphical assets (both stores)

Prepare these once; sizes below.

**Google Play**
- App icon: 512×512 PNG (32-bit, with alpha).
- Feature graphic: 1024×500 PNG/JPG.
- Phone screenshots: 2–8, min 1080px on the short side (16:9 or 9:16).
- (Optional) 7" & 10" tablet screenshots if you list tablet support.

**Apple App Store**
- App icon: 1024×1024 PNG, **no alpha, no rounded corners**.
- iPhone 6.7" screenshots (1290×2796) — required.
- iPhone 6.5" (1242×2688) — required if you don't provide 6.7"-only.
- (Optional) iPad 12.9" screenshots if you support iPad.

**Suggested screens to capture** (light theme): Home/marketplace, property
detail, the **Live** tab / broadcast wall, **Go live** preview, exhibition
register. Use a clean device frame; show the violet brand.

---

## 5. Privacy declarations

Answer these consistently across both stores and your privacy policy.

**What the app collects**
- **Account:** name, email, phone number (sign-in / registration).
- **User content:** listing photos (image picker), and **video + audio** when a
  user broadcasts live or submits video feedback.
- **Diagnostics:** none beyond standard crash/network (no analytics SDK is bundled).
- Data is sent over the network to the backend and, for live, to the LiveKit
  server. Encrypted in transit (once §1a HTTPS is done).

**Google Play → Data safety**
- Personal info: Name, Email address, Phone number → *Collected*, purpose
  "Account management / App functionality", **not shared**, encrypted in transit,
  user can request deletion (§1d).
- Photos and videos, and Voice/audio → *Collected*, purpose "App functionality"
  (live broadcasting / feedback). Not shared for advertising.
- Data is not used for tracking/ads.

**Apple → App Privacy (nutrition labels)**
- **Contact Info:** Name, Email, Phone → linked to identity, used for App Functionality.
- **User Content:** Photos/Videos, Audio Data → linked, App Functionality.
- **Data Not Used to Track You.**

**Content rating**
- The app hosts **user-generated live video/feedback**, which raises the rating
  even though submissions are **admin-moderated** (broadcasts require approval).
  Answer the IARC questionnaire honestly (there is user-generated content that is
  moderated); expect roughly **Teen / 12+**. On Apple, note UGC + moderation in
  the questionnaire.

**Export compliance (Apple):** the app uses only standard encryption (HTTPS/TLS
and WebRTC DTLS-SRTP), so `ITSAppUsesNonExemptEncryption=false` is set in
`Info.plist` — no yearly self-classification report needed.

---

## 6. Store listing copy (ready to paste)

**Title:** Ethio Build Connect

**Short description / subtitle (≤80 Play / ≤30 Apple):**
`Ethiopia's real estate & construction marketplace`

**Promotional text (Apple, ≤170):**
`Browse verified properties, connect with builders and banks, and watch the Build Connect expo live.`

**Full description:**
```
Ethio Build Connect is Ethiopia's marketplace for real estate and construction —
connecting home buyers and renters with trusted developers, real estate
companies, banks, contractors, suppliers, consultants and architects.

• Browse verified property and building listings across Addis Ababa and beyond
• Explore financing options and industry partners in one place
• Follow the Ethio Build Connect exhibition — watch live broadcasts from booths
  and the show floor, and go live yourself from an exhibitor stand
• Register your interest as a visitor or exhibitor

Find your next home, project partner, or investment — all in one app.
```

**Keywords (Apple, ≤100 chars, comma-separated):**
`real estate,Ethiopia,property,rent,buy,construction,housing,Addis Ababa,exhibition,builders`

**Category:** Play → *House & Home* (alt: Business). Apple → *Lifestyle* (alt: Business).

**Contact / URLs:** support email + `https://ethiobuildconnect.et` (marketing),
`https://ethiobuildconnect.et/privacy` (privacy policy). Provide a support URL both stores require.

---

## 7. iOS → App Store

Requires a **Mac with Xcode** and an **Apple Developer Program** membership ($99/yr).

1. **App Store Connect:** create the app record with bundle id
   `com.ethiobuildconnect.housingplatformapp` and name "Ethio Build Connect".
2. **Signing:** in Xcode (`ios/Runner.xcworkspace`) set your Team; let Xcode
   manage signing, or create an App Store distribution certificate + provisioning
   profile. The camera/mic usage strings are already in `Info.plist`.
3. **Confirm min iOS** and that CocoaPods installed (`cd ios && pod install`).
   LiveKit/WebRTC generally need **iOS 13+**; set the deployment target
   accordingly in Xcode if a pod requires it.
4. **Build & archive:**
   ```bash
   flutter build ipa --release \
     --build-name=1.0.0 --build-number=1 \
     --dart-define=API_BASE_URL=https://api.ethiobuildconnect.et/api/v1
   ```
   Then open `build/ios/archive/Runner.xcarchive` in Xcode Organizer (or use
   `xcrun altool`/Transporter) and **upload to App Store Connect**.
5. **TestFlight:** test on real devices — especially the live camera path — before
   submitting for review.
6. **App Review information:** provide a **test account** and clear notes on how
   to reach the "Go live" flow (it's under the **Live** tab → "Go live"; a
   broadcast needs organizer approval, so either pre-approve one for the reviewer
   or explain the flow). Fill App Privacy (§5). Submit.

---

## 8. Reviewer notes (paste into both stores' review-notes field)

```
Test account: <email / phone + OTP or password you provision>

Most of the app (marketplace, listings, exhibition info) is usable without an
account. To review live video:
- Open the "Live" tab in the bottom navigation to see the public live wall.
- Tap "Go live" to open the broadcaster screen; grant camera + microphone.
- Broadcasting requires organizer approval before it goes live; we have
  pre-approved a stream / an organizer will approve during review.
User-generated broadcasts and video feedback are admin-moderated before they
appear publicly.
```

---

## 9. Final pre-submission checklist

- [ ] Backend served over **HTTPS**; app built with the HTTPS `API_BASE_URL`; Android cleartext flag removed (§1a).
- [ ] **Privacy policy** URL live (§1b).
- [ ] **Account deletion** available in-app or via linked URL (§1d).
- [ ] LiveKit reachable over TLS at review time, or live toggled off (§1c).
- [ ] Release build **tested on a real device** (Android R8 + iOS), live path included.
- [ ] `key.properties` + keystore created, backed up, **not committed**.
- [ ] Build number incremented for this upload.
- [ ] Data safety / App Privacy filled to match §5.
- [ ] Content rating questionnaire completed (UGC + moderation noted).
- [ ] Icons + screenshots + feature graphic prepared (§4).
- [ ] Listing copy + support/privacy URLs entered (§6).
- [ ] Reviewer test account + notes provided (§8).
