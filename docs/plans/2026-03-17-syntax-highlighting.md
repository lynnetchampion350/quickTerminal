# Syntax Highlighting + File Drop Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add live syntax highlighting for JSON/HTML/CSS/JS in the text editor, plus drag-a-file-onto-the-tab-header to open it.

**Architecture:** Custom `NSTextStorage` subclass (`SyntaxTextStorage`) auto-highlights on every edit (debounced 0.15s). `SyntaxLanguage` enum detects language from file extension. `HeaderBarView` adopts `NSDraggingDestination` for file drop.

**Tech Stack:** AppKit — NSTextStorage, NSRegularExpression, NSDraggingDestination. No new dependencies.

---

## Task 1: `SyntaxLanguage` enum + tests

**Files:**
- Modify: `tests.swift` (add stub + tests at end of file)
- Modify: `quickTerminal.swift` (add enum before `// MARK: - Text Editor`, line 14482)

### Step 1: Add test stub + test cases to `tests.swift`

Add at the end of `tests.swift`, before the final `runAll()` call (or wherever tests are registered):

```swift
// ── SyntaxLanguage stub (mirrors quickTerminal.swift) ────────────────────────
enum SyntaxLanguage_Test: String {
    case none, json, html, css, javascript

    static func detect(from url: URL) -> SyntaxLanguage_Test {
        switch url.pathExtension.lowercased() {
        case "json":                                    return .json
        case "html", "htm":                             return .html
        case "css":                                     return .css
        case "js", "mjs", "cjs", "ts", "tsx", "jsx":   return .javascript
        default:                                        return .none
        }
    }
}

func testSyntaxLanguageDetection() {
    let cases: [(String, SyntaxLanguage_Test)] = [
        ("data.json",    .json),
        ("index.html",   .html),
        ("index.htm",    .html),
        ("style.css",    .css),
        ("app.js",       .javascript),
        ("app.mjs",      .javascript),
        ("app.ts",       .javascript),
        ("app.tsx",      .javascript),
        ("app.jsx",      .javascript),
        ("README.md",    .none),
        ("main.swift",   .none),
        ("Makefile",     .none),
    ]
    for (filename, expected) in cases {
        let url = URL(fileURLWithPath: "/tmp/\(filename)")
        let got = SyntaxLanguage_Test.detect(from: url)
        assert(got == expected, "detect(\(filename)): expected \(expected), got \(got)")
    }
    print("✓ SyntaxLanguage.detect — \(cases.count) cases")
}
```

Also call it from the test runner (find where other test functions are called and add `testSyntaxLanguageDetection()`).

### Step 2: Run tests — expect PASS

```bash
swift tests.swift
```
Expected: all existing tests pass + new `✓ SyntaxLanguage.detect` line printed.

### Step 3: Add `SyntaxLanguage` enum to `quickTerminal.swift`

Find `// MARK: - Text Editor` at line 14482. Insert the following **directly above** it:

```swift
// MARK: - Syntax Highlighting

enum SyntaxLanguage: String {
    case none, json, html, css, javascript

    static func detect(from url: URL) -> SyntaxLanguage {
        switch url.pathExtension.lowercased() {
        case "json":                                    return .json
        case "html", "htm":                             return .html
        case "css":                                     return .css
        case "js", "mjs", "cjs", "ts", "tsx", "jsx":   return .javascript
        default:                                        return .none
        }
    }
}
```

### Step 4: Build

```bash
bash build.sh
```
Expected: compiles + all tests pass. No behavioral change yet.

### Step 5: Commit

```bash
git add quickTerminal.swift tests.swift
git commit -m "feat: SyntaxLanguage enum + detect(from:) + tests"
```

---

## Task 2: `SyntaxRule` + `SyntaxTextStorage` classes

**Files:**
- Modify: `quickTerminal.swift` — add after `SyntaxLanguage` enum (inside `// MARK: - Syntax Highlighting`)

### Step 1: Add `SyntaxRule` struct

Insert directly after the `SyntaxLanguage` closing brace:

```swift
private struct SyntaxRule {
    let regex: NSRegularExpression
    let color: NSColor
    let group: Int  // 0 = whole match, >0 = capture group

    init(_ pattern: String, _ color: NSColor, group: Int = 0,
         options: NSRegularExpression.Options = [.dotMatchesLineSeparators]) {
        // Patterns are literals — crash at launch if malformed (never in practice)
        self.regex = try! NSRegularExpression(pattern: pattern, options: options)
        self.color = color
        self.group = group
    }
}

// Module-level cache: rules compiled once per (language, isDark) pair
private var _syntaxRulesCache: [String: [SyntaxRule]] = [:]
```

### Step 2: Add rules factory as `SyntaxLanguage` extension

Insert directly after `_syntaxRulesCache`:

```swift
private extension SyntaxLanguage {
    static func rules(for lang: SyntaxLanguage, isDark: Bool) -> [SyntaxRule] {
        let key = "\(lang.rawValue)-\(isDark)"
        if let cached = _syntaxRulesCache[key] { return cached }
        let rules = buildRules(lang: lang, isDark: isDark)
        _syntaxRulesCache[key] = rules
        return rules
    }

    // IMPORTANT: Rules are applied in ORDER — later rules overwrite earlier ones.
    // Put lower-priority rules first (base colors), higher-priority last (keywords, tags).
    private static func buildRules(lang: SyntaxLanguage, isDark: Bool) -> [SyntaxRule] {
        // Helper: hex color
        func c(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
            NSColor(calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255,
                    green:         CGFloat((hex >> 8)  & 0xFF) / 255,
                    blue:          CGFloat(hex         & 0xFF) / 255,
                    alpha: alpha)
        }

        switch lang {
        case .none: return []

        case .json:
            let string  = isDark ? c(0xCE9178) : c(0xA31515)
            let number  = isDark ? c(0xB5CEA8) : c(0x098658)
            let keyword = isDark ? c(0x569CD6) : c(0x0000FF)
            let key     = isDark ? c(0x9CDCFE) : c(0x001080)
            let punct   = isDark ? c(0x808080) : c(0x555555)
            return [
                SyntaxRule(#""[^"\\]*(?:\\.[^"\\]*)*""#,     string),
                SyntaxRule(#"-?\b\d+\.?\d*([eE][+-]?\d+)?\b"#, number),
                SyntaxRule(#"\b(true|false|null)\b"#,        keyword),
                SyntaxRule(#"[{}\[\]:,]"#,                   punct),
                // Keys override plain strings — apply last
                SyntaxRule(#""[^"\\]*(?:\\.[^"\\]*)*"(?=\s*:)"#, key),
            ]

        case .html:
            let comment = isDark ? c(0x6A9955) : c(0x008000)
            let tag     = isDark ? c(0x4EC9B0) : c(0x800000)
            let attrN   = isDark ? c(0x9CDCFE) : c(0xE50000)
            let attrV   = isDark ? c(0xCE9178) : c(0xA31515)
            let doctype = isDark ? c(0x569CD6) : c(0x0000FF)
            return [
                SyntaxRule(#"<!--[\s\S]*?-->"#,              comment),
                SyntaxRule(#"<!DOCTYPE[^>]*>"#,              doctype, options: [.caseInsensitive]),
                SyntaxRule(#"</?[\w:-]+"#,                   tag),
                SyntaxRule(#"\b[\w:-]+(?=\s*=)"#,            attrN),
                SyntaxRule(#""[^"]*"|'[^']*'"#,              attrV),
            ]

        case .css:
            let comment  = isDark ? c(0x6A9955) : c(0x008000)
            let atRule   = isDark ? c(0xC586C0) : c(0xAF00DB)
            let selector = isDark ? c(0xD7BA7D) : c(0x800000)
            let prop     = isDark ? c(0x9CDCFE) : c(0xFF0000)
            let value    = isDark ? c(0xCE9178) : c(0xA31515)
            let number   = isDark ? c(0xB5CEA8) : c(0x098658)
            let color    = isDark ? c(0x4EC9B0) : c(0x098658)
            return [
                SyntaxRule(#"\/\*[\s\S]*?\*\/"#,             comment),
                SyntaxRule(#"@[\w-]+"#,                      atRule),
                SyntaxRule(#"[^{};,]+(?=\s*\{)"#,            selector),
                SyntaxRule(#"[\w-]+(?=\s*:)"#,               prop),
                SyntaxRule(#""[^"]*"|'[^']*'"#,              value),
                SyntaxRule(#"#[0-9a-fA-F]{3,8}\b"#,          color),
                SyntaxRule(#"\b\d+\.?\d*(%|px|em|rem|vh|vw|pt|s|ms)?\b"#, number),
            ]

        case .javascript:
            let comment  = isDark ? c(0x6A9955) : c(0x008000)
            let string   = isDark ? c(0xCE9178) : c(0xA31515)
            let number   = isDark ? c(0xB5CEA8) : c(0x098658)
            let keyword  = isDark ? c(0x569CD6) : c(0x0000FF)
            let fnCall   = isDark ? c(0xDCDCAA) : c(0x795E26)
            return [
                SyntaxRule(#"\/\*[\s\S]*?\*\/"#,             comment),
                SyntaxRule(#"\/\/[^\n]*"#,                   comment, options: []),
                SyntaxRule(#"`[^`]*`"#,                      string),
                SyntaxRule(#""[^"\\]*(?:\\.[^"\\]*)*""#,     string),
                SyntaxRule(#"'[^'\\]*(?:\\.[^'\\]*)*'"#,     string),
                SyntaxRule(#"\b\d+\.?\d*\b"#,                number),
                SyntaxRule(#"\b(const|let|var|function|return|if|else|for|while|do|switch|case|break|continue|new|this|class|extends|import|export|default|from|async|await|typeof|instanceof|null|undefined|true|false|void|throw|try|catch|finally|delete|in|of)\b"#, keyword),
                SyntaxRule(#"\b[\w$]+(?=\s*\()"#,            fnCall),
            ]
        }
    }
}
```

### Step 3: Add `SyntaxTextStorage` class

Insert after the `SyntaxLanguage` extension:

```swift
final class SyntaxTextStorage: NSTextStorage {
    private let backing = NSMutableAttributedString()
    var language: SyntaxLanguage = .none { didSet { if oldValue != language { highlight() } } }
    var isDark: Bool = true          { didSet { if oldValue != isDark  { highlight() } } }
    var baseFont: NSFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    var baseFG:   NSColor = .white

    private var highlightTimer: Timer?

    // ── NSTextStorage backing store ──────────────────────────────────────────

    override var string: String { backing.string }

    override func attributes(at location: Int,
                             effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        backing.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        backing.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: str.utf16.count - range.length)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()
        backing.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    // ── Highlighting ─────────────────────────────────────────────────────────

    override func processEditing() {
        super.processEditing()
        guard language != .none else { return }
        highlightTimer?.invalidate()
        highlightTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
            self?.highlight()
        }
    }

    func highlight() {
        guard language != .none else { return }
        let str = string
        guard !str.isEmpty else { return }
        let full = NSRange(location: 0, length: (str as NSString).length)
        let rules = SyntaxLanguage.rules(for: language, isDark: isDark)

        beginEditing()
        // Reset: base font + foreground
        addAttributes([.font: baseFont, .foregroundColor: baseFG], range: full)
        // Apply token colors in order (later rules win)
        for rule in rules {
            rule.regex.enumerateMatches(in: str, options: [], range: full) { match, _, _ in
                guard let match = match else { return }
                let r = (rule.group > 0 && rule.group < match.numberOfRanges)
                    ? match.range(at: rule.group) : match.range
                guard r.location != NSNotFound else { return }
                addAttribute(.foregroundColor, value: rule.color, range: r)
            }
        }
        endEditing()
    }
}
```

### Step 4: Build

```bash
bash build.sh
```
Expected: compiles + all tests pass. No behavioral change yet.

### Step 5: Commit

```bash
git add quickTerminal.swift
git commit -m "feat: SyntaxTextStorage + SyntaxRule + per-language color rules"
```

---

## Task 3: Wire `SyntaxTextStorage` into `EditorView`

**Files:**
- Modify: `quickTerminal.swift` — `EditorView` class (lines ~14484–14575)

### Step 1: Add `syntaxStorage` property to `EditorView`

Find the `EditorView` class definition (~line 14484). Add one property after `private var modeBarLabel: NSTextField!`:

```swift
private var syntaxStorage: SyntaxTextStorage?
```

### Step 2: Replace textView init in `EditorView.setup()`

Find this block in `EditorView.setup()` (around line 14515):

```swift
let contentSize = scrollView.contentSize
textView = EditorTextView(frame: NSRect(origin: .zero, size: contentSize))
textView.minSize = NSSize(width: 0, height: contentSize.height)
textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                          height: CGFloat.greatestFiniteMagnitude)
textView.isVerticallyResizable = true
textView.isHorizontallyResizable = false
textView.autoresizingMask = [.width]
textView.textContainer?.containerSize = NSSize(width: contentSize.width,
                                               height: CGFloat.greatestFiniteMagnitude)
textView.textContainer?.widthTracksTextView = true
```

Replace with:

```swift
let contentSize = scrollView.contentSize
// Build custom text-storage stack so SyntaxTextStorage can highlight live
let storage = SyntaxTextStorage()
syntaxStorage = storage
let layoutMgr = NSLayoutManager()
storage.addLayoutManager(layoutMgr)
let tw = max(contentSize.width, 100)
let th = max(contentSize.height, 100)
let container = NSTextContainer(size: NSSize(width: tw, height: .greatestFiniteMagnitude))
container.widthTracksTextView = true
layoutMgr.addTextContainer(container)
textView = EditorTextView(frame: NSRect(origin: .zero, size: NSSize(width: tw, height: th)),
                          textContainer: container)
textView.minSize = NSSize(width: 0, height: contentSize.height)
textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                          height: CGFloat.greatestFiniteMagnitude)
textView.isVerticallyResizable = true
textView.isHorizontallyResizable = false
textView.autoresizingMask = [.width]
```

**Note:** `textContainer?.containerSize` and `widthTracksTextView` lines are removed — they are now set on the container directly above.

### Step 3: Sync `baseFG` + `isDark` in `applyColors(bg:fg:)`

Find `EditorView.applyColors(bg:fg:)` (~line 14565). Add two lines before the closing brace:

```swift
syntaxStorage?.baseFG = fg
syntaxStorage?.isDark = bg.brightnessComponent < 0.5
```

### Step 4: Add `setLanguage` and `setHighlightDark` methods to `EditorView`

Add after `applyColors(bg:fg:)`:

```swift
func setLanguage(_ lang: SyntaxLanguage) {
    syntaxStorage?.language = lang
    // language didSet triggers highlight() automatically
}

func setHighlightDark(_ dark: Bool) {
    syntaxStorage?.isDark = dark
    // isDark didSet triggers highlight() automatically
}
```

### Step 5: Build

```bash
bash build.sh
```
Expected: compiles. The text editor still works. Highlighting is wired but never triggered yet (no language set at load points).

### Step 6: Commit

```bash
git add quickTerminal.swift
git commit -m "feat: wire SyntaxTextStorage into EditorView"
```

---

## Task 4: Trigger highlighting at all load points

**Files:**
- Modify: `quickTerminal.swift` — `applyTheme()`, `openEditorFile()`, `restoreSession()`

### Step 1: Update `applyTheme()` to sync highlight theme

Find `applyTheme()` at line 1074. Find this block (~line 1097):

```swift
// Sync editor views to new theme
if let delegate = NSApp.delegate as? AppDelegate {
    for ev in delegate.tabEditorViews.compactMap({ $0 }) {
        ev.applyColors(bg: NSColor(cgColor: kTermBgCGColor) ?? kDefaultBG, fg: kDefaultFG)
    }
}
```

Replace with:

```swift
// Sync editor views to new theme
if let delegate = NSApp.delegate as? AppDelegate {
    let dark = t.id != "light"
    for ev in delegate.tabEditorViews.compactMap({ $0 }) {
        ev.applyColors(bg: NSColor(cgColor: kTermBgCGColor) ?? kDefaultBG, fg: kDefaultFG)
        ev.setHighlightDark(dark)
    }
}
```

### Step 2: Call `setLanguage` in `openEditorFile()`

Find `openEditorFile()` (~line 15363). After `ev.textView.string = content`, add:

```swift
ev.setLanguage(SyntaxLanguage.detect(from: url))
```

The relevant block will look like:

```swift
guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
ev.textView.string = content
ev.setLanguage(SyntaxLanguage.detect(from: url))   // ← add this line
if capturedTab < self.tabEditorURLs.count {
```

### Step 3: Call `setLanguage` in `restoreSession()`

Find `restoreSession()` (~line 18127). Find this block:

```swift
if let content = try? String(contentsOf: url, encoding: .utf8),
   tabIdx < tabEditorViews.count, let ev = tabEditorViews[tabIdx] {
    ev.textView.string = content
    tabEditorURLs[tabIdx] = url
    tabCustomNames[tabIdx] = url.lastPathComponent
}
```

Add one line after `ev.textView.string = content`:

```swift
ev.setLanguage(SyntaxLanguage.detect(from: url))
```

### Step 4: Build + smoke test

```bash
bash build.sh
```
Open the app. Open a `.json` file in an editor tab. Verify tokens are colored. Switch theme → colors update. Reopen app → highlighting restored.

### Step 5: Commit

```bash
git add quickTerminal.swift
git commit -m "feat: trigger syntax highlighting on file open, theme change, and session restore"
```

---

## Task 5: File drop onto tab header (`HeaderBarView`)

**Files:**
- Modify: `quickTerminal.swift` — `HeaderBarView` class (~line 5478) and AppDelegate setup (~line 15096)

### Step 1: Add properties to `HeaderBarView`

Find the properties block in `HeaderBarView` (~line 5528). Add after `var onFileSaveAs: (() -> Void)?`:

```swift
var onFileDropped: ((URL) -> Void)?
private var dropHighlight = false
private let dropOverlay: NSView = {
    let v = NSView()
    v.wantsLayer = true
    v.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.18).cgColor
    v.autoresizingMask = [.width, .height]
    v.isHidden = true
    return v
}()
```

### Step 2: Register for dragged types + add overlay in `HeaderBarView.init`

Find the end of `HeaderBarView.init(frame:)`, just before `NotificationCenter.default.addObserver(...)` (~line 5669). Insert:

```swift
// File drop support
registerForDraggedTypes([.fileURL])
dropOverlay.frame = bounds
addSubview(dropOverlay)
```

### Step 3: Add `NSDraggingDestination` methods

Add these methods to `HeaderBarView`, after `deinit` (~line 5675):

```swift
// ── File Drop ───────────────────────────────────────────────────────────────

override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    guard sender.draggingPasteboard.canReadObject(
        forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) else { return [] }
    // Ignore if this is an internal tab-reorder drag (source is self)
    guard !(sender.draggingSource is NSView && isDescendant(of: sender.draggingSource as! NSView)) else {
        return []
    }
    dropHighlight = true
    dropOverlay.isHidden = false
    return .copy
}

override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }

override func draggingExited(_ sender: NSDraggingInfo?) {
    dropHighlight = false
    dropOverlay.isHidden = true
}

override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    dropHighlight = false
    dropOverlay.isHidden = true
    guard let urls = sender.draggingPasteboard.readObjects(
        forClasses: [NSURL.self],
        options: [.urlReadingFileURLsOnly: true]) as? [URL],
          let url = urls.first else { return false }
    // Reject directories
    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
          !isDir.boolValue else { return false }
    onFileDropped?(url)
    return true
}
```

### Step 4: Wire `onFileDropped` in AppDelegate

Find the block of `headerView.on*` assignments (~line 15094):

```swift
headerView.onFileOpen   = { [weak self] in self?.openEditorFile() }
headerView.onFileSave   = { [weak self] in self?.saveCurrentEditor() }
headerView.onFileSaveAs = { [weak self] in self?.saveCurrentEditorAs() }
```

Add directly after:

```swift
headerView.onFileDropped = { [weak self] url in
    self?.createEditorTab(url: url)
}
```

### Step 5: Add `createEditorTab(url:)` overload to AppDelegate

Find `@objc func createEditorTab()` (~line 15417). Replace with:

```swift
@objc func createEditorTab() { createEditorTab(url: nil) }

func createEditorTab(url: URL?) {
    let tf = termFrame()

    let editorView = EditorView(frame: tf)
    editorView.autoresizingMask = [.width, .height]
    editorView.applyColors(bg: NSColor(cgColor: kTermBgCGColor) ?? kDefaultBG, fg: kDefaultFG)
```

Then find where `tabEditorURLs.append(nil)` is (~line 15447) and replace with:

```swift
tabEditorURLs.append(url)
```

Then after the `tabCustomNames.append(Loc.editorTabName)` line, add:

```swift
// If a URL was provided, load content + set language + tab name
if let url = url,
   let content = try? String(contentsOf: url, encoding: .utf8) {
    editorView.textView.string = content
    editorView.setLanguage(SyntaxLanguage.detect(from: url))
    tabCustomNames[tabCustomNames.count - 1] = url.lastPathComponent
    tabEditorDirty[tabEditorDirty.count - 1] = false
}
```

The closing `}` of the original `createEditorTab()` becomes the closing `}` of the new `createEditorTab(url:)`.

### Step 6: Build + smoke test

```bash
bash build.sh
```

Drag a `.json` file from Finder onto the tab header bar. Verify:
- Blue overlay appears during hover
- New editor tab opens with file content
- Syntax highlighting is active

### Step 7: Commit

```bash
git add quickTerminal.swift
git commit -m "feat: drag file onto tab header to open in editor + createEditorTab(url:)"
```

---

## Task 6: CHANGELOG + docs update

**Files:**
- Modify: `CHANGELOG.md`

### Step 1: Update CHANGELOG

In the v1.5.0 entry (or create v1.5.1 if version was bumped), verify these entries exist/update them:

```markdown
- **Syntax Highlighting** — Live token coloring auto-detected from file extension:
  JSON, HTML, CSS, JavaScript/TypeScript. Regex-based, debounced at 150ms.
  Colors adapt to dark/light theme.
- **File Drop on Tab Header** — Drag any text file from Finder onto the tab bar
  to open it in a new editor tab with syntax highlighting applied automatically.
```

### Step 2: Build final

```bash
bash build.sh
```

### Step 3: Commit

```bash
git add CHANGELOG.md
git commit -m "docs: update CHANGELOG for syntax highlighting and file drop features"
```

---

## Summary of Changes

| File | What changes |
|---|---|
| `tests.swift` | +`SyntaxLanguage_Test` stub, +`testSyntaxLanguageDetection()` |
| `quickTerminal.swift` | +`SyntaxLanguage` enum, +`SyntaxRule`, +`SyntaxTextStorage`, modified `EditorView.setup()`, +`EditorView.setLanguage/setHighlightDark`, modified `applyTheme()`, `openEditorFile()`, `restoreSession()`, +`HeaderBarView.onFileDropped/dragging*`, +`createEditorTab(url:)` |
| `CHANGELOG.md` | Document new features |

**Total estimated additions:** ~250 lines of Swift.
