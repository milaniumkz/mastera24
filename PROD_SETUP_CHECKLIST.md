# Production Setup Checklist

## 1. Firebase Authentication
- Turn on `Email/Password` because phone+password uses a hidden email mapping.
- Turn on `Google` provider.
- Turn on `Apple` provider for iOS.
- Add support email and project branding in Firebase Auth.

## 2. Hidden Phone Login Mapping
- User-facing phone format: `+7 (###) ###-##-##`.
- Internal auth login format: `phone_<normalized>@mastera42.kz`.
- Legacy sign-in fallback remains: `phone_<normalized>@mastera24.app`.
- Do not expose hidden emails in UI or support scripts.

## 3. Firebase Project Integrity
- Replace suspended or temporary API keys with active project keys.
- Make sure Android and iOS app registrations match final package/bundle IDs.
- Re-download Firebase config files after changing IDs or OAuth clients.

## 4. Google Sign-In
- Create Android OAuth client with final package name and SHA fingerprints.
- Create iOS OAuth client for the final bundle ID.
- Pass the Web client ID into Flutter build via `GOOGLE_SERVER_CLIENT_ID`.

## 5. Apple Sign-In
- Enable capability in Apple Developer and Xcode.
- Ensure provisioning profiles include `Sign In with Apple`.
- If Apple sign-in is not configured, keep the feature disabled on unsupported builds.

## 6. Halyk ePay
- Set Cloud Functions env vars:
  - `EPAY_ENV=prod`
  - `EPAY_CLIENT_ID=...`
  - `EPAY_CLIENT_SECRET=...`
  - `EPAY_TERMINAL_ID=...`
- Replace native placeholders:
  - `android/app/src/main/res/values/epay.xml`
  - `ios/Runner/Info.plist`
- Verify callbacks on deployed Functions before publishing.

## 7. Notifications
- Upload APNs key/certificate in Firebase for iOS push.
- Verify Android notification permission and channels on Android 13+.
- Test notification tap routing for `new_bid`, `bid_status`, `chat_message`.

## 8. Release Signing
- Android: create `android/keystore.properties` and keep it out of git.
- iOS: configure distribution certificate and App Store provisioning profile.
