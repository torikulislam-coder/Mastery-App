#!/usr/bin/env bash
set -euo pipefail
mkdir -p /tmp/_mastery_keep
cp -r lib /tmp/_mastery_keep/lib
cp pubspec.yaml /tmp/_mastery_keep/pubspec.yaml
flutter create --org com.mastery --project-name mastery_app --platforms=android,ios .
rm -rf lib && cp -r /tmp/_mastery_keep/lib lib
cp /tmp/_mastery_keep/pubspec.yaml pubspec.yaml
cp android_overrides/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
rm -rf test
flutter pub get
dart run flutter_launcher_icons
echo "Setup complete. Build Android with: flutter build apk --release"
