# Design: Bridge Release + Build Script Fixes (v1.5.0)

**Date**: 2026-03-18
**Status**: Approved

---

## Motivation

Old `quickTerminal` users (≤ v1.4.0) check `LEVOGNE/quickTerminal/releases/latest` for updates.
The rename to SystemTrayTerminal changed the bundle ID (`com.l3v0.quickterminal` → `com.l3v0.systemtrayterminal`).
Since the `knownMigration` code was added **after** v1.4.0, those users cannot auto-update directly
to SystemTrayTerminal — their old updater rejects the bundle ID mismatch.

Additionally, two bugs were found in the main build scripts.

---

## Part 1 — Fix `build_app.sh`: Missing WebKit Framework

`build.sh` links `-framework WebKit`; `build_app.sh` does not.
This means production `.app` bundles may fail to load WebKit at runtime.

**Fix**: Add `-framework WebKit` to the `swiftc` call in `build_app.sh`.

---

## Part 2 — Fix `build_zip.sh`: Missing SHA256 Sidecar

The updater (`UpdateChecker`) looks for a `.sha256` sidecar asset in the GitHub release
to verify download integrity before installing. `build_zip.sh` never generates this file,
so SHA256 verification is always skipped.

**Fix**: After creating the ZIP, generate `${ZIP_NAME}.sha256` via:
```bash
shasum -a 256 "$ZIP_NAME" | awk '{print $1}' > "${ZIP_NAME}.sha256"
```
Update the upload hint at the end of the script to include the `.sha256` file.

---

## Part 3 — `build_bridge.sh`: One-Time Migration Release

### Approach

Dedicated script `build_bridge.sh` (Approach A). Does not modify any existing scripts.

### What It Does

1. **Patch source** — copy `systemtrayterminal.swift` to `_bridge_tmp.swift`, then:
   - Replace `kAppVersion = "1.5.0"` → `"1.4.1"` (so bridge sees STT v1.5.0 as newer)
   - No other changes — `knownMigration` and update URL (`LEVOGNE/SystemTrayTerminal`) stay intact

2. **Build `quickTerminal.app`** — same swiftc flags as `build_app.sh`, but:
   - Source: `_bridge_tmp.swift`
   - `APP_NAME = quickTerminal`
   - `BUNDLE_ID = com.l3v0.quickterminal`
   - `CFBundleDisplayName = quickTerminal`
   - Binary at: `quickTerminal.app/Contents/MacOS/quickTerminal`

3. **Package ZIP** — `quickTERMINAL_v1.4.1.zip` containing:
   - `quickTerminal.app`
   - `install.sh`, `FIRST_READ.txt`, `LICENSE`, `README.md`

4. **Generate SHA256** — `quickTERMINAL_v1.4.1.zip.sha256` sidecar

5. **Cleanup** — remove `_bridge_tmp.swift`, `quickTerminal.app`, icon temp files

6. **Create GitHub Release** on `LEVOGNE/quickTerminal`:
   ```
   gh release create v1.4.1 \
     quickTERMINAL_v1.4.1.zip \
     quickTERMINAL_v1.4.1.zip.sha256 \
     --repo LEVOGNE/quickTerminal \
     --title "v1.4.1 — Automatic Migration to SystemTrayTerminal" \
     --notes "..."
   ```

### Migration Flow (End-User)

```
quickTerminal v1.4.0 (user)
  → checks LEVOGNE/quickTerminal → finds v1.4.1 bridge
  → bundle ID com.l3v0.quickterminal matches → installs
  → bridge starts, checks LEVOGNE/SystemTrayTerminal → finds v1.5.0
  → knownMigration (quickterminal → systemtrayterminal) passes → installs
  → user now runs SystemTrayTerminal v1.5.0 ✅
```

### Script Lifetime

`build_bridge.sh` stays in the repo permanently as documentation of how the migration was built.
It is a one-time-run script — never to be run again after v1.4.1 is published.

---

## Files Changed

| File | Change |
|------|--------|
| `build_app.sh` | Add `-framework WebKit` |
| `build_zip.sh` | Generate + output `.sha256` sidecar |
| `build_bridge.sh` | New file — one-time bridge build + release |
