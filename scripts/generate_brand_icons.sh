#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="/private/tmp/mastera_brand_assets"
SOURCE_SVG="$ROOT_DIR/assets/branding/mastera_brandmark.svg"

mkdir -p "$TMP_DIR"
qlmanage -t -s 1024 -o "$TMP_DIR" "$SOURCE_SVG" >/dev/null

BASE_PNG="$TMP_DIR/$(basename "$SOURCE_SVG").png"

resize_icon() {
  local size="$1"
  local output="$2"

  cp "$BASE_PNG" "$output"
  sips -z "$size" "$size" "$output" >/dev/null
}

resize_icon 64 "$ROOT_DIR/web/favicon.png"
resize_icon 192 "$ROOT_DIR/web/icons/Icon-192.png"
resize_icon 512 "$ROOT_DIR/web/icons/Icon-512.png"
resize_icon 192 "$ROOT_DIR/web/icons/Icon-maskable-192.png"
resize_icon 512 "$ROOT_DIR/web/icons/Icon-maskable-512.png"

resize_icon 48 "$ROOT_DIR/android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
resize_icon 72 "$ROOT_DIR/android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
resize_icon 96 "$ROOT_DIR/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
resize_icon 144 "$ROOT_DIR/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
resize_icon 192 "$ROOT_DIR/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"

resize_icon 40 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png"
resize_icon 60 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png"
resize_icon 29 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png"
resize_icon 58 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png"
resize_icon 87 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png"
resize_icon 80 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png"
resize_icon 120 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png"
resize_icon 120 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png"
resize_icon 180 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png"
resize_icon 20 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png"
resize_icon 40 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png"
resize_icon 29 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png"
resize_icon 58 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png"
resize_icon 40 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png"
resize_icon 80 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png"
resize_icon 76 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png"
resize_icon 152 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png"
resize_icon 167 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png"
resize_icon 1024 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
