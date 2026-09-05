# Notepad for Mac

> Pure plaintext. Instant. Native. No nonsense.

**By [No Ads Studio by TheOneKiK](https://github.com/theonekik)** — zero ads, zero tracking, zero telemetry. Forever.

![No Ads](https://img.shields.io/badge/No%20Ads-Zero%20Tracking-brightgreen)
![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![Swift](https://img.shields.io/badge/Swift-AppKit-orange)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## ⬇️ Download & Install (30 seconds)

**[⬇️ Download Notepad for Mac v1.0](https://github.com/theonekik/Notepad-for-Mac/releases/download/v1.0/Notepad.app.zip)** (24 KB zip)

1. Click the link above (or get it anytime at [Releases](https://github.com/theonekik/Notepad-for-Mac/releases)).
2. Unzip → you get `Notepad.app`.
3. Drag `Notepad.app` into **Applications**.
4. First launch: right-click → **Open** (app is unsigned, so macOS asks once), then use normally.

No installer, no account, nothing else.

## Why this app was built

Although TextEdit is good, I sometimes badly miss a plaintext editor — just like Notepad. A pure Notepad, exactly like how it is in Windows, with a native-to-the-OS feeling.

On Windows, Notepad is the tool you never think about: it opens instantly, it holds plain text and nothing else, it never asks you anything, it never phones home. On Mac, TextEdit is a good editor — but it doesn't feel that way. It defaults to rich text. It wants fonts, styles, rulers, smart quotes. Every paste brings formatting you have to strip. Every new document makes you check: *is this plain text or rich text?*

This app exists to end that friction:

- **Plaintext only.** No fonts panel, no styles, no embedded images. Ever.
- **Instant like Notepad.** One window, one text view, no sidebar, no toolbar, no iCloud prompt.
- **Native to macOS.** Real menus, Cmd+S/O/N, F5 Time/Date stamp, word wrap, status bar with Ln/Col — but with Mac keys and Mac windowing.
- **No Ads Studio policy.** Offline-only. Your text never leaves your machine.

If you ever wanted Windows Notepad's soul with a Mac body — this is it.

## Features

- New / Open / Save / Save As (`.txt`, UTF-8, LF)
- F5 Time/Date stamp (`h:mm a M/d/yyyy`, like Notepad)
- Word Wrap toggle, Status Bar toggle (Ln, Col, char count)
- Zoom In / Out / Reset (Cmd + / − / 0)
- Dirty `*` indicator, discard-changes guard
- Monospaced editing, smart-quotes/dashes off, spellcheck off

## Build

```bash
cd SwiftNotepad
swiftc -O -o Notepad.app/Contents/MacOS/Notepad Sources/main.swift
open Notepad.app
```

No dependencies. Single `Sources/main.swift` (AppKit). macOS 13+.

## Privacy — No Ads Studio Policy

- No ads. No tracking. No analytics. No telemetry.
- No network calls of any kind (verify: `grep -ri URLSession main.swift` → nothing).
- Files stay on your disk. No cloud, no account, no sign-in.
- See [PRIVACY.md](PRIVACY.md).
