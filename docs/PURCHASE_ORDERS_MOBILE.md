# Purchase orders in the mobile app

Flutter counterpart of the web purchase flow (backend: `housing-platform-backend/docs/PROPERTY_PURCHASE_ORDERS.md`,
web: `housing-platform-frontend/docs/PURCHASE_ORDER_UI.md`). A buyer places a purchase order on a
property in up to five steps — account (visitors only), contact, financing (only when the property
carries an active financing product), agreement, review — and cannot submit until the phone
validates and the Promise to Purchase Agreement has been read to the end, accepted and signed
with their full name.

## Entry points

| Where | What |
| --- | --- |
| `PropertyDetailScreen` bottom bar | gold **Place purchase order** button (replaces the inert "Book a Tour"); enabled for `AVAILABLE` listings that are for sale |
| `ProfileScreen` | **My purchase orders** → `MyPurchaseOrdersScreen` → `PurchaseOrderDetailScreen` |

## Structure

```
lib/core
├── config/google_config.dart                GOOGLE_WEB_CLIENT_ID (--dart-define)
├── models/purchase_model.dart               DTO mirrors + human labels
├── services/purchase_service.dart           preview, create, mine, get, agreements, sign, cancel, …
├── services/google_auth_gateway.dart        google_sign_in wrapper → ID token
├── providers/purchase_provider.dart         PurchaseFormState + PurchaseFormNotifier (Riverpod, per property)
├── utils/phone_number.dart                  E.164 normalisation identical to the backend
├── utils/financing_math.dart                split / instalment maths for live previews
└── utils/simple_markdown.dart               agreement text → widgets (no HTML, no package)
lib/features/purchase
├── screens/purchase_order_screen.dart       the wizard
├── screens/purchase_order_detail_screen.dart status, financing decisions, agreements sheet, history, cancel
├── screens/my_purchase_orders_screen.dart
└── widgets/  wizard_steps_header, purchase_account_step, purchase_form_steps (contact / financing /
              agreement / review), agreement_review_panel, purchase_status_badge
```

`AuthService` / `AuthNotifier` gained `quickRegister` and `loginWithGoogle`; `PropertyModel` gained
`category` and `unitNumber`.

## State

`PurchaseFormState` is one immutable value per property (`purchaseFormProvider(propertyId)`); the
derived rules (`steps`, `split`, `contactErrors`, `financingErrors`, `agreementErrors`,
`isStepValid`, `canSubmit`, `payload`) are getters so the UI and the tests read the same logic.
`PurchaseFormNotifier` owns the transitions: `init` (visitors start on the account step; the
preview is public so offers and the agreement load either way), `accountReady` (drops the account
step, pre-fills phone / email / signatory, reloads the preview for the signed-in buyer), input
setters, `goTo` / `next` / `back` (never past an invalid step), `submit` (409 duplicate order and
"agreement text changed" handled explicitly).

## Account step (visitors)

Three doors, all ending in `AuthNotifier` holding a signed-in BUYER:

| Door | Calls | Notes |
| --- | --- | --- |
| **Continue with Google** | `GoogleAuthGateway.obtainIdToken()` → `POST /auth/google` | button shown only when `GOOGLE_WEB_CLIENT_ID` is set |
| **I'm new here** | `POST /auth/quick-register` | full name + phone (country-code input); email and password optional |
| **I have an account** | `POST /auth/login/otp/send`, `/confirm` | WhatsApp code via `Pinput`; a phone that already has an account flips here automatically |

## Google sign-in setup

The ID token is requested with the **web** client id as `serverClientId`, so its audience equals
the value the backend verifies (`GOOGLE_OAUTH_CLIENT_ID`) and the web app uses
(`VITE_GOOGLE_CLIENT_ID`). In the same Google Cloud project:

1. **Android**: Credentials → Create OAuth client → *Android*; package name
   `com.ethio_properties.housing_platform_mobile`, plus the SHA-1 of every signing key (debug,
   upload/release, and Play App Signing). No file needs to be added to the repo.
2. **iOS**: Credentials → Create OAuth client → *iOS* with the bundle id. Then in
   `ios/Runner/Info.plist` add `GIDClientID` = the iOS client id and a `CFBundleURLTypes` entry
   whose URL scheme is the iOS client's reversed id (`com.googleusercontent.apps.…`).
3. Build with the web client id:
   ```
   flutter build apk --dart-define=API_BASE_URL=https://ethiobuildconnect.et/api/v1 \
                     --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
   ```
Without `GOOGLE_WEB_CLIENT_ID` the button is simply not rendered; the two other doors still work.

## Tests

`flutter test test/purchase` — 43 tests:

| File | Covers |
| --- | --- |
| `phone_number_test.dart` | the backend normaliser cases, country-code joining, display, email rule |
| `financing_math_test.dart` | instalments identical to the backend (87,039.85 / 58,033.79), split classification, clamping, validation, money formatting |
| `simple_markdown_test.dart` | block parsing and literal (non-HTML) rendering |
| `purchase_form_notifier_test.dart` | prefill, dynamic steps, visitor account step and `accountReady`, every gate, payload shape, cash opt-out, duplicate and template-changed handling, server field errors — against a fake `PurchaseService` |
| `agreement_review_panel_test.dart` | signature controls disabled until scrolled to the end, "Jump to the end", attempted-only errors, input forwarding |

The pre-existing `test/widget_test.dart` is the Flutter template counter test and does not match
this app; it is unchanged here.

## Requires

Flutter ≥ 3.47 (the lockfile pins Dart ≥ 3.12 because of `livekit_client`). `google_sign_in ^6.2`.
