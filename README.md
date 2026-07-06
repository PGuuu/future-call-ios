# Future Call

Future Call is a SwiftUI iOS app for recording a private voice capsule and scheduling it as a future call from your past self.

## Features

- Record a short voice message
- Schedule by exact date/time or countdown timer
- Receive a local notification when the capsule is ready
- Open an in-app incoming-call experience
- Play, replay, complete, and delete saved future calls
- Store data locally on device

## Local development

1. Open `ReminderSchedulerApp.xcodeproj` in Xcode.
2. Select an iPhone simulator or device.
3. Run the `ReminderSchedulerApp` scheme.
4. Allow notifications and microphone access.

## Distribution

Codemagic is configured in `codemagic.yaml`.

Before TestFlight publishing:

1. Create the Bundle ID `com.pguuu.futurecall` in Apple Developer.
2. Create the App Store Connect app record.
3. Connect the repository in Codemagic.
4. Configure Codemagic App Store Connect integration and iOS code signing.
5. Fill `APP_STORE_APP_ID` in `codemagic.yaml`.
