#!/bin/bash
# One-time bridge release: quickTERMINAL v1.4.1
# Builds quickTerminal.app (com.l3v0.quickterminal) from current STT source.
# Old quickTerminal v1.4.0 users install this, then auto-migrate to SystemTrayTerminal v1.5.0.
# DO NOT RUN AGAIN after v1.4.1 is published on LEVOGNE/quickTerminal.
set -e
cd "$(dirname "$0")"

BRIDGE_VERSION="1.4.1"
APP_NAME="quickTerminal"
BUNDLE="${APP_NAME}.app"
BUNDLE_ID="com.l3v0.quickterminal"
DISPLAY_NAME="quickTerminal"
ZIP_NAME="quickTERMINAL_v${BRIDGE_VERSION}.zip"
SHA256_NAME="${ZIP_NAME}.sha256"
TMP_SRC="_bridge_tmp.swift"
ICON_SRC="icon.png"

echo "=== Building Bridge Release: ${ZIP_NAME} ==="
echo "    Bundle ID : ${BUNDLE_ID}"
echo "    Version   : ${BRIDGE_VERSION}"
echo ""

# ─── Step 1: Patch source version ───
echo "[1/6] Patching source version ${BRIDGE_VERSION}..."
sed "s/let kAppVersion = \"[^\"]*\"/let kAppVersion = \"${BRIDGE_VERSION}\"/" \
    systemtrayterminal.swift > "$TMP_SRC"
echo "    ${TMP_SRC} created"

# ─── Step 2: Create .icns ───
echo "[2/6] Creating app icon..."
ICONSET="${APP_NAME}.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
sips -z 16 16     "$ICON_SRC" --out "${ICONSET}/icon_16x16.png"      > /dev/null 2>&1
sips -z 32 32     "$ICON_SRC" --out "${ICONSET}/icon_16x16@2x.png"   > /dev/null 2>&1
sips -z 32 32     "$ICON_SRC" --out "${ICONSET}/icon_32x32.png"      > /dev/null 2>&1
sips -z 64 64     "$ICON_SRC" --out "${ICONSET}/icon_32x32@2x.png"   > /dev/null 2>&1
sips -z 128 128   "$ICON_SRC" --out "${ICONSET}/icon_128x128.png"    > /dev/null 2>&1
sips -z 256 256   "$ICON_SRC" --out "${ICONSET}/icon_128x128@2x.png" > /dev/null 2>&1
sips -z 256 256   "$ICON_SRC" --out "${ICONSET}/icon_256x256.png"    > /dev/null 2>&1
sips -z 512 512   "$ICON_SRC" --out "${ICONSET}/icon_256x256@2x.png" > /dev/null 2>&1
sips -z 512 512   "$ICON_SRC" --out "${ICONSET}/icon_512x512.png"    > /dev/null 2>&1
sips -z 1024 1024 "$ICON_SRC" --out "${ICONSET}/icon_512x512@2x.png" > /dev/null 2>&1
iconutil -c icns "$ICONSET" -o AppIcon.icns
rm -rf "$ICONSET"
echo "    AppIcon.icns created"

# ─── Step 3: Compile binary ───
echo "[3/6] Compiling binary (this takes a while)..."
swiftc -O "$TMP_SRC" -o "${APP_NAME}_bin" \
  -framework Cocoa -framework Carbon -framework AVKit -framework WebKit \
  -Xlinker -sectcreate -Xlinker __FONTS -Xlinker __jbmono -Xlinker _JetBrainsMono-LightItalic-terminal.ttf \
  -Xlinker -sectcreate -Xlinker __FONTS -Xlinker __monocraft -Xlinker _Monocraft-terminal.ttf \
  -Xlinker -sectcreate -Xlinker __DATA -Xlinker __readme -Xlinker README.md \
  -Xlinker -sectcreate -Xlinker __DATA -Xlinker __commands -Xlinker COMMANDS.md \
  -Xlinker -sectcreate -Xlinker __DATA -Xlinker __changelog -Xlinker CHANGELOG.md
echo "    Binary compiled"

# ─── Step 4: Assemble .app bundle ───
echo "[4/6] Assembling ${BUNDLE}..."
rm -rf "$BUNDLE"
mkdir -p "${BUNDLE}/Contents/MacOS"
mkdir -p "${BUNDLE}/Contents/Resources"

mv "${APP_NAME}_bin" "${BUNDLE}/Contents/MacOS/${APP_NAME}"

cp _FiraCode-Regular-terminal.ttf "${BUNDLE}/Contents/MacOS/"
cp _FiraCode-Bold-terminal.ttf    "${BUNDLE}/Contents/MacOS/"
cp _IosevkaThin-terminal.ttf      "${BUNDLE}/Contents/MacOS/"
cp -R shell "${BUNDLE}/Contents/MacOS/shell"
rm -f "${BUNDLE}/Contents/MacOS/shell/.zsh_history"

cp AppIcon.icns "${BUNDLE}/Contents/Resources/"
cp SystemTrayTerminal.mp4 "${BUNDLE}/Contents/Resources/"

echo -n "APPL????" > "${BUNDLE}/Contents/PkgInfo"

cat > "${BUNDLE}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${DISPLAY_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${BRIDGE_VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${BRIDGE_VERSION}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
    <key>NSAppleEventsUsageDescription</key>
    <string>quickTerminal needs accessibility access for the global hotkey.</string>
</dict>
</plist>
PLIST
echo "    Bundle assembled"

# ─── Step 5: Package ZIP + SHA256 ───
echo "[5/6] Packaging ${ZIP_NAME}..."
rm -f "$ZIP_NAME" "$SHA256_NAME"
ditto -ck --sequesterRsrc --keepParent "$BUNDLE" "$ZIP_NAME"
/usr/bin/zip -j "$ZIP_NAME" install.sh FIRST_READ.txt LICENSE README.md
shasum -a 256 "$ZIP_NAME" | awk '{print $1}' > "$SHA256_NAME"

ZIP_SIZE=$(du -sh "$ZIP_NAME" | cut -f1)
echo "    ${ZIP_NAME}  →  ${ZIP_SIZE}"
echo "    ${SHA256_NAME}  →  $(cat "$SHA256_NAME")"

# ─── Step 6: Cleanup ───
echo "[6/6] Cleaning up temp files..."
rm -f "$TMP_SRC" AppIcon.icns
rm -rf "$BUNDLE"
echo "    Done"

echo ""
echo "=== Bridge release ready ==="
echo ""
echo "    ${ZIP_NAME}"
echo "    ${SHA256_NAME}"
echo ""
echo "    To publish:"
echo "    gh release create v${BRIDGE_VERSION} ${ZIP_NAME} ${SHA256_NAME} \\"
echo "      --repo LEVOGNE/quickTerminal \\"
echo "      --title \"v${BRIDGE_VERSION} — Migration to SystemTrayTerminal\" \\"
echo "      --notes \"This update automatically migrates quickTerminal to SystemTrayTerminal, its new name. After installing, the app will offer one final update to complete the migration.\""
echo ""
echo "    IMPORTANT: Run this gh command manually to publish — do not automate."
