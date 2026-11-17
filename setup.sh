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

# Generate a clean launcher icon: the icon supplied in the original archive
# has a malformed PNG palette checksum on some image decoders.
python3 - <<'PY'
import binascii
import struct
import zlib
from pathlib import Path

W = H = 512
BLACK = (12, 12, 12)
ORANGE = (255, 97, 36)
pixels = bytearray(BLACK * (W * H))

def polygon(points, color):
    r, g, b = color
    ymin = max(0, min(y for _, y in points))
    ymax = min(H - 1, max(y for _, y in points))
    for y in range(ymin, ymax + 1):
        scan_y = y + 0.5
        xs = []
        for i, (x1, y1) in enumerate(points):
            x2, y2 = points[(i + 1) % len(points)]
            if (y1 <= scan_y < y2) or (y2 <= scan_y < y1):
                xs.append(x1 + (scan_y - y1) * (x2 - x1) / (y2 - y1))
        xs.sort()
        for i in range(0, len(xs) - 1, 2):
            x0 = max(0, int(xs[i]))
            x1 = min(W - 1, int(xs[i + 1]))
            for x in range(x0, x1 + 1):
                p = (y * W + x) * 3
                pixels[p:p + 3] = bytes((r, g, b))

polygon([(112, 104), (256, 184), (400, 104),
         (400, 278), (256, 365), (112, 278)], ORANGE)
polygon([(184, 158), (256, 198), (328, 158),
         (328, 239), (256, 283), (184, 239)], BLACK)

def chunk(kind, data):
    return (struct.pack(">I", len(data)) + kind + data +
            struct.pack(">I", binascii.crc32(kind + data) & 0xffffffff))

raw = b"".join(b"\x00" + pixels[y * W * 3:(y + 1) * W * 3]
               for y in range(H))
png = (b"\x89PNG\r\n\x1a\n" +
       chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0)) +
       chunk(b"IDAT", zlib.compress(raw, 9)) +
       chunk(b"IEND", b""))
Path("assets/icon.png").write_bytes(png)
print(f"Generated valid {W}x{H} RGB launcher icon ({len(png)} bytes)")
PY

# Add Google's AndroidX, Maven Central, and Flutter engine/embedding Maven repositories.
python3 - <<'PY'
from pathlib import Path

def matching_brace(source, opening):
    depth = 0
    for i in range(opening, len(source)):
        if source[i] == "{":
            depth += 1
        elif source[i] == "}":
            depth -= 1
            if depth == 0:
                return i
    raise RuntimeError("Unbalanced Gradle settings braces")

for path in (Path("android/settings.gradle.kts"), Path("android/settings.gradle")):
    if not path.exists():
        continue
    source = path.read_text()
    kts = path.name.endswith(".kts")
    flutter_repo = (
        'maven { url = uri("https://storage.googleapis.com/download.flutter.io") }'
        if kts else
        'maven { url "https://storage.googleapis.com/download.flutter.io" }'
    )
    marker = "dependencyResolutionManagement"
    if marker not in source:
        source += f"""
dependencyResolutionManagement {{
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {{
        google()
        mavenCentral()
        {flutter_repo}
    }}
}}
"""
    else:
        block_open = source.find("{", source.find(marker))
        block_close = matching_brace(source, block_open)
        block = source[block_open + 1:block_close]
        repo_marker = "repositories"
        repo_pos = block.find(repo_marker)
        if repo_pos < 0:
            addition = f"""
    repositories {{
        google()
        mavenCentral()
        {flutter_repo}
    }}
"""
            source = source[:block_close] + addition + source[block_close:]
        else:
            repo_open = source.find("{", block_open + 1 + repo_pos)
            repo_close = matching_brace(source, repo_open)
            body = source[repo_open + 1:repo_close]
            additions = []
            if "google()" not in body:
                additions.append("        google()")
            if "mavenCentral()" not in body:
                additions.append("        mavenCentral()")
            if "storage.googleapis.com/download.flutter.io" not in body:
                additions.append("        " + flutter_repo)
            if additions:
                source = source[:repo_open + 1] + "\n" + "\n".join(additions) + source[repo_open + 1:]
    path.write_text(source)
    print(f"Configured Android Maven repositories in {path}")
    break
else:
    raise SystemExit("Android settings.gradle(.kts) was not generated")
PY

# The current Android Gradle Lint parser crashes inside url_launcher_android.
# Skip only Lint tasks; the APK is still compiled and packaged normally.
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
  echo "Android root Gradle build file not found." >&2
  exit 1
fi

flutter pub get

# flutter_inappwebview_android 1.1.3 still references the deprecated
# proguard-android.txt default file; current Android Gradle requires the
# optimise variant. Patch the downloaded pub-cache copy for this build.
python3 - <<'PY'
import os
from pathlib import Path

pub_cache = Path(os.environ.get("PUB_CACHE", str(Path.home() / ".pub-cache")))
for gradle_file in pub_cache.glob(
    "hosted/pub.dev/flutter_inappwebview_android-*/android/build.gradle"
):
    source = gradle_file.read_text()
    source = source.replace(
        "getDefaultProguardFile('proguard-android.txt')",
        "getDefaultProguardFile('proguard-android-optimize.txt')",
    )
    source = source.replace(
        'getDefaultProguardFile("proguard-android.txt")',
        'getDefaultProguardFile("proguard-android-optimize.txt")',
    )
    gradle_file.write_text(source)
    print(f"Patched Android Gradle ProGuard config: {gradle_file}")
PY

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
