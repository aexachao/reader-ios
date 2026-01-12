#!/usr/bin/env bash
# generate_app_icons.sh
# Usage: ./generate_app_icons.sh /path/to/source.png
# Generates iOS AppIcon sizes into 阅读/阅读/Assets.xcassets/AppIcon.appiconset

set -euo pipefail

SRC="$1"
if [[ -z "$SRC" || ! -f "$SRC" ]]; then
  echo "Usage: $0 /path/to/source.png"
  exit 1
fi

APPICON_DIR="$(pwd)/阅读/阅读/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$APPICON_DIR"

# list of sizes (px) and filenames per Apple template
declare -a sizes=(
  "20@2x,40"
  "20@3x,60"
  "29@2x,58"
  "29@3x,87"
  "40@2x,80"
  "40@3x,120"
  "60@2x,120"
  "60@3x,180"
  "76@1x,76"
  "76@2x,152"
  "83.5@2x,167"
  "1024@1x,1024"
)

# remove old icons except Contents.json
shopt -s extglob
rm -f "$APPICON_DIR"/icon_* || true

for entry in "${sizes[@]}"; do
  IFS=',' read -r name px <<< "$entry"
  filename="icon_${px}x.png"
  echo "Generating $filename ($px)"
  sips -Z $px "$SRC" --out "$APPICON_DIR/$filename" >/dev/null
done

# Write a minimal Contents.json mapping
cat > "$APPICON_DIR/Contents.json" <<JSON
{
  "images" : [
    { "idiom" : "iphone", "size" : "20x20", "scale" : "2x", "filename" : "icon_40x.png" },
    { "idiom" : "iphone", "size" : "20x20", "scale" : "3x", "filename" : "icon_60x.png" },
    { "idiom" : "iphone", "size" : "29x29", "scale" : "2x", "filename" : "icon_58x.png" },
    { "idiom" : "iphone", "size" : "29x29", "scale" : "3x", "filename" : "icon_87x.png" },
    { "idiom" : "iphone", "size" : "40x40", "scale" : "2x", "filename" : "icon_80x.png" },
    { "idiom" : "iphone", "size" : "40x40", "scale" : "3x", "filename" : "icon_120x.png" },
    { "idiom" : "iphone", "size" : "60x60", "scale" : "2x", "filename" : "icon_120x.png" },
    { "idiom" : "iphone", "size" : "60x60", "scale" : "3x", "filename" : "icon_180x.png" },
    { "idiom" : "ipad", "size" : "76x76", "scale" : "1x", "filename" : "icon_76x.png" },
    { "idiom" : "ipad", "size" : "76x76", "scale" : "2x", "filename" : "icon_152x.png" },
    { "idiom" : "ipad", "size" : "83.5x83.5", "scale" : "2x", "filename" : "icon_167x.png" },
    { "idiom" : "ios-marketing", "size" : "1024x1024", "scale" : "1x", "filename" : "icon_1024x.png" }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
JSON

echo "App icons generated in $APPICON_DIR"

echo "Next: Open Xcode and verify AppIcon source in target General -> App Icons is set to AppIcon"
