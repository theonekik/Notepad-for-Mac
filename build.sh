#!/bin/bash
# Build Notepad.app from source + Assets (icon survives clean checkouts)
set -e
cd "$(dirname "$0")"
APP=Notepad.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -o "$APP/Contents/MacOS/Notepad" Sources/main.swift
chmod +x "$APP/Contents/MacOS/Notepad"
cp Assets/Notepad.icns "$APP/Contents/Resources/Notepad.icns"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string Notepad" "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string studio.noads.notepad" "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1.0" "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0" "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string Notepad" "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 13.0" "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :NSHighResolutionCapable bool true" "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :NSHumanReadableCopyright string Copyright © 2026 No Ads Studio by TheOneKiK." "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string Notepad" "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile Notepad" "$APP/Contents/Info.plist" 2>/dev/null || true
xattr -cr "$APP"
codesign --force --deep -s - "$APP"
rm -f Notepad.app.zip
ditto -c -k --sequesterRsrc --keepParent "$APP" Notepad.app.zip
ls -lh Notepad.app.zip
