#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="WeekendRain"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON_SOURCE="$ROOT_DIR/WeekendRain/App/AppIcon.icns"
BUNDLE_ID="dev.weekendrain.app"
MIN_SYSTEM_VERSION="13.0"
PACKAGE_ZIP="$DIST_DIR/$APP_NAME-local.zip"
PACKAGE_DMG="$DIST_DIR/$APP_NAME.dmg"

cd "$ROOT_DIR"

if [ ! -d "$ROOT_DIR/WeekendRain.xcodeproj" ]; then
  xcodegen generate --spec "$ROOT_DIR/project.yml"
fi

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build --product "$APP_NAME"
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$APP_ICON_SOURCE" "$APP_RESOURCES/AppIcon.icns"
rsync -a --delete "$ROOT_DIR/ExternalContent" "$APP_RESOURCES/"

{
  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>'
  printf '%s\n' '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
  printf '%s\n' '<plist version="1.0">'
  printf '%s\n' '<dict>'
  printf '%s\n' '  <key>CFBundleExecutable</key>'
  printf '  <string>%s</string>\n' "$APP_NAME"
  printf '%s\n' '  <key>CFBundleIdentifier</key>'
  printf '  <string>%s</string>\n' "$BUNDLE_ID"
  printf '%s\n' '  <key>CFBundleIconFile</key>'
  printf '%s\n' '  <string>AppIcon</string>'
  printf '%s\n' '  <key>CFBundleName</key>'
  printf '  <string>%s</string>\n' "$APP_NAME"
  printf '%s\n' '  <key>CFBundlePackageType</key>'
  printf '%s\n' '  <string>APPL</string>'
  printf '%s\n' '  <key>LSMinimumSystemVersion</key>'
  printf '  <string>%s</string>\n' "$MIN_SYSTEM_VERSION"
  printf '%s\n' '  <key>NSPrincipalClass</key>'
  printf '%s\n' '  <string>NSApplication</string>'
  printf '%s\n' '</dict>'
  printf '%s\n' '</plist>'
} >"$INFO_PLIST"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  --package|package)
    codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null 2>&1 || true
    rm -f "$PACKAGE_ZIP" "$PACKAGE_DMG"
    (cd "$DIST_DIR" && /usr/bin/ditto -c -k --keepParent "$APP_NAME.app" "$PACKAGE_ZIP")
    /usr/bin/hdiutil create \
      -volname "$APP_NAME" \
      -srcfolder "$APP_BUNDLE" \
      -ov \
      -format UDZO \
      "$PACKAGE_DMG" >/dev/null
    echo "$PACKAGE_ZIP"
    echo "$PACKAGE_DMG"
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--package]" >&2
    exit 2
    ;;
esac
