# Bridge Release + Build Script Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix two bugs in the main build scripts and create a one-time `build_bridge.sh` that publishes a `quickTERMINAL_v1.4.1` release to `LEVOGNE/quickTerminal`, enabling old quickTerminal users to auto-migrate to SystemTrayTerminal.

**Architecture:** Three independent changes to shell scripts. No Swift code changes. `build_bridge.sh` temporarily patches the source version, builds with the old bundle ID, packages, and creates a GitHub release — then cleans up all temp files.

**Tech Stack:** Bash, swiftc, ditto, shasum, gh CLI

**Design doc:** `docs/plans/2026-03-18-bridge-release-design.md`

---

### Task 1: Fix `build_app.sh` — Add Missing WebKit Framework

**Files:**
- Modify: `build_app.sh:40`

**Step 1: Verify the discrepancy**

```bash
grep "framework" build.sh
grep "framework" build_app.sh
```

Expected: `build.sh` has `-framework WebKit`, `build_app.sh` does not.

**Step 2: Add WebKit to build_app.sh**

Find this line in `build_app.sh` (around line 40):
```bash
swiftc -O systemtrayterminal.swift -o "${APP_NAME}_bin" \
  -framework Cocoa -framework Carbon -framework AVKit \
```

Change to:
```bash
swiftc -O systemtrayterminal.swift -o "${APP_NAME}_bin" \
  -framework Cocoa -framework Carbon -framework AVKit -framework WebKit \
```

**Step 3: Verify build still works**

```bash
bash build_app.sh
```

Expected: Completes without errors, prints `[4/4] Done!` and bundle size.

**Step 4: Commit**

```bash
git add build_app.sh
git commit -m "fix: add missing WebKit framework to build_app.sh"
```

---

### Task 2: Fix `build_zip.sh` — Generate SHA256 Sidecar

**Files:**
- Modify: `build_zip.sh`

**Step 1: Locate the packaging section**

Open `build_zip.sh`. After the `/usr/bin/zip` line that adds docs into the zip, there is currently no SHA256 generation. The upload hint at the bottom also needs updating.

**Step 2: Add SHA256 generation after zip is complete**

Find this block (around line 22–24):
```bash
/usr/bin/zip -j "$ZIP_NAME" install.sh FIRST_READ.txt LICENSE README.md

ZIP_SIZE=$(du -sh "$ZIP_NAME" | cut -f1)
```

Replace with:
```bash
/usr/bin/zip -j "$ZIP_NAME" install.sh FIRST_READ.txt LICENSE README.md

# Generate SHA256 sidecar for updater integrity verification
SHA256_NAME="${ZIP_NAME}.sha256"
shasum -a 256 "$ZIP_NAME" | awk '{print $1}' > "$SHA256_NAME"

ZIP_SIZE=$(du -sh "$ZIP_NAME" | cut -f1)
```

**Step 3: Update the output summary and upload hint**

Find:
```bash
echo "    Contents:"
echo "      SystemTrayTerminal.app"
echo "      install.sh"
echo "      FIRST_READ.txt"
echo "      LICENSE"
echo "      README.md"
echo ""
echo "    Ready for GitHub Release v${VERSION}"
echo "    Upload: gh release create v${VERSION} ${ZIP_NAME} --title \"v${VERSION}\""
```

Replace with:
```bash
echo "    Contents:"
echo "      SystemTrayTerminal.app"
echo "      install.sh"
echo "      FIRST_READ.txt"
echo "      LICENSE"
echo "      README.md"
echo ""
echo "    SHA256: ${SHA256_NAME}"
echo ""
echo "    Ready for GitHub Release v${VERSION}"
echo "    Upload: gh release create v${VERSION} ${ZIP_NAME} ${SHA256_NAME} --title \"v${VERSION}\""
```

**Step 4: Verify**

```bash
bash build_zip.sh
ls -lh SystemTrayTerminal_v*.zip SystemTrayTerminal_v*.zip.sha256
cat SystemTrayTerminal_v*.zip.sha256
```

Expected: Both files exist, SHA256 file contains a 64-char hex string (nothing else).

**Step 5: Commit**

```bash
git add build_zip.sh
git commit -m "fix: generate SHA256 sidecar in build_zip.sh for updater verification"
```

---

### Task 3: Create `build_bridge.sh`

**Files:**
- Create: `build_bridge.sh`

**Overview of what the script must do:**
1. Patch source version `1.5.0` → `1.4.1` into a temp file `_bridge_tmp.swift`
2. Build `quickTerminal.app` with bundle ID `com.l3v0.quickterminal`, compiling from `_bridge_tmp.swift`
3. Assemble the full `.app` bundle (icon, fonts, shell configs, Info.plist, mp4)
4. Package `quickTERMINAL_v1.4.1.zip` with app + docs
5. Generate `quickTERMINAL_v1.4.1.zip.sha256` sidecar
6. Clean up all temp files (`_bridge_tmp.swift`, `quickTerminal.app`, iconset, icns)
7. Create GitHub release on `LEVOGNE/quickTerminal`

**Step 1: Create `build_bridge.sh`**

```bash
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
```

**Step 2: Make executable**

```bash
chmod +x build_bridge.sh
```

**Step 3: Verify the script works (dry run — check output, don't publish yet)**

```bash
bash build_bridge.sh
```

Expected output:
- `[1/6]` through `[6/6]` all succeed
- `quickTERMINAL_v1.4.1.zip` exists, size ~15–25 MB
- `quickTERMINAL_v1.4.1.zip.sha256` contains a 64-char hex string
- `_bridge_tmp.swift` is gone
- `quickTerminal.app` is gone
- Original `systemtrayterminal.swift` unchanged: `grep "kAppVersion" systemtrayterminal.swift` still shows `"1.5.0"`

**Step 4: Verify bundle ID and version in zip**

```bash
ditto -xk quickTERMINAL_v1.4.1.zip /tmp/bridge_check/
cat /tmp/bridge_check/quickTerminal.app/Contents/Info.plist | grep -A1 "CFBundleIdentifier\|CFBundleVersion\|CFBundleExecutable"
rm -rf /tmp/bridge_check
```

Expected:
- `CFBundleIdentifier` = `com.l3v0.quickterminal`
- `CFBundleVersion` = `1.4.1`
- `CFBundleExecutable` = `quickTerminal`

**Step 5: Commit**

```bash
git add build_bridge.sh
git commit -m "feat: add build_bridge.sh for one-time quickTerminal → SystemTrayTerminal migration release"
```

---

### Task 4: Publish Bridge Release + Push Everything

**Step 1: Push commits to both repos**

```bash
bash push.sh
```

Expected: "Done. Both repos updated."

**Step 2: Publish the bridge release on quickTerminal repo**

```bash
gh release create v1.4.1 quickTERMINAL_v1.4.1.zip quickTERMINAL_v1.4.1.zip.sha256 \
  --repo LEVOGNE/quickTerminal \
  --title "v1.4.1 — Migration to SystemTrayTerminal" \
  --notes "This update automatically migrates quickTerminal to SystemTrayTerminal, its new name. After installing, the app will offer one final update to complete the migration."
```

**Step 3: Verify release on GitHub**

```bash
gh release view v1.4.1 --repo LEVOGNE/quickTerminal
```

Expected: Shows title, both assets listed (`quickTERMINAL_v1.4.1.zip`, `quickTERMINAL_v1.4.1.zip.sha256`).

**Step 4: Clean up local zip artifacts**

```bash
rm -f quickTERMINAL_v1.4.1.zip quickTERMINAL_v1.4.1.zip.sha256
```
