#!/bin/zsh
# Builds the windowed Mac disk image from the already-exported app.
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/export/Grid Walk.app"
if [[ ! -d "$APP" ]]; then
  echo "missing $APP"
  exit 1
fi

mkdir -p build
swift scripts/dmg-background.swift "build/dmg-background.png"

hdiutil detach "/Volumes/Grid Walk" >/dev/null 2>&1 || true
for leftover in /private/tmp/gridwalk-dmg.*(N); do
  hdiutil detach "$leftover" >/dev/null 2>&1 || true
done
rm -f "build/GridWalk-rw.dmg" "build/GridWalk.dmg"

hdiutil create -size 48m -fs HFS+ -volname "Grid Walk" "build/GridWalk-rw.dmg" >/dev/null
MOUNT="/Volumes/Grid Walk"
hdiutil attach "build/GridWalk-rw.dmg" -mountpoint "$MOUNT" >/dev/null

cp -R "$APP" "$MOUNT/Grid Walk.app"
ln -s /Applications "$MOUNT/Applications"
mkdir -p "$MOUNT/.background"
# 1x plus 2x, otherwise Finder scales one image and the grid goes soft
sips -z 400 680 "build/dmg-background.png" --out "build/dmg-background-1x.png" >/dev/null
sips -s dpiWidth 72 -s dpiHeight 72 "build/dmg-background-1x.png" >/dev/null
tiffutil -cathidpicheck "build/dmg-background-1x.png" "build/dmg-background.png" -out "$MOUNT/.background/background.tiff" >/dev/null

osascript <<EOF
tell application "Finder"
  tell disk "Grid Walk"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {120, 80, 800, 512}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 128
    set background picture of viewOptions to file ".background:background.tiff"
    set position of item "Grid Walk.app" to {170, 210}
    set position of item "Applications" to {510, 210}
    close
    open
    update without registering applications
    delay 1
  end tell
end tell
EOF

sync
hdiutil detach "$MOUNT" >/dev/null

hdiutil convert "build/GridWalk-rw.dmg" -format UDZO -imagekey zlib-level=9 -o "build/GridWalk.dmg" >/dev/null
rm -f "build/GridWalk-rw.dmg"
echo "wrote build/GridWalk.dmg"
