# Firebase and OAuth Setup for kz.milanium.mastera24

## Final Identifiers
- Android package: `kz.milanium.mastera24`
- iOS bundle id: `kz.milanium.mastera24`
- Firebase project: `mastera24-bfbcf`

## Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com/).
2. In project `mastera24-bfbcf`, add or update Android app with package name `kz.milanium.mastera24`.
3. Add or update iOS app with bundle id `kz.milanium.mastera24`.
4. Download fresh config files and replace:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

## Android SHA Fingerprints
Add the release SHA-1 and SHA-256 of the keystore that will sign Play builds.

## Google Sign-In
### Firebase
- Enable `Google` sign-in provider.

### Google Cloud / OAuth
Create OAuth clients for:
- Android app: package `kz.milanium.mastera24` + release SHA fingerprints
- iOS app: bundle `kz.milanium.mastera24`
- Web client: use this client ID as `GOOGLE_SERVER_CLIENT_ID`

### Build Command
Use the web client id in release builds:

```bash
/Volumes/PD1000/job/flutter/bin/flutter build apk --release \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

## Apple Sign-In
- Enable `Apple` provider in Firebase Auth.
- In Apple Developer, enable `Sign In with Apple` for bundle `kz.milanium.mastera24`.
- Update provisioning profiles.

## Halyk ePay
Set Functions env vars:

```bash
firebase functions:config:set \
  epay.env="prod" \
  epay.client_id="YOUR_CLIENT_ID" \
  epay.client_secret="YOUR_CLIENT_SECRET" \
  epay.terminal_id="YOUR_TERMINAL_ID"
```

If you use modern env instead of legacy config, export these before deploy:

```bash
export EPAY_ENV=prod
export EPAY_CLIENT_ID=YOUR_CLIENT_ID
export EPAY_CLIENT_SECRET=YOUR_CLIENT_SECRET
export EPAY_TERMINAL_ID=YOUR_TERMINAL_ID
```

Replace native placeholders before store release:
- `android/app/src/main/res/values/epay.xml`
- `ios/Runner/Info.plist`

## Android Signing
Create `android/keystore.properties`:

```properties
storeFile=/absolute/path/to/release.keystore
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

## After Console Update
Refresh generated config if needed:
- rerun FlutterFire CLI for the new app registrations, or
- manually replace Firebase config files and keep `lib/firebase_options.dart` in sync.
