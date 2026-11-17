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

# Re-create the launcher source as a clean, standards-compliant RGB PNG.
# The icon supplied in the original archive has an invalid PNG palette checksum.
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

# Mastery orange chevron / shield mark on a dark app tile.
polygon([(112, 104), (256, 184), (400, 104),
         (400, 278), (256, 365), (112, 278)], ORANGE)
# Add the inner dark fold that gives the mark its distinctive open V.
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
print(f"Generated valid {W}x{H} RGB Mastery launcher icon ({len(png)} bytes)")
PY

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
