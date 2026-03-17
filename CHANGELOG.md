# Changelog

All notable changes to quickTERMINAL are documented here.

---

## v1.5.0 — 2026-03-16

### New Features
- **Text Editor Tab** — Open a full text editor tab alongside terminal tabs. Click `+` → "Text Editor" or press `⌘E`. Supports open (`⌘O`), save (`⌘S`), and save-as (`⌘⇧S`) with native sheet panels.
- **Syntax Highlighting** — Live token coloring auto-detected from file extension:
  JSON, HTML/HTM, CSS, JavaScript/TypeScript (JS/MJS/CJS/TS/TSX/JSX).
  Regex-based engine, debounced at 150ms. Colors adapt to dark/light theme automatically.
- **File Drop on Tab Header** — Drag any text file from Finder onto the tab bar
  to open it in a new editor tab with syntax highlighting applied automatically.
- **Editor Modes** — Three input modes selectable via footer buttons: `NORMAL` (plain NSTextView), `NANO` (`Ctrl+S/X/K/U` shortcuts), `VIM` (modal hjkl/insert/dd/yy/p/:/wq).
- **Vim Mode** — Minimal modal editing: hjkl + arrow key navigation, `i/a/o` insert, `dd` delete line, `yy` yank, `p` paste, `0/$` line start/end, `:w/:q/:wq` file operations. Status bar shows `── NORMAL ──` / `── INSERT ──`.
- **Nano Mode** — Shortcut bar with `^S Save  ^X Close  ^K Cut Line  ^U Paste`. Keys intercepted at window level.
- **Session Persistence** — Editor tabs (including open file URL and editor mode) are saved and restored across restarts.
- **Theme Sync** — Editor background and text color automatically follow the active color theme.

### Bug Fixes
- **Window positioning flash on launch** — Docked window now waits 200 ms for status-bar item coordinates to stabilize before calling `showWindowAnimated()`. Eliminates flash/jump since v1.3.
- **Multiple editor tabs background darkening** — Each new editor tab no longer composites on top of the previous one; views are properly hidden before the new one is shown.
- **File panels appearing behind window** — `NSOpenPanel` / `NSSavePanel` now use `beginSheetModal(for:)`, attaching them as sheets to the window instead of floating behind it.
- **Version button not clickable** — Tab content views are re-added below the version button in z-order after each tab creation.
- **Version button shows text cursor** — HoverButton now has `resetCursorRects`, `cursorUpdate`, and `.cursorUpdate` tracking area. TerminalView and EditorTextView both early-return when the cursor is over the version button.
- **`+` → Terminal opened editor** — Removed incorrect branch in `addTab()` that called `createEditorTab()` when the active tab was an editor.
- **Vim cursor invisible in normal mode** — `isEditable` stays `true` in all Vim sub-modes; key blocking is handled entirely by `BorderlessWindow.sendEvent`.
- **Vim normal mode typing** — All unrecognized keyDown events in normal mode are now consumed by `sendEvent` before reaching NSTextView.

---

## v1.4.0 — 2026-03-14

### New Features
- **SSH Manager** — Floating sidebar for SSH profile management. Save connections (label, user@host, port, identity file), connect via new tab with one click, delete profiles. Profiles stored in UserDefaults as JSON. `SSHProfile.connectCommand` builds the correct `ssh` invocation automatically.
- **Keyboard Shortcuts: Tab Navigation** — `Ctrl+1–9` to switch directly to any tab. `Ctrl+Shift+1–9` to trigger inline rename for that tab.
- **Keyboard Shortcuts: Window Presets** — `Ctrl+⌥+1` (compact 620×340), `Ctrl+⌥+2` (medium 860×480), `Ctrl+⌥+3` (large 1200×680) — animated spring resize.
- **Color Themes** — 4 terminal color schemes in Settings: Dark (default), Light, OLED Black, System (auto-follows macOS Dark/Light Mode). System theme observes `AppleInterfaceThemeChangedNotification` for live switching.
- **Follow All Spaces** — New setting: window appears on all macOS Spaces simultaneously. Toggle in Settings or via tray right-click menu.
- **Tray Detach / Reattach** — Right-click tray icon → "Detach Window" floats the terminal freely on the desktop. Detached window is fully resizable from all 8 edges/corners. "Reattach Window" snaps it back under the tray icon. State survives hide/show cycles.
- **Terminal Right-Click Context Menu** — Right-click: Copy, Paste, Select All (respects mouse-tracking mode; falls through to app when tracking is active).
- **Sidebar Right-Click** — Right-click on any header panel button (Git, WebPicker, SSH) to toggle that panel without opening quickBAR.
- **Full 10-Language Localization Update** — All new UI strings (`showHide`, `detachWindow`, `reattachWindow`, `quitApp`) added to all 10 language dictionaries: EN, DE, TR, ES, FR, IT, AR, JA, ZH, RU.

### Security
- **Updater: SHA256 integrity check** — Downloads a `.sha256` sidecar from GitHub Releases and verifies the ZIP before installation. Absent sidecar falls back gracefully without blocking the update.
- **Updater: HTTPS + host allowlist** — Both download and checksum URLs are enforced to use `https://` and restricted to `github.com` / `objects.githubusercontent.com`. Redirects to any other host are rejected.
- **Updater: Bundle ID verification** — Extracted `.app` must match the current app's `CFBundleIdentifier` before installation proceeds.

### Bug Fixes
- **Header gap when detached** — Floating window no longer shows a 4–5 px empty strip at the top. Arrow view is hidden and `headerView.frame` repositions flush to the window top edge.
- **Terminal area when detached** — `termFrame()` now uses `effectiveArrowH = 0` when detached, so the terminal expands to fill the recovered space.
- **Sidebar drag moved window** — `isMovableByWindowBackground` removed entirely; drag-to-move is now handled exclusively in `HeaderBarView.mouseDragged` and only activates when `isWindowDetached == true`.
- **Diagonal resize when detached** — `BorderlessWindow.edgeAt()` now exposes top-left and top-right corner resize zones when `isDetached == true`.
- **First-click on sidebar divider** — `GitPanelDividerView.acceptsFirstMouse` returns `true`, fixing the two-click interaction when the window is not yet frontmost.
- **Window position saved while detached** — `windowDidMove` / `windowDidResize` guard against `isWindowDetached` to prevent the desktop position from overwriting the tray-snap coordinates.
- **Reattach position** — `toggleDetach()` clears `windowX` / `windowY` from UserDefaults before reattaching, so `positionWindowUnderTrayIcon()` always recalculates from the current tray icon position.
- **Detach state not preserved on hide/show** — `toggleWindow()` now preserves the detached state; showing a hidden detached window no longer auto-reattaches it.
- **Updater: parse error vs. "up to date"** — HTTP errors, missing data, and JSON parse failures now return `.failure(error)` instead of silently reporting no update available.
- **Updater: background-thread install** — `installUpdate` runs on `DispatchQueue.global(qos: .utility)`, eliminating UI freeze during extraction and file operations.
- **Updater: relaunch exit guarded by open exit code** — `exit(0)` is only called when `/usr/bin/open` returns exit code 0. A failed relaunch no longer terminates the running process.
- **Updater: backup preserved until relaunch confirmed** — Old `.app` backup is deleted only after `open` succeeds, retaining rollback capability on relaunch failure.
- **Auto-Check Updates: toggle reschedules timer** — Enabling/disabling in Settings now immediately schedules or cancels the repeating timer.
- **Startup window fade** — `showWindowAnimated()` is now used on first launch, ensuring consistent fade-in and correct `hideOnClickOutside` monitor setup.

---

## v1.3.0 — 2026-03-12

### New Features
- **WebPicker** — Chrome DevTools Protocol (CDP) based DOM element picker. Connects to Chrome via WebSocket, lets you hover-select any element on any webpage, copies `outerHTML` to clipboard and auto-pastes into terminal. Floating sidebar with Connect/Disconnect toggle, live hostname display, and element preview.
- **Onboarding Video** — First-launch intro panel (480×300, centered). Plays `quickTERMINAL.mp4` once using AVKit, auto-closes when done, has "✕ Skip" button. Never shown again after first view (UserDefaults flag).
- **Full English UI** — All UI strings translated to English: Git panel, WebPicker, GitHub auth, feedback toasts, error messages, Claude API strings.
- **Demo GIF** — `quickTERMINAL.gif` added to README (MP4 → GIF, 700px, 2.4 MB, auto-plays on GitHub).

### Bug Fixes
- **WebSocket silent death** — `ChromeCDPClient.receiveLoop` now fires `onDisconnected` callback on `.failure`, preventing the UI from getting stuck in "connected" state when Chrome crashes or the tab is killed externally.
- **pollTimer not reset on reconnect** — `connect()` now invalidates `pollTimer` before starting a new session, preventing duplicate polling timers when the user reconnects without disconnecting first.
- **Tab closed externally** — `refreshTabTitle` returning `nil` (tab not found in Chrome's `/json/list`) now triggers a full `handleUnexpectedDisconnect(message: "Tab was closed")` instead of incorrectly showing "Navigating" state.
- **Stale onDisconnected closure** — `disconnect()` now sets `cdp.onDisconnected = nil` before closing, preventing a stale closure race where a final WebSocket `.failure` after manual disconnect could re-trigger disconnect logic.
- **Teardown duplication** — Disconnect/cleanup logic was duplicated in 3 places. Extracted into `handleUnexpectedDisconnect(message:)` with a `guard isConnected` gate to prevent double-firing.
- **titlePollTimer churn** — `startTitlePolling()` was being recreated on every HTTP callback. Extracted into a dedicated method called once after connect, preventing timer accumulation.
- **targetId extraction** — Replaced hand-rolled `wsURL.components(separatedBy: "/").last` with `URL(string: wsURL)?.lastPathComponent` for correct and reliable target ID extraction.

### Renames / Cleanup
- `HTMLPickerSidebarView` → `WebPickerSidebarView`
- `htmlPickerSidebarView` → `webPickerSidebarView` (AppDelegate)
- `onHTMLPickerToggle` → `onWebPickerToggle` (HeaderBarView)
- `setHTMLPickerActive` → `setWebPickerActive`
- `htmlPickerRightDivider` → `webPickerRightDivider`
- `toggleHTMLPicker` → `toggleWebPicker`
- `htmlPickerBrowser` → `webPickerBrowser` (UserDefaults key)
- `htmlBtn` → `webPickerBtn` (HeaderBarView)
- Removed dead `HTMLPickerPanel` class (282 lines)
- Removed all `print("[CDP]...")` debug statements

---

## v1.2.1 — 2026-03-11

### Bug Fixes
- **Auto-updater** — Clickable toast notification for update install. `.app` guard prevents update on non-bundled binary.

---

## v1.2.0 — 2026-03-10

### New Features
- **Git Panel** — 7 new features: branch display, changed files, diff viewer, staged changes, commit history, GitHub API CI status, panel position toggle (right/bottom).
- **Claude Code Usage Badge** — Live session & weekly limits in footer. Auto-connects via local credentials, color-coded, click for detail popover.
- **Drag & Drop** — Drop files/images from Finder → shell-escaped path inserted at cursor.
- **Custom Tab Names** — Double-click tab to rename; persists across sessions.

---

## v1.1.0 — 2026-03-08

### New Features
- Session restore — tabs, shells, splits, working directories.
- quickBAR — 40-command Spotlight-style palette.
- Multi-tab with color coding and drag-to-reorder.
- Split panes — vertical and horizontal with draggable divider.
- Auto-updater — GitHub Releases check every 72h.

---

## v1.0.0 — 2026-03-01

### Initial Release
- VT100/VT220/xterm terminal emulator from scratch (13-state FSM parser).
- 60 FPS CGContext rendering. 24-bit TrueColor. Sixel graphics.
- Menu bar app, global hotkey Ctrl+<.
- Single Swift file, zero dependencies, 4.8 MB app bundle.
