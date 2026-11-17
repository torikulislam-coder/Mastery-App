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

# Fix legacy ProGuard config shipped by flutter_inappwebview_android 1.1.x.
# Newer Android Gradle Plugin rejects proguard-android.txt because it disables
# optimization; the plugin's own error recommends the optimized default file.
python3 - <<'PY'
from pathlib import Path
from pathlib import Path
import os

pub_cache = Path(os.environ.get("PUB_CACHE", Path.home() / ".pub-cache"))
matches = list((pub_cache / "hosted" / "pub.dev").glob(
    "flutter_inappwebview_android-*/android/build.gradle"
))
for gradle_file in matches:
    source = gradle_file.read_text()
    fixed = source.replace(
        "getDefaultProguardFile('proguard-android.txt')",
        "getDefaultProguardFile('proguard-android-optimize.txt')",
    ).replace(
        'getDefaultProguardFile("proguard-android.txt")',
        'getDefaultProguardFile("proguard-android-optimize.txt")',
    )
    if fixed != source:
        gradle_file.write_text(fixed)
        print(f"Updated legacy ProGuard config: {gradle_file}")
PY

dart run flutter_launcher_icons
echo "Setup complete. Build Android with: flutter build apk --release"
