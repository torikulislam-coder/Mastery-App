#!/usr/bin/env bash
# Mastery app: APK ও Web build. Flutter SDK আগে থেকে ইনস্টল থাকতে হবে।
set -euo pipefail
rm -rf build_app dist
flutter create --platforms=android,web --project-name mastery_app --org bd.com.mastery build_app
cp -r overlay/. build_app/
cd build_app
rm -rf test
sed -i.bak 's#<title>.*</title>#<title>Mastery</title>#' web/index.html && rm web/index.html.bak
sed -i.bak 's#android:label="[^"]*"#android:label="Mastery"#' android/app/src/main/AndroidManifest.xml && rm android/app/src/main/AndroidManifest.xml.bak
flutter pub get
flutter build apk --release
flutter build web --release
mkdir -p ../dist
cp build/app/outputs/flutter-apk/app-release.apk ../dist/Mastery.apk
cp -r build/web ../dist/web
echo "Done: dist/Mastery.apk এবং dist/web"
