# Editor Modes Design

**Date:** 2026-03-16
**Status:** Approved

## Goal

Add three editor input modes (Normal / Nano / Vim) selectable via footer buttons, plus file operation buttons (Open / Save / Save As) in the header — all only visible when an editor tab is active.

## Features

### Footer: Mode Buttons (left side, editor tab only)
Three buttons left of the AI usage badge: `NORMAL` · `NANO` · `VIM`. Active mode button is highlighted. Hidden for terminal tabs.

### Header: File Operation Buttons (right side, editor tab only)
Three small buttons to the left of `+`: `Open` · `Save` · `Save As`. Hidden for terminal tabs.
- **Open** (`⌘O`): NSOpenPanel → load file into current editor tab
- **Save** (`⌘S`): write to current URL; if no URL → Save As
- **Save As** (`⌘⇧S`): NSSavePanel → write and set new URL

### NORMAL Mode
Current plain NSTextView behavior — no changes.

### NANO Mode
NSTextView stays First Responder. Key intercepts via `BorderlessWindow.sendEvent`:
- `Ctrl+S` → save
- `Ctrl+X` → close tab
- `Ctrl+K` → cut current line
- `Ctrl+U` → paste
- `Ctrl+W` → find (future)

A shortcut bar appears at the bottom of EditorView showing: `^S Save  ^X Close  ^K Cut Line  ^U Paste`

### VIM Mode (Minimal)
Modal editor implemented via `BorderlessWindow.sendEvent` key intercepts.

**Sub-modes:** `VimSubMode` enum: `.normal` / `.insert`

**Normal mode keys:**
- `h/j/k/l` → left/down/up/right
- `i` → insert before cursor
- `a` → insert after cursor
- `o` → new line below, insert
- `dd` → delete current line
- `yy` → yank (copy) current line
- `p` → paste yanked line below
- `0` → beginning of line
- `$` → end of line
- `:w` → save, `:q` → close tab, `:wq` → save + close
- `Esc` → stays in normal mode (noop)

**Insert mode:** regular NSTextView editing. `Esc` → back to Normal mode.

A status indicator `── NORMAL ──` / `── INSERT ──` appears at bottom of EditorView.

## Architecture

### New Types
```swift
enum EditorInputMode { case normal, nano, vim }
enum VimSubMode      { case normal, insert }
```

### EditorView Changes
- `var inputMode: EditorInputMode = .normal`
- `var vimMode: VimSubMode = .normal`
- `var vimYankBuffer: String = ""`
- `var vimPendingColon: Bool = false`  (for :w/:q/:wq)
- `private var modeBar: NSView` — bottom strip inside EditorView (nano shortcuts or vim mode indicator)
- `func setInputMode(_ mode: EditorInputMode)` — shows/hides modeBar
- `func setVimMode(_ mode: VimSubMode)` — updates modeBar label, enables/disables NSTextView editing

### AppDelegate Changes
- `var tabEditorModes: [EditorInputMode]` — parallel array, `.normal` for all new tabs
- `var tabEditorURLs: [URL?]` — track open file URL per editor tab
- `var tabEditorDirty: [Bool]` — unsaved changes flag
- `func openEditorFile()` — NSOpenPanel
- `func saveCurrentEditor()` — write to URL or trigger Save As
- `func saveCurrentEditorAs()` — NSSavePanel

### FooterBarView Changes
- `private var editorModeButtons: [ShellButton]` — 3 buttons: NORMAL/NANO/VIM
- Added to `linksContent` left of shell buttons
- `setEditorMode(_ isEditor: Bool)` already hides shell buttons; also shows/hides `editorModeButtons`
- `var onEditorModeChange: ((EditorInputMode) -> Void)?`

### HeaderBarView Changes
- `private var fileOpenBtn: HoverButton`
- `private var fileSaveBtn: HoverButton`
- `private var fileSaveAsBtn: HoverButton`
- Added before `+` button with constraints; hidden by default
- `func setEditorFileButtonsVisible(_ visible: Bool)`
- Callbacks: `var onFileOpen`, `var onFileSave`, `var onFileSaveAs`

### Key Intercept (BorderlessWindow.sendEvent)
When editor tab is active:
- **Nano mode**: intercept `.keyDown` with `.control` flag → Ctrl+S/X/K/U
- **Vim normal mode**: intercept all `.keyDown` → route to `EditorView.handleVimNormalKey(_:)`
- **Vim insert mode**: only intercept `Esc` → switch to normal mode

## Out of Scope (v1)
- Vim Visual mode
- Vim count prefix (3dd)
- Nano search (Ctrl+W)
- Syntax highlighting per mode
- Persistent mode per tab across sessions
