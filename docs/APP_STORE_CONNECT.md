# Future Call App Store Connect Setup

## App record

- App name: Future Call
- Bundle ID: com.pguuu.futurecall
- SKU: future-call-ios
- Category: Productivity

## Required privacy notes

Future Call records voice messages chosen by the user and stores them locally on the device. The app does not need a server for the first version.

## Codemagic setup

1. Create the Bundle ID `com.pguuu.futurecall` in Apple Developer.
2. Create the app record in App Store Connect.
3. Connect this GitHub repository in Codemagic.
4. In Codemagic, connect App Store Connect API access under Integrations.
5. Enable iOS code signing for the bundle ID.
6. Put the App Store Connect app numeric ID into `APP_STORE_APP_ID` in `codemagic.yaml` after the app record exists.

## Review positioning

Do not describe the app as a fake call or prank call app. Use language like:

> Record a private voice capsule and schedule it as a future call from your past self.

The system notification opens an in-app call-style experience. It does not impersonate iOS Phone or CallKit.
