import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSTextViewDelegate, NSWindowDelegate {
    var window: NSWindow!
    var textView: NSTextView!
    var scroll: NSScrollView!
    var statusLabel: NSTextField!
    var statusBar: NSView!
    var fileURL: URL?
    var isDirty = false { didSet { updateTitle() } }
    var fontSize: CGFloat = 14
    var wrapOn = true

    func applicationDidFinishLaunching(_ n: Notification) {
        buildMenu()
        let frame = NSRect(x: 0, y: 0, width: 820, height: 620)
        window = NSWindow(contentRect: frame, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.center(); window.delegate = self
        window.title = "Untitled - Notepad"

        scroll = NSScrollView(frame: .zero)
        scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = false
        scroll.autoresizingMask = [.width, .height]
        scroll.translatesAutoresizingMaskIntoConstraints = false

        textView = NSTextView(frame: .zero)
        textView.delegate = self
        textView.isRichText = false; textView.usesFontPanel = false
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.allowsUndo = true
        scroll.documentView = textView

        statusBar = NSView(); statusBar.translatesAutoresizingMaskIntoConstraints = false
        statusBar.wantsLayer = true; statusBar.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        statusLabel = NSTextField(labelWithString: "Ln 1, Col 1  |  0 chars  |  UTF-8  |  LF")
        statusLabel.font = .systemFont(ofSize: 11); statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusBar.addSubview(statusLabel)

        let content = window.contentView!
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
        window.makeKeyAndOrderFront(nil)
        updateTitle(); updateStatus()
    }

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
        window.title = (isDirty ? "*" : "") + name + " - Notepad"
        window.isDocumentEdited = isDirty
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
        if !confirmDiscard() { return }
        let p = NSOpenPanel(); p.allowedFileTypes = ["txt", "text", "md", "log"]; p.allowsMultipleSelection = false
        if p.runModal() == .OK, let u = p.url, let t = try? String(contentsOf: u, encoding: .utf8) {
            textView.string = t; fileURL = u; isDirty = false; updateTitle(); updateStatus()
        }
    }
    @objc func saveDoc(_ s: Any?) { fileURL == nil ? saveAs(s) : write(to: fileURL!) }
    @objc func saveAs(_ s: Any?) {
        let p = NSSavePanel(); p.allowedFileTypes = ["txt"]; p.nameFieldStringValue = fileURL?.lastPathComponent ?? "Untitled.txt"
        if p.runModal() == .OK, let u = p.url { write(to: u); fileURL = u; updateTitle() }
    }
    func write(to u: URL) {
        do { try textView.string.write(to: u, atomically: true, encoding: .utf8); isDirty = false } catch {
            let a = NSAlert(); a.messageText = "Could not save"; a.informativeText = error.localizedDescription; a.runModal()
        }
    }
    func confirmDiscard() -> Bool {
        if !isDirty { return true }
        let a = NSAlert(); a.messageText = "Discard changes?"; a.addButton(withTitle: "Discard"); a.addButton(withTitle: "Cancel")
        return a.runModal() == .alertFirstButtonReturn
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool { confirmDiscard() }

    // MARK: - Edit extras
    @objc func stampTime(_ s: Any?) {
        let f = DateFormatter(); f.dateFormat = "h:mm a M/d/yyyy"
        textView.insertText(f.string(from: Date()), replacementRange: textView.selectedRange())
    }
    @objc func toggleWrap(_ s: Any?) { wrapOn.toggle(); applyWrap(); if let i = s as? NSMenuItem { i.state = wrapOn ? .on : .off } }
    @objc func toggleStatus(_ s: Any?) { statusBar.isHidden.toggle(); if let i = s as? NSMenuItem { i.state = statusBar.isHidden ? .off : .on } }
    @objc func zoomIn(_ s: Any?) { fontSize += 1; textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular) }
    @objc func zoomOut(_ s: Any?) { fontSize = max(8, fontSize - 1); textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular) }
    @objc func zoomReset(_ s: Any?) { fontSize = 14; textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular) }

    // MARK: - Menu (Notepad feel, Mac keys)
    func buildMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem(); main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Notepad", action: #selector(showAbout(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Notepad", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        func menu(_ title: String, items: [(String, Selector?, String)]) -> NSMenuItem {
            let m = NSMenuItem(); m.submenu = NSMenu(title: title)
            for (t, sel, key) in items {
                if t == "-" { m.submenu!.addItem(.separator()); continue }
                let i = NSMenuItem(title: t, action: sel, keyEquivalent: key)
                if t == "Word Wrap" || t == "Status Bar" { i.state = .on }
                m.submenu!.addItem(i)
            }
            main.addItem(m); return m
        }
        _ = menu("File", items: [
            ("New", #selector(newDoc(_:)), "n"),
            ("Open…", #selector(openDoc(_:)), "o"),
            ("Save", #selector(saveDoc(_:)), "s"),
            ("Save As…", #selector(saveAs(_:)), "S"),
        ])
        _ = menu("Edit", items: [
            ("Undo", Selector(("undo:")), "z"),
            ("Redo", Selector(("redo:")), "Z"),
            ("-", nil, ""),
            ("Cut", Selector(("cut:")), "x"),
            ("Copy", Selector(("copy:")), "c"),
            ("Paste", Selector(("paste:")), "v"),
            ("Select All", Selector(("selectAll:")), "a"),
            ("-", nil, ""),
            ("Time/Date", #selector(stampTime(_:)), ""),
        ])
        _ = menu("Format", items: [("Word Wrap", #selector(toggleWrap(_:)), "")])
        _ = menu("View", items: [
            ("Status Bar", #selector(toggleStatus(_:)), ""),
            ("-", nil, ""),
            ("Zoom In", #selector(zoomIn(_:)), "+"),
            ("Zoom Out", #selector(zoomOut(_:)), "-"),
            ("Reset Zoom", #selector(zoomReset(_:)), "0"),
        ])
        NSApp.mainMenu = main
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    @objc func showAbout(_ s: Any?) {
        let a = NSAlert()
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
