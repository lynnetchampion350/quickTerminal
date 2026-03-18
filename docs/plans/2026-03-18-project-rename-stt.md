# Project Rename: quickTerminal → STT Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Vollständiges Rename von quickTerminal zu SYSTEM TRAY TERMINAL (STT) — Dateinamen, Bundle-ID, Config-Pfade, Display-Strings, Build-Scripts, Docs.

**Architecture:** Batch-Ersetzungen in Swift-Datei + Build-Scripts, Migrations-Logik für bestehende Installs, dann Directory-Rename als letzter Schritt.

**Tech Stack:** Swift, Bash, git mv

---

## Übersicht der Änderungen

| Was | Alt | Neu |
|---|---|---|
| Source-Datei | `quickTerminal.swift` | `STT.swift` |
| Binary | `quickTerminal` | `STT` |
| App-Bundle | `quickTerminal.app` | `STT.app` |
| Bundle-ID | `com.l3v0.quickterminal` | `com.l3v0.stt` |
| CFBundleDisplayName | `quickTERMINAL` | `SYSTEM TRAY TERMINAL` |
| Config-Dir | `~/.quickterminal/` | `~/.stt/` |
| LaunchAgent Label | `com.quickterminal.autostart` | `com.stt.autostart` |
| Keychain Service | `com.quickTerminal.github` | `com.stt.github` |
| Footer-Text | `quickTERMINAL v…` | `STT v…` |
| Settings-Titel | `quickTERMINAL` | `SYSTEM TRAY TERMINAL` |
| About-Badge | `quickTERMINAL` | `STT` |
| Onboarding-Video | `quickTERMINAL.mp4` | `STT.mp4` |
| Projekt-Verzeichnis | `quickTerminal/` | `STT/` |

---

### Task 1: git mv Source-Datei

**Files:**
- Rename: `quickTerminal.swift` → `STT.swift`

**Step 1: Datei umbenennen mit git**

```bash
cd "/Users/l3v0/Desktop/FERTIGE PROJEKTE/quickTerminal"
git mv quickTerminal.swift STT.swift
```

**Step 2: Verifizieren**

```bash
git status
```
Expected: `renamed: quickTerminal.swift -> STT.swift`

**Step 3: Commit**

```bash
git commit -m "chore: rename quickTerminal.swift → STT.swift"
```

---

### Task 2: Build-Scripts aktualisieren

**Files:**
- Modify: `build.sh`
- Modify: `build_app.sh`
- Modify: `build_zip.sh`

**Step 1: `build.sh` komplett neu schreiben**

Ersetze den Inhalt von `build.sh`:

```bash
#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Building STT..."
swiftc -O STT.swift -o STT -framework Cocoa -framework Carbon -framework AVKit -framework WebKit \
  -Xlinker -sectcreate -Xlinker __FONTS -Xlinker __jbmono -Xlinker _JetBrainsMono-LightItalic-terminal.ttf \
  -Xlinker -sectcreate -Xlinker __FONTS -Xlinker __monocraft -Xlinker _Monocraft-terminal.ttf \
  -Xlinker -sectcreate -Xlinker __DATA -Xlinker __readme -Xlinker README.md \
  -Xlinker -sectcreate -Xlinker __DATA -Xlinker __commands -Xlinker COMMANDS.md \
  -Xlinker -sectcreate -Xlinker __DATA -Xlinker __changelog -Xlinker CHANGELOG.md
echo "Done! Run with: ./STT"

echo ""
echo "Running tests..."
swift tests.swift
echo ""
```

**Step 2: `build_app.sh` — 5 Ersetzungen**

1. Zeile 5: `APP_NAME="quickTerminal"` → `APP_NAME="STT"`
2. Zeile 8: `BUNDLE_ID="com.l3v0.quickterminal"` → `BUNDLE_ID="com.l3v0.stt"`
3. Zeile 11: `quickTerminal.swift` → `STT.swift` (VERSION extraction sed)
4. Zeile 12: Error-Msg `quickTerminal.swift` → `STT.swift`
5. Zeile 40: `swiftc -O quickTerminal.swift` → `swiftc -O STT.swift`
6. Zeile 72: `cp quickTERMINAL.mp4` → `cp STT.mp4`
7. Zeile 86: `<string>quickTERMINAL</string>` (CFBundleDisplayName) → `<string>SYSTEM TRAY TERMINAL</string>`
8. Zeile 112: `quickTERMINAL needs accessibility...` → `STT needs accessibility...`

**Step 3: `build_zip.sh` — 3 Ersetzungen**

1. Zeile 6: `quickTerminal.swift` → `STT.swift`
2. Zeile 7: Error-Msg `quickTerminal.swift` → `STT.swift`
3. Zeile 8: `ZIP_NAME="quickTERMINAL_v${VERSION}.zip"` → `ZIP_NAME="STT_v${VERSION}.zip"`
4. Zeile 19: `ditto -ck ... quickTerminal.app` → `STT.app`
5. Zeilen 29: Echo `quickTerminal.app` → `STT.app`

**Step 4: Commit**

```bash
git add build.sh build_app.sh build_zip.sh
git commit -m "chore: update build scripts for STT rename"
```

---

### Task 3: Onboarding-Video umbenennen

**Files:**
- Rename: `quickTERMINAL.mp4` → `STT.mp4`

**Step 1: Datei umbenennen**

```bash
cd "/Users/l3v0/Desktop/FERTIGE PROJEKTE/quickTerminal"
git mv quickTERMINAL.mp4 STT.mp4
```

**Step 2: Verifizieren**

```bash
ls STT.mp4
```

**Step 3: Commit**

```bash
git commit -m "chore: rename quickTERMINAL.mp4 → STT.mp4"
```

---

### Task 4: In-App Display-Strings in STT.swift

**Files:**
- Modify: `STT.swift`

Ziel: Alle Stellen ersetzen, die dem User angezeigt werden.

**Step 1: Datei-Header (Zeile 1)**

Alt: `// quickTerminal.swift — A simple native terminal emulator for macOS`
Neu: `// STT.swift — SYSTEM TRAY TERMINAL — A native terminal emulator for macOS`

**Step 2: Footer-Text (Zeile 4315)**

Alt: `string: "quickTERMINAL v\(kAppVersion) — LEVOGNE © 2026"`
Neu: `string: "STT v\(kAppVersion) — LEVOGNE © 2026"`

**Step 3: About-Titel (Zeile 13237)**

Alt: `l.append(StyledLine(text: "quickTERMINAL", style: .title))`
Neu: `l.append(StyledLine(text: "STT", style: .title))`

**Step 4: NSMenu-Items (Zeilen 20466, 20468)**

Alt: `"About quickTerminal"`  → Neu: `"About STT"`
Alt: `"Quit quickTerminal"` → Neu: `"Quit STT"`

**Step 5: fullDiskAccessMsg in allen Sprachen (Zeilen 289, 358, 427, 496, 565, 634, 703, 772, 841, 910)**

Replace all: `quickTERMINAL` in `fullDiskAccessMsg` strings → `STT`
(Nur in den Localizations-Dicts, nicht in Kommentaren)

**Step 6: quitApp-Strings in allen Sprachen**

Replace all:
- `"Quit quickTerminal"` → `"Quit STT"`
- `"quickTerminal beenden"` → `"STT beenden"`
- `"quickTerminal'i Kapat"` → `"STT'yi Kapat"`
- `"Salir de quickTerminal"` → `"Salir de STT"`
- `"Quitter quickTerminal"` → `"Quitter STT"`
- `"Esci da quickTerminal"` → `"Esci da STT"`
- `"إنهاء quickTerminal"` → `"إنهاء STT"`
- `"quickTerminal を終了"` → `"STT を終了"`
- `"退出 quickTerminal"` → `"退出 STT"`
- `"Выйти из quickTerminal"` → `"Выйти из STT"`

**Step 7: Feedback-Email (Zeilen 8002–8004, 8053)**

Alt:
```swift
let subject = "quickTERMINAL Feedback"
let hostname = Host.current().localizedName ?? "quickTerminal-user"
let email = "From: quickTerminal@\(hostname)\r\n..."
```
Neu:
```swift
let subject = "STT Feedback"
let hostname = Host.current().localizedName ?? "STT-user"
let email = "From: STT@\(hostname)\r\n..."
```
(Zeile 8053: `let subject = "quickTERMINAL Feedback"` → `"STT Feedback"`)

**Step 8: Device Attribute Response (Zeile 2248)**

Alt: `onResponse?("\u{1B}P>|quickTerminal(1.0)\u{1B}\\")`
Neu: `onResponse?("\u{1B}P>|STT(1.0)\u{1B}\\")`

**Step 9: Crash-Log / Lock-Datei (Zeilen 20403, 20415, 20428, 20441)**

Alt: `let lockPath = NSTemporaryDirectory() + "quickTerminal.lock"`
Neu: `let lockPath = NSTemporaryDirectory() + "STT.lock"`

Alt (20415, 20428): `NSHomeDirectory() + "/.quickterminal"`
Neu: `NSHomeDirectory() + "/.stt"`

Alt (20441): `var msg = "quickTerminal crashed with signal \(sigNum)\n"`
Neu: `var msg = "STT crashed with signal \(sigNum)\n"`

**Step 10: GitHub Token Description (Zeile 10834)**

Suche: `scopes=repo&description=quickTerminal`
Neu: `scopes=repo&description=STT`

**Step 11: Commit**

```bash
git add STT.swift
git commit -m "feat: update all in-app display strings for STT rename"
```

---

### Task 5: System-Identifiers in STT.swift

**Files:**
- Modify: `STT.swift`

**Step 1: LaunchAgent Label (Zeilen 8580, 8588)**

Alt:
```swift
let plistPath = "\(agentDir)/com.quickterminal.autostart.plist"
"Label": "com.quickterminal.autostart",
```
Neu:
```swift
let plistPath = "\(agentDir)/com.stt.autostart.plist"
"Label": "com.stt.autostart",
```

**Step 2: Keychain Service (Zeile 8605)**

Alt: `private static let service = "com.quickTerminal.github"`
Neu: `private static let service = "com.stt.github"`

**Step 3: Config-Dir (Zeile 3158)**

Alt: `let histDir = "\(homeDir)/.quickterminal/history"`
Neu: `let histDir = "\(homeDir)/.stt/history"`

**Step 4: Update-Installer Temp-Pfade (Zeilen 14623, 14682, 14711, 14745)**

Alt: `"quickTerminal_update_\(UUID().uuidString).zip"`
Neu: `"STT_update_\(UUID().uuidString).zip"`

Alt: `"quickTerminal_extract_\(UUID().uuidString)"`
Neu: `"STT_extract_\(UUID().uuidString)"`

Alt: `appBundle.appendingPathComponent("Contents/MacOS/quickTerminal")`
Neu: `appBundle.appendingPathComponent("Contents/MacOS/STT")`

Alt: `"quickTerminal_backup_\(UUID().uuidString).app"`
Neu: `"STT_backup_\(UUID().uuidString).app"`

**Step 5: GitHub API URL (Zeile 14537)**

Alt: `https://api.github.com/repos/LEVOGNE/quickTerminal/releases/latest`
Neu: `https://api.github.com/repos/LEVOGNE/STT/releases/latest`

> **Hinweis:** Diese URL funktioniert erst nach dem GitHub-Repo-Rename auf github.com!

**Step 6: Onboarding-Video Resource (Zeile 14894)**

Alt: `Bundle.main.url(forResource: "quickTERMINAL", withExtension: "mp4")`
Neu: `Bundle.main.url(forResource: "STT", withExtension: "mp4")`

**Step 7: Factory Reset (Zeilen 17882–17910)**

Alt:
```swift
// --- Full factory reset: delete ALL quickTerminal data from system ---
// A) Delete ~/.quickterminal/ directory (shell history files)
try? fm.removeItem(atPath: home + "/.quickterminal")
```
Neu:
```swift
// --- Full factory reset: delete ALL STT data from system ---
// A) Delete ~/.stt/ directory (shell history files)
try? fm.removeItem(atPath: home + "/.stt")
```

Zeile 17908:
Alt: `cachesDir + "/com.l3v0.quickterminal"`
Neu: `cachesDir + "/com.l3v0.stt"`

**Step 8: SVG-Kommentar (Zeile 16636)**

Alt: `// Exact reproduction of quickTERMINAL.svg`
Neu: `// Exact reproduction of STT.svg` (oder einfach entfernen)

**Step 9: Commit**

```bash
git add STT.swift
git commit -m "feat: update all system identifiers for STT (bundle, LaunchAgent, keychain, paths)"
```

---

### Task 6: Migrations-Logik hinzufügen

**Files:**
- Modify: `STT.swift` — in `applicationDidFinishLaunching`, direkt nach Zeile 16619 (nach `register(defaults:)`)

**Step 1: Migrations-Funktion hinzufügen**

Füge **vor** `applicationDidFinishLaunching` eine private Funktion ein:

```swift
private func migrateLegacyData() {
    let fm = FileManager.default
    let home = NSHomeDirectory()
    let oldConfigDir = home + "/.quickterminal"
    let newConfigDir = home + "/.stt"

    // 1. Migrate config directory
    if fm.fileExists(atPath: oldConfigDir) && !fm.fileExists(atPath: newConfigDir) {
        do {
            try fm.copyItem(atPath: oldConfigDir, toPath: newConfigDir)
            try fm.removeItem(atPath: oldConfigDir)
        } catch {
            // Migration failed — leave old dir intact
        }
    }

    // 2. Migrate UserDefaults from old domain to new domain
    let oldDomain = "com.l3v0.quickterminal"
    let newDomain = "com.l3v0.stt"
    let defaults = UserDefaults.standard
    if let oldPrefs = UserDefaults(suiteName: oldDomain)?.dictionaryRepresentation(),
       !oldPrefs.isEmpty {
        let newDefaults = UserDefaults(suiteName: newDomain)
        for (key, value) in oldPrefs {
            if newDefaults?.object(forKey: key) == nil {
                newDefaults?.set(value, forKey: key)
            }
        }
        newDefaults?.synchronize()
        // Remove old domain
        defaults.removePersistentDomain(forName: oldDomain)
    }

    // 3. Migrate LaunchAgent (unload old, new will be registered on next autostart toggle)
    let agentDir = home + "/Library/LaunchAgents"
    let oldPlist = agentDir + "/com.quickterminal.autostart.plist"
    if fm.fileExists(atPath: oldPlist) {
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["unload", oldPlist]
        try? task.run()
        task.waitUntilExit()
        try? fm.removeItem(atPath: oldPlist)
    }
}
```

**Step 2: Migrations-Aufruf in `applicationDidFinishLaunching`**

Direkt nach `UserDefaults.standard.register(defaults: SettingsOverlay.defaultSettings)` (Zeile 16619) einfügen:

```swift
// Migrate legacy data from quickTerminal → STT
migrateLegacyData()
```

**Step 3: Build und Test**

```bash
bash build.sh
```
Expected: Kompiliert ohne Fehler, Tests grün.

**Step 4: Commit**

```bash
git add STT.swift
git commit -m "feat: add legacy data migration quickTerminal → STT"
```

---

### Task 7: install.sh und FIRST_READ.txt aktualisieren

**Files:**
- Modify: `install.sh`
- Modify: `FIRST_READ.txt`

**Step 1: `install.sh` aktualisieren**

Ersetze alle Vorkommen:
- `quickTerminal.app` → `STT.app`
- `quickTERMINAL Installer` → `STT Installer`
- `=== quickTERMINAL Installer ===` → `=== STT — SYSTEM TRAY TERMINAL Installer ===`

**Step 2: `FIRST_READ.txt` aktualisieren**

Ersetze:
- `quickTERMINAL` → `STT` (alle Vorkommen im ASCII-Banner und Text)
- `quickTerminal.app` → `STT.app`
- `xattr -cr quickTerminal.app` → `xattr -cr STT.app`
- GitHub-URL: `LEVOGNE/quickTerminal` → `LEVOGNE/STT`

**Step 3: Commit**

```bash
git add install.sh FIRST_READ.txt
git commit -m "docs: update install.sh and FIRST_READ.txt for STT"
```

---

### Task 8: Dokumentation aktualisieren

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `COMMANDS.md`
- Modify: `ROADMAP.md`
- Modify: `MARKETING.md`
- Modify: `CONTRIBUTING.md`
- Modify: `SECURITY.md`
- Modify: `CLAUDE.md`
- Modify: `docs/index.html` (falls vorhanden)

**Step 1: Batch-Ersetzung in allen Docs**

```bash
cd "/Users/l3v0/Desktop/FERTIGE PROJEKTE/quickTerminal"
# Alle Markdown-Dateien
for f in README.md CHANGELOG.md COMMANDS.md ROADMAP.md MARKETING.md CONTRIBUTING.md SECURITY.md CLAUDE.md CODE_OF_CONDUCT.md REMAINING_COMPAT.md; do
    [ -f "$f" ] || continue
    sed -i '' \
        -e 's/quickTERMINAL/STT/g' \
        -e 's/quickTerminal/STT/g' \
        -e 's/quickterminal/stt/g' \
        "$f"
done
```

> **ACHTUNG**: Durchgehen und prüfen ob semantische Änderungen korrekt sind — besonders in CHANGELOG.md (historische Versionsnamen).

**Step 2: docs/index.html**

```bash
[ -f docs/index.html ] && sed -i '' \
    -e 's/quickTERMINAL/STT/g' \
    -e 's/quickTerminal/STT/g' \
    -e 's/quickterminal/stt/g' \
    docs/index.html
```

**Step 3: CLAUDE.md im Projekt — Hauptdatei-Referenz aktualisieren**

In `CLAUDE.md` Zeile `- **Hauptdatei**: \`quickTerminal.swift\`...`:
Neu: `- **Hauptdatei**: \`STT.swift\`...`

**Step 4: Commit**

```bash
git add README.md CHANGELOG.md COMMANDS.md ROADMAP.md MARKETING.md CONTRIBUTING.md SECURITY.md CLAUDE.md docs/
git commit -m "docs: rename quickTerminal → STT throughout all documentation"
```

---

### Task 9: Build und vollständigen Test durchführen

**Step 1: Build**

```bash
cd "/Users/l3v0/Desktop/FERTIGE PROJEKTE/quickTerminal"
bash build.sh
```
Expected: `Done! Run with: ./STT`, alle Tests grün.

**Step 2: Alte Binaries aufräumen**

```bash
rm -f quickTerminal quickTerminal_debug.dSYM 2>/dev/null || true
```

**Step 3: App-Bundle testen**

```bash
bash build_app.sh
```
Expected: `STT.app` wird erstellt.

**Step 4: Commit wenn nötig**

```bash
git status
# Nur wenn es ungestagete Änderungen gibt:
git add -A && git commit -m "chore: clean up old build artifacts"
```

---

### Task 10: Verzeichnis umbenennen

> **WICHTIG:** Dieser Task kommt ZULETZT! Nach dem Rename ändert sich der Pfad für git und alle weiteren Operationen.

**Step 1: Verzeichnis umbenennen**

```bash
mv "/Users/l3v0/Desktop/FERTIGE PROJEKTE/quickTerminal" "/Users/l3v0/Desktop/FERTIGE PROJEKTE/STT"
```

**Step 2: Memory-Verzeichnis für neuen Pfad vorbereiten**

```bash
mkdir -p "/Users/l3v0/.claude/projects/-Users-l3v0-Desktop-FERTIGE-PROJEKTE-STT/memory"
cp "/Users/l3v0/.claude/projects/-Users-l3v0-Desktop-FERTIGE-PROJEKTE-quickTerminal/memory/MEMORY.md" \
   "/Users/l3v0/.claude/projects/-Users-l3v0-Desktop-FERTIGE-PROJEKTE-STT/memory/MEMORY.md"
```

**Step 3: MEMORY.md im neuen Pfad aktualisieren**

Ersetze in der kopierten MEMORY.md alle Pfad-Referenzen:
- `quickTerminal.swift` → `STT.swift`
- `/quickTerminal/` → `/STT/`
- `~/.quickterminal/` → `~/.stt/`
- `com.l3v0.quickterminal` → `com.l3v0.stt`

**Step 4: In neues Verzeichnis wechseln und verifizieren**

```bash
cd "/Users/l3v0/Desktop/FERTIGE PROJEKTE/STT"
git status
git log --oneline -5
```
Expected: git history vollständig erhalten.

**Step 5: Abschließender Build**

```bash
bash build.sh
```
Expected: Läuft sauber durch.

---

### Task 11: GitHub-Hinweis

Das GitHub-Repository muss manuell umbenannt werden:

1. Auf https://github.com/LEVOGNE/quickTerminal gehen
2. Settings → Danger Zone → Rename Repository → `STT`
3. Danach Remote-URL aktualisieren:

```bash
cd "/Users/l3v0/Desktop/FERTIGE PROJEKTE/STT"
git remote set-url origin https://github.com/LEVOGNE/STT.git
git push origin main
```

---

## Reihenfolge der Commits

1. `chore: rename quickTerminal.swift → STT.swift`
2. `chore: update build scripts for STT rename`
3. `chore: rename quickTERMINAL.mp4 → STT.mp4`
4. `feat: update all in-app display strings for STT rename`
5. `feat: update all system identifiers for STT (bundle, LaunchAgent, keychain, paths)`
6. `feat: add legacy data migration quickTerminal → STT`
7. `docs: update install.sh and FIRST_READ.txt for STT`
8. `docs: rename quickTerminal → STT throughout all documentation`
9. *(Directory-Rename ist kein git-commit)*
