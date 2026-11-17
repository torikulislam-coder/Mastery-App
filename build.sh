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

# Disable only Android Lint tasks due to a reproducible upstream Android Lint parser crash
# in url_launcher_android (JavaDocParser.parseDataItem NoSuchMethodError).
if [ -f android/build.gradle.kts ]; then
  cat >> android/build.gradle.kts <<'GRADLE'
subprojects {
    tasks.configureEach {
        if (name.startsWith("lint")) {
            enabled = false
        }
    }
}
GRADLE
elif [ -f android/build.gradle ]; then
  cat >> android/build.gradle <<'GRADLE'
subprojects {
    tasks.configureEach { task ->
        if (task.name.startsWith('lint')) {
            task.enabled = false
        }
    }
}
GRADLE
else
  echo "Could not locate Android root Gradle build file." >&2
  exit 1
fi

flutter build apk --release
flutter build web --release
mkdir -p ../dist
cp build/app/outputs/flutter-apk/app-release.apk ../dist/Mastery.apk
cp -r build/web ../dist/web
echo "Done: dist/Mastery.apk এবং dist/web"
