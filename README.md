# Mastery App (Android + iOS)

Flutter app wrapper for [https://mastery.com.bd/](https://mastery.com.bd/).

## Features
- Loads the Mastery website inside an in-app WebView.
- Keeps Mastery-domain navigation and payment gateways inside the app.
- Opens selected social and meeting links in their external apps.
- Pull-to-refresh, loading progress, offline/retry screen, and Android back navigation.
- Mastery splash screen and app launcher icons.

## Build locally
Install Flutter and platform tooling first.

**Android**
```bash
bash setup.sh
flutter build apk --release
```
APK output: `build/app/outputs/flutter-apk/app-release.apk`

**iOS**
Run on macOS with Xcode installed:
```bash
bash setup.sh
flutter build ios --release --no-codesign
```
This validates/compiles the iOS app but is not a signed, installable iPhone IPA. Device installation and App Store/TestFlight distribution require Apple signing credentials and a provisioning profile.

## GitHub Actions
Open the repository's **Actions** tab and run **Build Mastery App (Android + iOS)**. It uploads:
- `Mastery-Android-APK`: Android release APK.
- `Mastery-iOS-Unsigned-App`: unsigned iOS device build for validation; not installable until signed.

## App identity
- Display name: Mastery
- Android/iOS bundle identifier: `com.mastery.mastery_app`
