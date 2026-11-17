#!/usr/bin/env bash
# Generate Android and iOS native projects, restore the Mastery source, then install packages.
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cp -R lib "$TMP_DIR/lib"
cp pubspec.yaml "$TMP_DIR/pubspec.yaml"

flutter create --org com.mastery --project-name mastery_app --platforms=android,ios .

rm -rf lib
cp -R "$TMP_DIR/lib" lib
cp "$TMP_DIR/pubspec.yaml" pubspec.yaml
cp android_overrides/AndroidManifest.xml android/app/src/main/AndroidManifest.xml

rm -rf test
flutter pub get
dart run flutter_launcher_icons

# Set the iOS app display name and user-facing permission descriptions.
python3 - <<'PY'
import plistlib
from pathlib import Path

plist_path = Path("ios/Runner/Info.plist")
if plist_path.exists():
    data = plistlib.loads(plist_path.read_bytes())
    data["CFBundleDisplayName"] = "Mastery"
    data["NSCameraUsageDescription"] = "Mastery may use your camera when a course or website feature requires it."
    data["NSMicrophoneUsageDescription"] = "Mastery may use your microphone for supported course features."
    data["NSPhotoLibraryUsageDescription"] = "Mastery may access selected photos when a website feature requires it."
    plist_path.write_bytes(plistlib.dumps(data, fmt=plistlib.FMT_XML, sort_keys=False))
PY

echo "Setup complete: Android and iOS projects are ready."
