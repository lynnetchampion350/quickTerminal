# Print Modal — Design Doc
**Datum:** 2026-03-18
**Feature:** Drucker-Icon im Footer + Custom Print-Modal

---

## Ziel

Ein Drucker-Button im Footer öffnet ein custom dunkles Modal (Approach A, Quick-Action Modal). Der User wählt WAS gedruckt wird, danach öffnet der native macOS-Druckdialog für Papierformat/Ränder.

---

## Footer-Button

- **Widget:** `SymbolHoverButton` mit SF Symbol `"printer"`, Größe 24×24pt
- **Position:** `rechtsContent`, direkt **vor** dem Gear-Button
- **Sichtbarkeit:** Immer sichtbar (alle Tab-Typen: Terminal + Editor)
- **Callback:** `onPrint: (() -> Void)?` in `FooterBarView`
- **Layout-Änderung:** Im `layout()` Override vor `gearBtn` positionieren

Footer-Reihenfolge rechts:
```
[ ^< ] [ ⌥⇥ ] [ ⌘T ] [ ⌘E ] [ ⌘W ] [ ⌘D ] [ ⌘⇧D ]  [ 🖨 ] [ ⚙ ] [ ✕ ]
```

---

## Print Modal (`PrintModal: NSView`)

### Visuelles Design
- Vollflächen-Backdrop: `NSColor.black.withAlphaComponent(0.55)` — blockiert Klicks (wie `EditorAlertOverlay`)
- Zentriertes Panel: 320pt breit, variable Höhe je nach Anzahl Buttons
- Panel-Style: `background #14141a`, `cornerRadius 10`, `border white/9%`, Shadow
- Oben: SF Symbol `"printer"` (20pt, weiß/70%) + Titel `"Drucken"`
- Buttons: Große Aktions-Buttons (volle Breite, 36pt Höhe), Dark-Style mit Hover
- Unten: `"Abbrechen"` Link-Button

### Modal-Inhalt je Tab-Typ

| Tab-Typ | Button(s) |
|---|---|
| **Terminal** | `"Terminal drucken"` |
| **Markdown** (`.md`, `.markdown`, …) | `"Formatiert drucken"` + `"Quellcode drucken"` |
| **HTML** (`.html`, `.htm`) | `"Vorschau drucken"` + `"Quellcode drucken"` |
| **SVG** (`.svg`) | `"SVG-Grafik drucken"` + `"Quellcode drucken"` |
| **CSV** (`.csv`) | `"Als Tabelle drucken"` + `"Quellcode drucken"` |
| **Andere Editoren** | `"Quellcode drucken"` |

---

## Print-Implementierung

### Gerendert drucken (Markdown / HTML / SVG / CSV / Terminal)
1. Bestehende `markdownToHTML` / `svgToHTML` / `csvToHTML` Konverter wiederverwenden
2. Für Terminal: scrollback + sichtbaren Buffer als HTML aufbauen (Monospace, dunkler BG)
3. Temporäre `WKWebView` off-screen erstellen (Fenstergröße)
4. HTML laden via `loadHTMLString(_:baseURL:)`
5. Nach `webView(_:didFinish:)` Navigation-Delegate Callback: `wkWebView.printOperation(with: NSPrintInfo.shared).runModal(for: window)`

### Quellcode drucken (alle Editor-Typen)
- `ev.textView.printOperation(with: NSPrintInfo.shared).runModal(for: window)`
- Behält Syntax-Highlighting (NSAttributedString) + Monospace-Font

---

## Neue Komponenten

| Komponente | Beschreibung |
|---|---|
| `class PrintModal: NSView` | Backdrop + Panel, analog zu `EditorAlertOverlay`. Factory-Methode `PrintModal.show(options:onSelect:onCancel:)` |
| `struct PrintOption` | `label: String`, `action: PrintAction` |
| `enum PrintAction` | `.renderedHTML(String, URL?)`, `.sourceCode`, `.terminal` |
| `func printCurrentTab()` in AppDelegate | Erkennt Tab-Typ, baut Optionen, zeigt Modal |
| `func executePrintAction(_ action: PrintAction)` | Führt gewählte Aktion aus (WKWebView oder textView) |
| `var onPrint: (() -> Void)?` in FooterBarView | Callback zum AppDelegate |

---

## Ablauf (Sequenz)

```
User klickt 🖨
  → footerView.onPrint?()
  → AppDelegate.printCurrentTab()
      → erkennt Tab-Typ (terminal/editor + Dateiendung)
      → baut [PrintOption] Array
      → PrintModal.show(options:onSelect:onCancel:)
          → User wählt Option
          → onSelect(PrintAction)
          → AppDelegate.executePrintAction(_:)
              → .renderedHTML: WKWebView laden → runModal
              → .sourceCode:  textView.printOperation → runModal
              → .terminal:    Buffer→HTML → WKWebView → runModal
```

---

## Out of Scope
- Print-Margins/Farben konfigurieren (das macht der native macOS-Druckdialog)
- Mehrere Tabs gleichzeitig drucken
- PDF-Export (separates Feature)
