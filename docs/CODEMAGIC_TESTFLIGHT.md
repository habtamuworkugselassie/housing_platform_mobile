# Ship to TestFlight without a Mac (Codemagic)

`codemagic.yaml` builds the iOS app on a cloud Mac and uploads it to TestFlight.
You need an **Apple Developer account ($99/yr)** but **not** your own Mac.

## One-time setup (~30 min)

1. **Apple Developer Program** — enrol at developer.apple.com ($99/yr).

2. **Create the app in App Store Connect**
   - appstoreconnect.apple.com → My Apps → **+** → New App.
   - Platform iOS, bundle id **`com.ethiobuildconnect.housingplatformapp`**, name **Ethio Build Connect**.
   - Open the app → App Information → note the **Apple ID** (a number like `6478…`). This is `APP_APPLE_ID` in `codemagic.yaml`.

3. **App Store Connect API key** (lets Codemagic sign & upload)
   - App Store Connect → Users and Access → **Integrations** → App Store Connect API → **Generate API Key** (Access: *App Manager*).
   - Download the `.p8`, and copy the **Key ID** and **Issuer ID**.

4. **Codemagic**
   - Sign up at codemagic.io with GitHub, grant access to this repo.
   - Team/app settings → **Integrations → App Store Connect** → add the key from step 3. **Name it exactly `AppStoreConnect`** (matches `integrations.app_store_connect` in the yaml).
   - Codemagic will fetch/create the signing certificate + provisioning profile automatically (that's what `ios_signing` + `xcode-project use-profiles` do).

5. **Edit `codemagic.yaml`**
   - Set `APP_APPLE_ID` to the number from step 2.
   - Leave `API_BASE_URL` as the current HTTP backend for testing (the temporary ATS exception in `Info.plist` allows it), or set it to your HTTPS URL.

6. **Run it**
   - In Codemagic, start the **`ios-testflight`** workflow (or push to the repo if you enable automatic triggers).
   - It builds, uploads, and the build appears in **App Store Connect → TestFlight** after processing (a few minutes).

## Testing the build
- **Internal testers** (up to 100): add them in App Store Connect → TestFlight → Internal Testing. **No Apple review** — they get it in the TestFlight app within minutes.
- **External testers** (up to 10,000, public link): need Apple's light **Beta App Review** (usually ~a day) and a "what to test" note.

## Before the PUBLIC App Store release (not needed for TestFlight)
- Serve the backend over **HTTPS** and **remove the `NSAppTransportSecurity` block** from `ios/Runner/Info.plist`.
- Add screenshots, privacy policy, App Privacy answers, and account deletion — see `STORE_SUBMISSION.md`.

> Alternatives to Codemagic if you prefer: **Xcode Cloud** (Apple's own, needs the app set up via Xcode once) or **Bitrise**. Any of them removes the "must own a Mac" requirement.
