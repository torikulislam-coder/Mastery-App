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

# Ensure AndroidX and Kotlin dependencies resolve from their official Maven repositories.
python3 - <<'PY'
from pathlib import Path
import re

def closing_brace(text, opening):
    depth = 0
    for i in range(opening, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return i
    raise RuntimeError("Unbalanced Gradle settings braces")

for settings in (Path("android/settings.gradle.kts"), Path("android/settings.gradle")):
    if not settings.exists():
        continue
    text = settings.read_text()
    m = re.search(r"dependencyResolutionManagement\s*\{", text)
    if not m:
        text += """
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
    }
}
"""
    else:
        block_open = text.find("{", m.start())
        block_close = closing_brace(text, block_open)
        block = text[block_open + 1:block_close]
        r = re.search(r"repositories\s*\{", block)
        if r:
            repo_open = block_open + 1 + block.find("{", r.start())
            repo_close = closing_brace(text, repo_open)
            repo_body = text[repo_open + 1:repo_close]
            additions = []
            if "google()" not in repo_body:
                additions.append("        google()")
            if "mavenCentral()" not in repo_body:
                additions.append("        mavenCentral()")
            if additions:
                text = text[:repo_open + 1] + "\n" + "\n".join(additions) + text[repo_open + 1:]
        else:
            text = text[:block_close] + """
    repositories {
        google()
        mavenCentral()
    }
""" + text[block_close:]
    settings.write_text(text)
    print(f"Configured google() and mavenCentral() in {settings}")
    break
else:
    raise SystemExit("Could not locate Android settings.gradle(.kts)")
PY

flutter build apk --release
flutter build web --release
mkdir -p ../dist
cp build/app/outputs/flutter-apk/app-release.apk ../dist/Mastery.apk
cp -r build/web ../dist/web
echo "Done: dist/Mastery.apk এবং dist/web"
