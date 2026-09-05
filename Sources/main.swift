import AppKit

final class StatusBarView: NSView {
    override func draw(_ r: NSRect) {
        NSColor.windowBackgroundColor.setFill(); bounds.fill()
        NSColor.separatorColor.setFill()
        NSRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1).fill()
    }
}

// MARK: - Per-window editor (in the responder chain via NSWindowController,
// so menu actions always hit the key window's document)
final class Editor: NSWindowController, NSTextViewDelegate, NSWindowDelegate {
    var textView: NSTextView!
    var scroll: NSScrollView!
    var statusLabel: NSTextField!
    var statusBar: NSView!
    var fileURL: URL?
    var isDirty = false { didSet { updateTitle() } }
    var fontSize: CGFloat = 14
    var wrapOn = true

    init() {
        let frame = NSRect(x: 0, y: 0, width: 820, height: 620)
        let w = NSWindow(contentRect: frame, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init(window: w)
        w.delegate = self
        w.title = "Untitled - Notepad"

        scroll = NSScrollView(frame: .zero)
        scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = false
        scroll.autoresizingMask = [.width, .height]
        scroll.translatesAutoresizingMaskIntoConstraints = false

        textView = NSTextView(frame: .zero)
        textView.delegate = self
        textView.isRichText = false; textView.usesFontPanel = true; textView.usesFindBar = true
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.allowsUndo = true
        scroll.documentView = textView

        statusBar = StatusBarView(); statusBar.translatesAutoresizingMaskIntoConstraints = false
        statusLabel = NSTextField(labelWithString: "Ln 1, Col 1  |  0 chars  |  UTF-8  |  LF")
        statusLabel.font = .systemFont(ofSize: 11); statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusBar.addSubview(statusLabel)

        let content = w.contentView!
        content.addSubview(scroll); content.addSubview(statusBar)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: content.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: statusBar.topAnchor),
            statusBar.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            statusBar.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            statusBar.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: statusBar.trailingAnchor, constant: -10),
            statusLabel.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor)
        ])
        applyWrap()
        if let prev = AppDelegate.editors.last?.window {
            var p = prev.frame.origin; p.x += 28; p.y -= 28; w.setFrameOrigin(p)
        } else {
            w.center()
        }
        w.makeKeyAndOrderFront(nil)
        updateTitle(); updateStatus()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Wrap
    func applyWrap() {
        if wrapOn {
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSSize(width: scroll.contentSize.width, height: .greatestFiniteMagnitude)
            scroll.hasHorizontalScroller = false
        } else {
            textView.textContainer?.widthTracksTextView = false
            textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            scroll.hasHorizontalScroller = true
        }
    }

    // MARK: - Title / status
    func updateTitle() {
        let name = fileURL?.lastPathComponent ?? "Untitled"
        window?.title = (isDirty ? "*" : "") + name + " - Notepad"
        window?.isDocumentEdited = isDirty
    }
    func updateStatus() {
        let s = textView.string as NSString
        let sel = textView.selectedRange()
        let upTo = s.substring(to: min(sel.location, s.length))
        let lines = upTo.components(separatedBy: "\n")
        let ln = lines.count, col = (lines.last?.count ?? 0) + 1
        statusLabel.stringValue = "Ln \(ln), Col \(col)  |  \(s.length) chars  |  UTF-8  |  LF"
    }
    func textDidChange(_ n: Notification) { isDirty = true; updateStatus() }

    // MARK: - File ops
    @objc func newDoc(_ s: Any?) {
        if !confirmDiscard() { return }
        textView.string = ""; fileURL = nil; isDirty = false; updateTitle(); updateStatus()
    }
    @objc func openDoc(_ s: Any?) {
        let p = NSOpenPanel(); p.allowedFileTypes = ["txt", "text", "md", "log"]; p.allowsMultipleSelection = false
        if p.runModal() == .OK, let u = p.url { open(url: u) }
    }
    func open(url u: URL) {
        if !confirmDiscard() { return }
        if let t = try? String(contentsOf: u, encoding: .utf8) {
            textView.string = t; fileURL = u; isDirty = false; updateTitle(); updateStatus()
            NSDocumentController.shared.noteNewRecentDocumentURL(u)
        }
    }
    @objc func saveDoc(_ s: Any?) { fileURL == nil ? saveAs(s) : write(to: fileURL!) }
    @objc func saveAs(_ s: Any?) {
        let p = NSSavePanel(); p.allowedFileTypes = ["txt"]; p.nameFieldStringValue = fileURL?.lastPathComponent ?? "Untitled.txt"
        if p.runModal() == .OK, let u = p.url { write(to: u); fileURL = u; updateTitle() }
    }
    func write(to u: URL) {
        do {
            try textView.string.write(to: u, atomically: true, encoding: .utf8); isDirty = false
            NSDocumentController.shared.noteNewRecentDocumentURL(u)
        } catch {
            let a = NSAlert(); a.messageText = "Could not save"; a.informativeText = error.localizedDescription; a.runModal()
        }
    }
    @objc func printDoc(_ s: Any?) {
        let op = NSPrintOperation(view: textView)
        op.run()
    }
    func confirmDiscard() -> Bool {
        if !isDirty { return true }
        let a = NSAlert(); a.messageText = "Discard changes?"; a.addButton(withTitle: "Discard"); a.addButton(withTitle: "Cancel")
        return a.runModal() == .alertFirstButtonReturn
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool { confirmDiscard() }
    func windowWillClose(_ n: Notification) {
        AppDelegate.editors.removeAll { $0 === self }
    }

    // MARK: - Edit extras
    @objc func stampTime(_ s: Any?) {
        let f = DateFormatter(); f.dateFormat = "h:mm a M/d/yyyy"
        textView.insertText(f.string(from: Date()), replacementRange: textView.selectedRange())
    }
    func finderAction(_ a: NSTextFinder.Action) {
        window?.makeFirstResponder(textView)
        let stub = NSMenuItem(); stub.tag = a.rawValue
        textView.performTextFinderAction(stub)
    }
    @objc func findShow(_ s: Any?) { finderAction(.showFindInterface) }
    @objc func findNext(_ s: Any?) { finderAction(.nextMatch) }
    @objc func findPrev(_ s: Any?) { finderAction(.previousMatch) }
    @objc func replaceShow(_ s: Any?) { finderAction(.showReplaceInterface) }
    @objc func goToLine(_ s: Any?) {
        let a = NSAlert(); a.messageText = "Go to Line"
        let f = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        f.placeholderString = "Line number"; a.accessoryView = f
        a.addButton(withTitle: "Go"); a.addButton(withTitle: "Cancel")
        guard a.runModal() == .alertFirstButtonReturn,
              let n = Int(f.stringValue.trimmingCharacters(in: .whitespaces)), n >= 1 else { return }
        let str = textView.string as NSString
        let total = str.components(separatedBy: "\n").count
        let target = min(n, max(total, 1))
        var idx = 0, cur = 1
        while cur < target, idx < str.length {
            let r = str.range(of: "\n", range: NSRange(location: idx, length: str.length - idx))
            if r.location == NSNotFound { break }
            idx = r.location + 1; cur += 1
        }
        let rest = str.range(of: "\n", range: NSRange(location: idx, length: str.length - idx))
        let end = (rest.location == NSNotFound) ? str.length : rest.location
        textView.setSelectedRange(NSRange(location: idx, length: end - idx))
        textView.scrollRangeToVisible(NSRange(location: idx, length: 0))
        window?.makeFirstResponder(textView)
        updateStatus()
    }
    @objc func toggleWrap(_ s: Any?) { wrapOn.toggle(); applyWrap(); if let i = s as? NSMenuItem { i.state = wrapOn ? .on : .off } }
    @objc func toggleStatus(_ s: Any?) { statusBar.isHidden.toggle(); if let i = s as? NSMenuItem { i.state = statusBar.isHidden ? .off : .on } }
    @objc func zoomIn(_ s: Any?) { fontSize += 1; textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular) }
    @objc func zoomOut(_ s: Any?) { fontSize = max(8, fontSize - 1); textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular) }
    @objc func zoomReset(_ s: Any?) { fontSize = 14; textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular) }
}

// MARK: - App level: menu, About, new window, recents
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    static var editors: [Editor] = []
    var recentMenu: NSMenu!

    func applicationDidFinishLaunching(_ n: Notification) {
        buildMenu()
        AppDelegate.newEditor()
    }

    static func newEditor() {
        let e = Editor()
        editors.append(e)
    }

    @objc func newWindowDoc(_ s: Any?) { AppDelegate.newEditor() }

    func keyEditor() -> Editor? {
        if let w = NSApp.keyWindow { return AppDelegate.editors.first { $0.window === w } }
        return AppDelegate.editors.first
    }

    @objc func openRecent(_ s: Any?) {
        guard let i = s as? NSMenuItem, let u = i.representedObject as? URL else { return }
        keyEditor()?.open(url: u)
    }
    @objc func clearRecent(_ s: Any?) { NSDocumentController.shared.clearRecentDocuments(nil) }

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu == recentMenu else { return }
        menu.removeAllItems()
        let urls = NSDocumentController.shared.recentDocumentURLs.filter { FileManager.default.fileExists(atPath: $0.path) }
        if urls.isEmpty {
            let i = NSMenuItem(title: "No Recent Files", action: nil, keyEquivalent: ""); i.isEnabled = false; menu.addItem(i)
        } else {
            for u in urls.prefix(10) {
                let i = NSMenuItem(title: u.lastPathComponent, action: #selector(openRecent(_:)), keyEquivalent: "")
                i.target = self; i.representedObject = u; menu.addItem(i)
            }
            menu.addItem(.separator())
            let c = NSMenuItem(title: "Clear Menu", action: #selector(clearRecent(_:)), keyEquivalent: ""); c.target = self; menu.addItem(c)
        }
    }

    // MARK: - Menu (Notepad feel, Mac keys)
    func buildMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem(); main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Notepad", action: #selector(showAbout(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Notepad", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        func menu(_ title: String, items: [(String, Selector?, String, NSEvent.ModifierFlags)]) -> NSMenuItem {
            let m = NSMenuItem(); m.submenu = NSMenu(title: title)
            for (t, sel, key, mods) in items {
                if t == "-" { m.submenu!.addItem(.separator()); continue }
                let i = NSMenuItem(title: t, action: sel, keyEquivalent: key)
                if mods != .command { i.keyEquivalentModifierMask = mods }
                if t == "Word Wrap" || t == "Status Bar" { i.state = .on }
                m.submenu!.addItem(i)
            }
            main.addItem(m); return m
        }
        let C: NSEvent.ModifierFlags = .command
        let fileItem = menu("File", items: [
            ("New", #selector(Editor.newDoc(_:)), "n", C),
            ("New Window", #selector(newWindowDoc(_:)), "N", C),
            ("Open…", #selector(Editor.openDoc(_:)), "o", C),
            ("Save", #selector(Editor.saveDoc(_:)), "s", C),
            ("Save As…", #selector(Editor.saveAs(_:)), "S", C),
            ("-", nil, "", C),
            ("Print…", #selector(Editor.printDoc(_:)), "p", C),
        ])
        recentMenu = NSMenu(title: "Open Recent"); recentMenu.delegate = self
        let ri = NSMenuItem(title: "Open Recent", action: nil, keyEquivalent: ""); ri.submenu = recentMenu
        fileItem.submenu!.insertItem(ri, at: 3)
        let editItem = menu("Edit", items: [
            ("Undo", Selector(("undo:")), "z", C),
            ("Redo", Selector(("redo:")), "Z", C),
            ("-", nil, "", C),
            ("Cut", Selector(("cut:")), "x", C),
            ("Copy", Selector(("copy:")), "c", C),
            ("Paste", Selector(("paste:")), "v", C),
            ("Select All", Selector(("selectAll:")), "a", C),
            ("-", nil, "", C),
            ("Find…", #selector(Editor.findShow(_:)), "f", C),
            ("Find Next", #selector(Editor.findNext(_:)), "g", C),
            ("Find Previous", #selector(Editor.findPrev(_:)), "G", C),
            ("Replace…", #selector(Editor.replaceShow(_:)), "f", [.command, .option]),
            ("Go to Line…", #selector(Editor.goToLine(_:)), "", C),
            ("-", nil, "", C),
            ("Time/Date", #selector(Editor.stampTime(_:)), "", C),
        ])
        let fontItem = NSMenuItem(title: "Font…", action: Selector(("orderFrontFontPanel:")), keyEquivalent: "")
        fontItem.target = NSFontManager.shared
        editItem.submenu!.insertItem(fontItem, at: 14)
        _ = menu("Format", items: [("Word Wrap", #selector(Editor.toggleWrap(_:)), "", C)])
        _ = menu("View", items: [
            ("Status Bar", #selector(Editor.toggleStatus(_:)), "", C),
            ("-", nil, "", C),
            ("Zoom In", #selector(Editor.zoomIn(_:)), "+", C),
            ("Zoom Out", #selector(Editor.zoomOut(_:)), "-", C),
            ("Reset Zoom", #selector(Editor.zoomReset(_:)), "0", C),
        ])
        NSApp.mainMenu = main
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    @objc func showAbout(_ s: Any?) {
        let a = NSAlert()
        a.icon = NSApp.applicationIconImage
        a.messageText = "Notepad for Mac"
        a.informativeText = "Version 1.0\n\nBy No Ads Studio by TheOneKiK.\nZero ads. Zero tracking. Zero telemetry. Offline-only."
        a.addButton(withTitle: "OK")
        a.runModal()
    }
}

let app = NSApplication.shared
let del = AppDelegate()
app.delegate = del
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
