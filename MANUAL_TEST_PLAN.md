# Manual Test Plan

## Auth
1. Register a new user with phone `+7 (###) ###-##-##` and password.
2. Sign in with the same phone and password.
3. Sign in with an account created before the `@mastera42.kz` migration.
4. Attempt login with wrong password and verify a clean user-facing error.
5. Verify Google sign-in on Android when `GOOGLE_SERVER_CLIENT_ID` is set.
6. Verify Google sign-in on iOS.
7. Verify Apple sign-in on iOS.
8. Verify that missing Google/Apple config shows honest business text, not raw exceptions.

## First Login / Profile
1. Sign in as a new account and confirm the role/profile setup screen appears.
2. Save `customer` profile.
3. Save `executor` profile.
4. Edit profile and verify phone normalization remains `+7 (###) ###-##-##`.
5. Upload executor portfolio items and reopen the profile.

## Customer Flow
1. Create a job with title, description, category, budget.
2. Open own jobs list and job details.
3. Accept a submitted bid and verify chat creation.
4. Reject a submitted bid and verify executor receives status update.

## Executor Flow
1. Open available jobs list.
2. Create a bid for an open job.
3. Retry payment after a cancelled payment and confirm no duplicate active payments are created.
4. After successful callback, confirm bid moves from `pending_payment` to `submitted`.
5. Open accepted bid and enter chat.

## Payments
1. Start payment and close the SDK before completion.
2. Start payment and fail the card flow.
3. Complete payment successfully.
4. Confirm payment states transition through created/sdk_started/awaiting_callback/paid.
5. Confirm failed/cancelled flows do not mark the bid as submitted.
6. Run admin refund and confirm payment becomes `refund_requested`.

## Chat / Push
1. Send text message.
2. Send image.
3. Send file.
4. Verify recipient gets push notification for chat message.
5. Tap notification from foreground/background/terminated states and verify correct screen opens.
6. Verify push routing for `new_bid` and `bid_status`.

## Release Sanity
1. Install release APK.
2. Verify no debug banners or raw stack traces appear.
3. Verify payment buttons show honest state when Halyk credentials are not configured.
4. Verify sign-in options only appear where configured/supported.
