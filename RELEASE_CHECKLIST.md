# Release Checklist

## Build Configuration
- [ ] Create `android/keystore.properties` with release keystore values.
- [ ] Provide `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` for Android Google Sign-In.
- [ ] Provide `--dart-define=PAYMENT_SUCCESS_URL=...` and `--dart-define=PAYMENT_FAILURE_URL=...` for the production web callbacks.
- [ ] If the final Android package ID differs from `kz.milanium.mastera24`, pass `-PMASTERA_APPLICATION_ID=<final.id>` and update Firebase configs for that package.

## Firebase
- [ ] Enable `Email/Password` provider.
- [ ] Enable `Google` provider and add Android/iOS OAuth clients.
- [ ] Enable `Apple` provider for iOS.
- [ ] Add Android SHA-1 and SHA-256 fingerprints in Firebase.
- [ ] Replace `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` with production configs that match final package/bundle IDs.
- [ ] Deploy Firestore/Storage rules and Cloud Functions.

## Payments
- [ ] Set Functions env vars: `EPAY_ENV`, `EPAY_CLIENT_ID`, `EPAY_CLIENT_SECRET`, `EPAY_TERMINAL_ID`.
- [ ] Replace placeholder ePay values in iOS/Android native configs before store submission.
- [ ] Verify production `postLink` and `failurePostLink` endpoints are reachable from Halyk ePay.

## iOS
- [ ] Set final `PRODUCT_BUNDLE_IDENTIFIER` values in Xcode project.
- [ ] Add `Sign In with Apple` capability and production provisioning profiles.
- [ ] Archive a release build with a production signing team.

## Android
- [ ] Configure final `applicationId` and Play signing assets.
- [ ] Verify `release` build is signed with the release keystore, not debug keys.
- [ ] Upload the generated AAB/APK only after final Firebase and Halyk configs are applied.
