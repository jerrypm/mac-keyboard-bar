# Top Bar Floating Keyboard Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build macOS menu bar app that lives next to Wi-Fi/Battery icons. Click the menu bar icon to toggle a draggable floating keyboard panel that injects keystrokes into the frontmost app — for lazy-couch use with only a wireless mouse.

**Architecture:** VIPER per module (Keyboard, MenuBar) + Builder assembly + Router for window lifecycle + injected Services (KeyInjection, Accessibility, WindowPosition). AppKit (`NSStatusItem`, `NSPanel`) for system integration; SwiftUI (`NSHostingView`) for keyboard rendering. Dependency injection via init — no singletons. Follows reference project `mac-AI-assistant` conventions: max 200 lines/file, 1 type/file, all user-facing strings in `Constants/Strings.swift`, MARK sections, no force unwraps, clean code.

**Tech Stack:** Swift 5, AppKit, SwiftUI, Core Graphics (`CGEvent` for key injection), `ApplicationServices` (`AXIsProcessTrustedWithOptions` for Accessibility permission), `XCTest`, `UserDefaults` for position persistence.

**Key macOS constraints:**
- App must be `LSUIElement = YES` (accessory app, no Dock icon) so the status item is the only UI.
- Key injection via `CGEvent.post(tap: .cghidEventTap)` requires **Accessibility** permission (System Settings → Privacy & Security → Accessibility). Not sandboxable — disable App Sandbox.
- Floating panel must be `NSPanel` subclass overriding `canBecomeKey`/`canBecomeMain` and using `.nonactivatingPanel` style so clicking keys does NOT steal focus from the target app.
- `NSHostingView` bridges SwiftUI keyboard into `NSPanel.contentView`.

---

## Pre-Flight Checklist

Before Task 1:
- [ ] Confirm Xcode project target is `mac-keyboard-bar`, macOS 13+.
- [ ] You are in the repo root `/Users/jeripurnamamaulid/Documents/15_MacOS_Projects/mac-keyboard-bar/`.
- [ ] `git status` is clean.

---

## Target Folder Layout

```
mac-keyboard-bar/
├── main.swift                     (app entry — replaces @main on AppDelegate)
├── AppDelegate.swift              (wires Builders, holds strong refs)
├── Info.plist                     (LSUIElement = YES, NSAccessibilityUsageDescription)
├── mac-keyboard-bar.entitlements  (app sandbox OFF)
├── AppKit/
│   └── FloatingPanel.swift        (NSPanel subclass)
├── Constants/
│   ├── Strings.swift              (all user-facing + key constants)
│   └── Layout.swift               (sizes, insets, window defaults)
├── Entities/
│   ├── KeyDefinition.swift        (one key: label, keyCode, width)
│   ├── KeyboardLayout.swift       (rows of keys — QWERTY default)
│   └── ModifierState.swift        (shift/cmd/opt/ctrl/fn flags)
├── Services/
│   ├── AccessibilityService.swift (permission check + prompt)
│   ├── KeyInjectionService.swift  (CGEvent post)
│   └── WindowPositionService.swift (UserDefaults persist frame)
├── Modules/
│   ├── MenuBar/
│   │   ├── MenuBarProtocols.swift
│   │   ├── MenuBarInteractor.swift
│   │   ├── MenuBarPresenter.swift
│   │   ├── MenuBarRouter.swift
│   │   ├── MenuBarController.swift  (NSStatusItem wrapper)
│   │   └── MenuBarBuilder.swift
│   └── Keyboard/
│       ├── KeyboardProtocols.swift
│       ├── KeyboardInteractor.swift
│       ├── KeyboardPresenter.swift
│       ├── KeyboardRouter.swift
│       ├── KeyboardWindowController.swift
│       └── KeyboardBuilder.swift
└── UI/
    ├── KeyboardView.swift         (SwiftUI root)
    ├── KeyRowView.swift
    └── KeyButtonView.swift

mac-keyboard-barTests/
├── KeyInjectionServiceTests.swift
├── WindowPositionServiceTests.swift
├── KeyboardLayoutTests.swift
├── ModifierStateTests.swift
└── KeyboardPresenterTests.swift
```

---

## Task 1: Project config — LSUIElement + disable sandbox + Accessibility usage string

**Files:**
- Modify: `mac-keyboard-bar/Info.plist`
- Modify: `mac-keyboard-bar/mac-keyboard-bar.entitlements` (create if missing)
- Delete: `mac-keyboard-bar/Base.lproj/MainMenu.xib` (not needed for menu-bar-only app) — **ONLY after confirming unused; see Step 3**

**Step 1: Open Info.plist and add keys**

Add inside top-level `<dict>`:

```xml
<key>LSUIElement</key>
<true/>
<key>NSAccessibilityUsageDescription</key>
<string>mac-keyboard-bar injects keystrokes into the focused app so you can type from the couch.</string>
```

**Step 2: Disable App Sandbox**

Edit `mac-keyboard-bar.entitlements`. If file doesn't exist, create with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

Then in Xcode: Target → Signing & Capabilities → remove "App Sandbox" capability (or set to NO). Sandbox blocks `CGEvent.post` to other apps.

**Step 3: Remove storyboard wiring**

Open `project.pbxproj` is risky — do it via Xcode GUI instead:
- Target → General → Main Interface: clear the field (empty).
- Delete `Base.lproj/MainMenu.xib` from project (Move to Trash).

**Step 4: Replace AppDelegate entry with `main.swift`**

Create `mac-keyboard-bar/main.swift`:

```swift
import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
```

Edit `AppDelegate.swift` — remove `@main` attribute, remove `@IBOutlet var window`, keep class skeleton (we fill wiring in Task 19):

```swift
import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties
    // (populated by Builders in Task 19)

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Task 19 wires here
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}
```

**Step 5: Build and launch**

Run: `xcodebuild -project mac-keyboard-bar.xcodeproj -scheme mac-keyboard-bar -configuration Debug build`
Expected: Build succeeded. Launching the app shows NO Dock icon and NO window (correct — menu bar comes later).

**Step 6: Commit**

```bash
git add -A
git commit -m "chore: configure accessory app (LSUIElement, no sandbox, Accessibility usage)"
```

---

## Task 2: Strings constants

**Files:**
- Create: `mac-keyboard-bar/Constants/Strings.swift`

**Step 1: Write test first**

Create `mac-keyboard-barTests/StringsTests.swift`:

```swift
import XCTest
@testable import mac_keyboard_bar

final class StringsTests: XCTestCase {

    func test_appStrings_areNonEmpty() {
        XCTAssertFalse(Strings.App.name.isEmpty)
        XCTAssertFalse(Strings.App.quit.isEmpty)
    }

    func test_accessibilityStrings_hasPermissionTitle() {
        XCTAssertFalse(Strings.Accessibility.permissionTitle.isEmpty)
        XCTAssertFalse(Strings.Accessibility.permissionMessage.isEmpty)
    }
}
```

**Step 2: Run to confirm failure**

Run: `xcodebuild test -project mac-keyboard-bar.xcodeproj -scheme mac-keyboard-bar -destination 'platform=macOS'`
Expected: FAIL — `Strings` undefined.

**Step 3: Implement**

Create `Constants/Strings.swift`:

```swift
import Foundation

enum Strings {
    static let empty = ""

    enum App {
        static let name = "Keyboard Bar"
        static let quit = "Quit"
        static let about = "About"
    }

    enum MenuBar {
        static let iconSymbol = "keyboard"
        static let iconAccessibility = "Toggle floating keyboard"
        static let show = "Show Keyboard"
        static let hide = "Hide Keyboard"
        static let openAccessibilitySettings = "Open Accessibility Settings…"
    }

    enum Keyboard {
        static let title = "Floating Keyboard"
    }

    enum Accessibility {
        static let permissionTitle = "Accessibility Access Required"
        static let permissionMessage = "Grant Accessibility access so Keyboard Bar can send keystrokes to the focused app."
        static let permissionButtonOpen = "Open System Settings"
        static let permissionButtonCancel = "Cancel"
    }

    enum Defaults {
        static let windowFrameKey = "keyboard.window.frame"
    }
}
```

**Step 4: Run tests — expect pass**

Run: `xcodebuild test ...`
Expected: PASS.

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add Strings constants"
```

---

## Task 3: Layout constants

**Files:**
- Create: `mac-keyboard-bar/Constants/Layout.swift`

**Step 1: Write test**

`mac-keyboard-barTests/LayoutTests.swift`:

```swift
import XCTest
@testable import mac_keyboard_bar

final class LayoutTests: XCTestCase {

    func test_keyboardDefaults_arePositive() {
        XCTAssertGreaterThan(Layout.Keyboard.defaultWidth, 0)
        XCTAssertGreaterThan(Layout.Keyboard.defaultHeight, 0)
        XCTAssertGreaterThan(Layout.Keyboard.keyUnitSize, 0)
    }
}
```

**Step 2: Run — expect FAIL**

**Step 3: Implement `Constants/Layout.swift`:**

```swift
import CoreGraphics

enum Layout {

    enum Keyboard {
        static let defaultWidth: CGFloat = 720
        static let defaultHeight: CGFloat = 260
        static let keyUnitSize: CGFloat = 44
        static let keySpacing: CGFloat = 4
        static let rowSpacing: CGFloat = 6
        static let contentPadding: CGFloat = 10
        static let cornerRadius: CGFloat = 14
    }

    enum MenuBar {
        static let iconSize: CGFloat = 18
    }
}
```

**Step 4: Run — expect PASS.**

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add Layout constants"
```

---

## Task 4: ModifierState entity

**Files:**
- Create: `mac-keyboard-bar/Entities/ModifierState.swift`
- Create: `mac-keyboard-barTests/ModifierStateTests.swift`

**Step 1: Write tests**

```swift
import XCTest
@testable import mac_keyboard_bar

final class ModifierStateTests: XCTestCase {

    func test_default_allFalse() {
        let s = ModifierState()
        XCTAssertFalse(s.shift)
        XCTAssertFalse(s.command)
        XCTAssertFalse(s.option)
        XCTAssertFalse(s.control)
        XCTAssertFalse(s.fn)
    }

    func test_toggle_flipsFlag() {
        var s = ModifierState()
        s.toggle(.shift)
        XCTAssertTrue(s.shift)
        s.toggle(.shift)
        XCTAssertFalse(s.shift)
    }

    func test_cgEventFlags_reflectsActiveModifiers() {
        var s = ModifierState()
        s.shift = true
        s.command = true
        let flags = s.cgEventFlags
        XCTAssertTrue(flags.contains(.maskShift))
        XCTAssertTrue(flags.contains(.maskCommand))
        XCTAssertFalse(flags.contains(.maskAlternate))
    }

    func test_clearOneShot_clearsNonStickyModifiers() {
        var s = ModifierState()
        s.shift = true
        s.command = true
        s.clearOneShot()
        XCTAssertFalse(s.shift)
        XCTAssertFalse(s.command)
    }
}
```

**Step 2: Run — expect FAIL (undefined).**

**Step 3: Implement**

```swift
import CoreGraphics

struct ModifierState: Equatable {

    // MARK: - Keys

    enum Key {
        case shift, command, option, control, fn
    }

    // MARK: - Properties

    var shift = false
    var command = false
    var option = false
    var control = false
    var fn = false

    // MARK: - Mutations

    mutating func toggle(_ key: Key) {
        switch key {
        case .shift: shift.toggle()
        case .command: command.toggle()
        case .option: option.toggle()
        case .control: control.toggle()
        case .fn: fn.toggle()
        }
    }

    mutating func clearOneShot() {
        shift = false
        command = false
        option = false
        control = false
        fn = false
    }

    // MARK: - CGEvent Flags

    var cgEventFlags: CGEventFlags {
        var flags: CGEventFlags = []
        if shift   { flags.insert(.maskShift) }
        if command { flags.insert(.maskCommand) }
        if option  { flags.insert(.maskAlternate) }
        if control { flags.insert(.maskControl) }
        if fn      { flags.insert(.maskSecondaryFn) }
        return flags
    }
}
```

**Step 4: Run — expect PASS.**

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add ModifierState entity"
```

---

## Task 5: KeyDefinition + KeyboardLayout entities

**Files:**
- Create: `mac-keyboard-bar/Entities/KeyDefinition.swift`
- Create: `mac-keyboard-bar/Entities/KeyboardLayout.swift`
- Create: `mac-keyboard-barTests/KeyboardLayoutTests.swift`

**Step 1: Write tests**

```swift
import XCTest
@testable import mac_keyboard_bar

final class KeyboardLayoutTests: XCTestCase {

    func test_qwertyLayout_hasFiveRows() {
        XCTAssertEqual(KeyboardLayout.qwerty.rows.count, 5)
    }

    func test_qwertyLayout_numberRowHasTenKeys() {
        let row = KeyboardLayout.qwerty.rows[0]
        XCTAssertEqual(row.count, 10)
        XCTAssertEqual(row.first?.label, "1")
    }

    func test_keyDefinition_modifierFlagIsSet() {
        let shift = KeyDefinition(label: "⇧", keyCode: 0x38, kind: .modifier(.shift))
        if case .modifier(let mod) = shift.kind {
            XCTAssertEqual(mod, .shift)
        } else {
            XCTFail("expected modifier")
        }
    }
}
```

**Step 2: Run — FAIL.**

**Step 3: Implement `KeyDefinition.swift`**

```swift
import CoreGraphics

struct KeyDefinition: Equatable {

    enum Kind: Equatable {
        case character       // injects via keyCode
        case modifier(ModifierState.Key)
        case toggle          // caps-lock style sticky
    }

    let label: String
    let keyCode: CGKeyCode
    let kind: Kind
    let widthUnits: CGFloat

    init(label: String, keyCode: CGKeyCode, kind: Kind = .character, widthUnits: CGFloat = 1) {
        self.label = label
        self.keyCode = keyCode
        self.kind = kind
        self.widthUnits = widthUnits
    }
}
```

**Step 4: Implement `KeyboardLayout.swift`**

macOS virtual key codes are from `<Carbon/HIToolbox/Events.h>`. Hard-coded here to avoid importing Carbon.

```swift
struct KeyboardLayout {

    let rows: [[KeyDefinition]]

    static let qwerty = KeyboardLayout(rows: [
        // Row 0 — numbers
        [
            .init(label: "1", keyCode: 0x12),
            .init(label: "2", keyCode: 0x13),
            .init(label: "3", keyCode: 0x14),
            .init(label: "4", keyCode: 0x15),
            .init(label: "5", keyCode: 0x17),
            .init(label: "6", keyCode: 0x16),
            .init(label: "7", keyCode: 0x1A),
            .init(label: "8", keyCode: 0x1C),
            .init(label: "9", keyCode: 0x19),
            .init(label: "0", keyCode: 0x1D),
        ],
        // Row 1 — QWERTY
        [
            .init(label: "Q", keyCode: 0x0C),
            .init(label: "W", keyCode: 0x0D),
            .init(label: "E", keyCode: 0x0E),
            .init(label: "R", keyCode: 0x0F),
            .init(label: "T", keyCode: 0x11),
            .init(label: "Y", keyCode: 0x10),
            .init(label: "U", keyCode: 0x20),
            .init(label: "I", keyCode: 0x22),
            .init(label: "O", keyCode: 0x1F),
            .init(label: "P", keyCode: 0x23),
        ],
        // Row 2 — ASDF
        [
            .init(label: "A", keyCode: 0x00),
            .init(label: "S", keyCode: 0x01),
            .init(label: "D", keyCode: 0x02),
            .init(label: "F", keyCode: 0x03),
            .init(label: "G", keyCode: 0x05),
            .init(label: "H", keyCode: 0x04),
            .init(label: "J", keyCode: 0x26),
            .init(label: "K", keyCode: 0x28),
            .init(label: "L", keyCode: 0x25),
            .init(label: "⏎", keyCode: 0x24, widthUnits: 1.5),
        ],
        // Row 3 — ZXCV
        [
            .init(label: "⇧", keyCode: 0x38, kind: .modifier(.shift), widthUnits: 1.5),
            .init(label: "Z", keyCode: 0x06),
            .init(label: "X", keyCode: 0x07),
            .init(label: "C", keyCode: 0x08),
            .init(label: "V", keyCode: 0x09),
            .init(label: "B", keyCode: 0x0B),
            .init(label: "N", keyCode: 0x2D),
            .init(label: "M", keyCode: 0x2E),
            .init(label: ",", keyCode: 0x2B),
            .init(label: ".", keyCode: 0x2F),
            .init(label: "⌫", keyCode: 0x33),
        ],
        // Row 4 — modifiers + space
        [
            .init(label: "⌃", keyCode: 0x3B, kind: .modifier(.control)),
            .init(label: "⌥", keyCode: 0x3A, kind: .modifier(.option)),
            .init(label: "⌘", keyCode: 0x37, kind: .modifier(.command), widthUnits: 1.2),
            .init(label: "space", keyCode: 0x31, widthUnits: 4),
            .init(label: "⌘", keyCode: 0x36, kind: .modifier(.command), widthUnits: 1.2),
            .init(label: "←", keyCode: 0x7B),
            .init(label: "↓", keyCode: 0x7D),
            .init(label: "↑", keyCode: 0x7E),
            .init(label: "→", keyCode: 0x7C),
        ],
    ])
}
```

**Step 5: Run tests — PASS.**

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: add KeyDefinition and QWERTY KeyboardLayout"
```

---

## Task 6: AccessibilityService

**Files:**
- Create: `mac-keyboard-bar/Services/AccessibilityService.swift`

No unit test — wraps a global Apple API (`AXIsProcessTrustedWithOptions`) that cannot be stubbed without a wrapper. We verify manually in Task 15.

**Step 1: Implement**

```swift
import ApplicationServices
import AppKit

protocol AccessibilityServicing {
    var isTrusted: Bool { get }
    func requestPermission()
    func openSystemSettings()
}

final class AccessibilityService: AccessibilityServicing {

    // MARK: - AccessibilityServicing

    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: CFDictionary = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
```

**Step 2: Build**

Run: `xcodebuild build ...`
Expected: success.

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add AccessibilityService wrapper"
```

---

## Task 7: KeyInjectionService

**Files:**
- Create: `mac-keyboard-bar/Services/KeyInjectionService.swift`
- Create: `mac-keyboard-barTests/KeyInjectionServiceTests.swift`

**Design:** Service exposes `inject(keyCode:flags:)` → builds key-down + key-up `CGEvent`s, posts to `.cghidEventTap`. For testability we inject a `poster: (CGEvent) -> Void` closure so tests can capture events without touching the real tap.

**Step 1: Write tests**

```swift
import XCTest
import CoreGraphics
@testable import mac_keyboard_bar

final class KeyInjectionServiceTests: XCTestCase {

    func test_inject_postsDownThenUp() {
        var posted: [(CGKeyCode, Bool)] = []
        let sut = KeyInjectionService { event in
            guard let e = event else { return }
            let keyCode = CGKeyCode(e.getIntegerValueField(.keyboardEventKeycode))
            let isDown = e.getIntegerValueField(.keyboardEventAutorepeat) == 0
                && e.type == .keyDown
            posted.append((keyCode, isDown))
        }

        sut.inject(keyCode: 0x00, flags: [])

        XCTAssertEqual(posted.count, 2)
        XCTAssertEqual(posted[0].0, 0x00)
        XCTAssertTrue(posted[0].1)   // down
        XCTAssertEqual(posted[1].0, 0x00)
        XCTAssertFalse(posted[1].1)  // up
    }

    func test_inject_appliesFlags() {
        var capturedFlags: CGEventFlags = []
        let sut = KeyInjectionService { event in
            if event?.type == .keyDown { capturedFlags = event?.flags ?? [] }
        }

        sut.inject(keyCode: 0x00, flags: [.maskShift, .maskCommand])

        XCTAssertTrue(capturedFlags.contains(.maskShift))
        XCTAssertTrue(capturedFlags.contains(.maskCommand))
    }
}
```

**Step 2: Run — FAIL.**

**Step 3: Implement**

```swift
import CoreGraphics

protocol KeyInjecting {
    func inject(keyCode: CGKeyCode, flags: CGEventFlags)
}

final class KeyInjectionService: KeyInjecting {

    // MARK: - Types

    typealias EventPoster = (CGEvent?) -> Void

    // MARK: - Properties

    private let source = CGEventSource(stateID: .hidSystemState)
    private let poster: EventPoster

    // MARK: - Init

    /// Default poster sends to the real HID tap.
    init(poster: EventPoster? = nil) {
        self.poster = poster ?? { event in
            event?.post(tap: .cghidEventTap)
        }
    }

    // MARK: - KeyInjecting

    func inject(keyCode: CGKeyCode, flags: CGEventFlags) {
        let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        down?.flags = flags
        poster(down)

        let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        up?.flags = flags
        poster(up)
    }
}
```

**Step 4: Run — PASS.**

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add KeyInjectionService with testable CGEvent poster"
```

---

## Task 8: WindowPositionService

**Files:**
- Create: `mac-keyboard-bar/Services/WindowPositionService.swift`
- Create: `mac-keyboard-barTests/WindowPositionServiceTests.swift`

**Step 1: Write tests**

```swift
import XCTest
@testable import mac_keyboard_bar

final class WindowPositionServiceTests: XCTestCase {

    func test_saveAndLoad_returnsSameFrame() {
        let defaults = UserDefaults(suiteName: "test-\(UUID())")!
        let sut = WindowPositionService(defaults: defaults)
        let frame = CGRect(x: 100, y: 200, width: 720, height: 260)

        sut.save(frame: frame)

        XCTAssertEqual(sut.loadFrame(), frame)
    }

    func test_loadFrame_returnsNilWhenUnset() {
        let defaults = UserDefaults(suiteName: "test-\(UUID())")!
        let sut = WindowPositionService(defaults: defaults)

        XCTAssertNil(sut.loadFrame())
    }
}
```

**Step 2: Run — FAIL.**

**Step 3: Implement**

```swift
import CoreGraphics
import Foundation

protocol WindowPositionStoring {
    func loadFrame() -> CGRect?
    func save(frame: CGRect)
}

final class WindowPositionService: WindowPositionStoring {

    // MARK: - Properties

    private let defaults: UserDefaults
    private let key = Strings.Defaults.windowFrameKey

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - WindowPositionStoring

    func loadFrame() -> CGRect? {
        guard let string = defaults.string(forKey: key) else { return nil }
        let rect = NSRectFromString(string)
        return rect == .zero ? nil : rect
    }

    func save(frame: CGRect) {
        defaults.set(NSStringFromRect(frame), forKey: key)
    }
}
```

**Step 4: Run — PASS.**

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add WindowPositionService"
```

---

## Task 9: FloatingPanel

**Files:**
- Create: `mac-keyboard-bar/AppKit/FloatingPanel.swift`

**Step 1: Implement**

```swift
import Cocoa

/// Nonactivating NSPanel that can become key without stealing focus
/// from the frontmost app — required so injected keystrokes reach the
/// previously-focused app instead of the keyboard panel itself.
final class FloatingPanel: NSPanel {

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
```

**Step 2: Build — success.**

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add nonactivating FloatingPanel"
```

---

## Task 10: KeyButtonView (SwiftUI)

**Files:**
- Create: `mac-keyboard-bar/UI/KeyButtonView.swift`

**Step 1: Implement**

```swift
import SwiftUI

struct KeyButtonView: View {

    // MARK: - Input

    let key: KeyDefinition
    let isActive: Bool
    let onTap: (KeyDefinition) -> Void

    // MARK: - Body

    var body: some View {
        Button {
            onTap(key)
        } label: {
            Text(key.label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .frame(
                    width: Layout.Keyboard.keyUnitSize * key.widthUnits
                        + Layout.Keyboard.keySpacing * (key.widthUnits - 1),
                    height: Layout.Keyboard.keyUnitSize
                )
                .background(background)
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isActive ? Color.accentColor.opacity(0.8) : Color.secondary.opacity(0.25))
    }
}
```

**Step 2: Build — success.**

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add KeyButtonView"
```

---

## Task 11: KeyRowView

**Files:**
- Create: `mac-keyboard-bar/UI/KeyRowView.swift`

**Step 1: Implement**

```swift
import SwiftUI

struct KeyRowView: View {

    let keys: [KeyDefinition]
    let activeModifiers: ModifierState
    let onTap: (KeyDefinition) -> Void

    var body: some View {
        HStack(spacing: Layout.Keyboard.keySpacing) {
            ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                KeyButtonView(key: key, isActive: isActive(key), onTap: onTap)
            }
        }
    }

    private func isActive(_ key: KeyDefinition) -> Bool {
        guard case .modifier(let mod) = key.kind else { return false }
        switch mod {
        case .shift:   return activeModifiers.shift
        case .command: return activeModifiers.command
        case .option:  return activeModifiers.option
        case .control: return activeModifiers.control
        case .fn:      return activeModifiers.fn
        }
    }
}
```

**Step 2: Build — success.**

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add KeyRowView"
```

---

## Task 12: KeyboardView (SwiftUI root)

**Files:**
- Create: `mac-keyboard-bar/UI/KeyboardView.swift`

**Step 1: Implement**

```swift
import SwiftUI

struct KeyboardView: View {

    let layout: KeyboardLayout
    @Binding var modifiers: ModifierState
    let onKey: (KeyDefinition) -> Void

    var body: some View {
        VStack(spacing: Layout.Keyboard.rowSpacing) {
            ForEach(Array(layout.rows.enumerated()), id: \.offset) { _, row in
                KeyRowView(keys: row, activeModifiers: modifiers, onTap: onKey)
            }
        }
        .padding(Layout.Keyboard.contentPadding)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Layout.Keyboard.cornerRadius))
    }
}
```

**Step 2: Build — success.**

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add KeyboardView"
```

---

## Task 13: KeyboardProtocols (VIPER contract)

**Files:**
- Create: `mac-keyboard-bar/Modules/Keyboard/KeyboardProtocols.swift`

**Step 1: Implement**

```swift
import Foundation

// MARK: - View -> Presenter

protocol KeyboardPresenterInput: AnyObject {
    var modifiers: ModifierState { get }
    func handleKey(_ key: KeyDefinition)
}

// MARK: - Presenter -> Interactor

protocol KeyboardInteractorInput: AnyObject {
    func sendKey(keyCode: CGKeyCode, flags: CGEventFlags)
    var hasAccessibilityPermission: Bool { get }
    func requestAccessibilityPermission()
}

// MARK: - Presenter -> Router

protocol KeyboardRouterInput: AnyObject {
    func show()
    func hide()
    var isVisible: Bool { get }
    func presentAccessibilityAlert()
}
```

**Step 2: Build — success.**

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add KeyboardProtocols"
```

---

## Task 14: KeyboardInteractor + unit test

**Files:**
- Create: `mac-keyboard-bar/Modules/Keyboard/KeyboardInteractor.swift`
- Create: `mac-keyboard-barTests/KeyboardInteractorTests.swift`

**Step 1: Tests**

```swift
import XCTest
import CoreGraphics
@testable import mac_keyboard_bar

final class KeyboardInteractorTests: XCTestCase {

    final class SpyInjector: KeyInjecting {
        var calls: [(CGKeyCode, CGEventFlags)] = []
        func inject(keyCode: CGKeyCode, flags: CGEventFlags) {
            calls.append((keyCode, flags))
        }
    }

    final class StubAccessibility: AccessibilityServicing {
        var isTrusted = true
        func requestPermission() {}
        func openSystemSettings() {}
    }

    func test_sendKey_delegatesToInjector() {
        let injector = SpyInjector()
        let sut = KeyboardInteractor(injector: injector, accessibility: StubAccessibility())

        sut.sendKey(keyCode: 0x00, flags: [.maskShift])

        XCTAssertEqual(injector.calls.count, 1)
        XCTAssertEqual(injector.calls[0].0, 0x00)
        XCTAssertTrue(injector.calls[0].1.contains(.maskShift))
    }

    func test_hasAccessibilityPermission_reflectsService() {
        let access = StubAccessibility()
        access.isTrusted = false
        let sut = KeyboardInteractor(injector: SpyInjector(), accessibility: access)
        XCTAssertFalse(sut.hasAccessibilityPermission)
    }
}
```

**Step 2: Run — FAIL.**

**Step 3: Implement**

```swift
import CoreGraphics

final class KeyboardInteractor: KeyboardInteractorInput {

    // MARK: - Dependencies

    private let injector: KeyInjecting
    private let accessibility: AccessibilityServicing

    // MARK: - Init

    init(injector: KeyInjecting, accessibility: AccessibilityServicing) {
        self.injector = injector
        self.accessibility = accessibility
    }

    // MARK: - KeyboardInteractorInput

    var hasAccessibilityPermission: Bool {
        accessibility.isTrusted
    }

    func requestAccessibilityPermission() {
        accessibility.requestPermission()
    }

    func sendKey(keyCode: CGKeyCode, flags: CGEventFlags) {
        injector.inject(keyCode: keyCode, flags: flags)
    }
}
```

**Step 4: Run — PASS.**

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add KeyboardInteractor"
```

---

## Task 15: KeyboardPresenter + tests

**Files:**
- Create: `mac-keyboard-bar/Modules/Keyboard/KeyboardPresenter.swift`
- Create: `mac-keyboard-barTests/KeyboardPresenterTests.swift`

**Behavior:**
- `handleKey(modifier)` → toggle the modifier flag.
- `handleKey(character)` → if no permission → router.presentAccessibilityAlert; else interactor.sendKey with current flags, then clear one-shot modifiers.

**Step 1: Tests**

```swift
import XCTest
import CoreGraphics
@testable import mac_keyboard_bar

final class KeyboardPresenterTests: XCTestCase {

    final class FakeInteractor: KeyboardInteractorInput {
        var calls: [(CGKeyCode, CGEventFlags)] = []
        var trusted = true
        var hasAccessibilityPermission: Bool { trusted }
        func requestAccessibilityPermission() {}
        func sendKey(keyCode: CGKeyCode, flags: CGEventFlags) {
            calls.append((keyCode, flags))
        }
    }

    final class FakeRouter: KeyboardRouterInput {
        var shown = false
        var alertShown = false
        var isVisible: Bool { shown }
        func show() { shown = true }
        func hide() { shown = false }
        func presentAccessibilityAlert() { alertShown = true }
    }

    func test_handleKey_modifier_togglesState() {
        let sut = KeyboardPresenter(interactor: FakeInteractor(), router: FakeRouter())
        let shift = KeyDefinition(label: "⇧", keyCode: 0x38, kind: .modifier(.shift))

        sut.handleKey(shift)

        XCTAssertTrue(sut.modifiers.shift)
    }

    func test_handleKey_character_sendsKeyAndClearsModifiers() {
        let interactor = FakeInteractor()
        let sut = KeyboardPresenter(interactor: interactor, router: FakeRouter())
        sut.handleKey(KeyDefinition(label: "⇧", keyCode: 0x38, kind: .modifier(.shift)))

        sut.handleKey(KeyDefinition(label: "A", keyCode: 0x00))

        XCTAssertEqual(interactor.calls.count, 1)
        XCTAssertTrue(interactor.calls[0].1.contains(.maskShift))
        XCTAssertFalse(sut.modifiers.shift)
    }

    func test_handleKey_character_noPermission_presentsAlert() {
        let interactor = FakeInteractor()
        interactor.trusted = false
        let router = FakeRouter()
        let sut = KeyboardPresenter(interactor: interactor, router: router)

        sut.handleKey(KeyDefinition(label: "A", keyCode: 0x00))

        XCTAssertTrue(router.alertShown)
        XCTAssertEqual(interactor.calls.count, 0)
    }
}
```

**Step 2: Run — FAIL.**

**Step 3: Implement**

```swift
import CoreGraphics

final class KeyboardPresenter: KeyboardPresenterInput {

    // MARK: - Dependencies

    private let interactor: KeyboardInteractorInput
    private let router: KeyboardRouterInput

    // MARK: - State

    private(set) var modifiers = ModifierState()

    /// Notifies observer (KeyboardWindowController → SwiftUI binding) after state change.
    var onStateChange: (() -> Void)?

    // MARK: - Init

    init(interactor: KeyboardInteractorInput, router: KeyboardRouterInput) {
        self.interactor = interactor
        self.router = router
    }

    // MARK: - KeyboardPresenterInput

    func handleKey(_ key: KeyDefinition) {
        switch key.kind {
        case .modifier(let mod):
            modifiers.toggle(mod)
            onStateChange?()

        case .character, .toggle:
            guard interactor.hasAccessibilityPermission else {
                router.presentAccessibilityAlert()
                return
            }
            interactor.sendKey(keyCode: key.keyCode, flags: modifiers.cgEventFlags)
            modifiers.clearOneShot()
            onStateChange?()
        }
    }
}
```

**Step 4: Run — PASS.**

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add KeyboardPresenter with modifier + character handling"
```

---

## Task 16: KeyboardRouter + KeyboardWindowController

**Files:**
- Create: `mac-keyboard-bar/Modules/Keyboard/KeyboardRouter.swift`
- Create: `mac-keyboard-bar/Modules/Keyboard/KeyboardWindowController.swift`

**Step 1: Implement `KeyboardWindowController.swift`**

```swift
import Cocoa
import SwiftUI

final class KeyboardWindowController {

    // MARK: - Properties

    private let panel: FloatingPanel
    private let presenter: KeyboardPresenter
    private let positionStore: WindowPositionStoring
    private var hostingView: NSHostingView<AnyView>?

    // MARK: - Init

    init(presenter: KeyboardPresenter, positionStore: WindowPositionStoring) {
        self.presenter = presenter
        self.positionStore = positionStore

        let frame = positionStore.loadFrame() ?? Self.defaultFrame()
        panel = FloatingPanel(
            contentRect: frame,
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        configurePanel()
        installHostingView()
        observePresenter()
        observeFrameChanges()
    }

    // MARK: - API

    func show() {
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    var isVisible: Bool { panel.isVisible }

    // MARK: - Setup

    private func configurePanel() {
        panel.title = Strings.Keyboard.title
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
    }

    private func installHostingView() {
        let root = AnyView(
            KeyboardView(
                layout: .qwerty,
                modifiers: Binding(
                    get: { [unowned self] in self.presenter.modifiers },
                    set: { _ in /* presenter is source of truth */ }
                ),
                onKey: { [weak presenter] key in
                    presenter?.handleKey(key)
                }
            )
        )
        let host = NSHostingView(rootView: root)
        host.frame = panel.contentView?.bounds ?? .zero
        host.autoresizingMask = [.width, .height]
        panel.contentView = host
        hostingView = host
    }

    private func observePresenter() {
        presenter.onStateChange = { [weak self] in
            self?.reinstallRootView()
        }
    }

    private func reinstallRootView() {
        // Rebuild SwiftUI root so the captured `modifiers` value updates.
        installHostingView()
    }

    private func observeFrameChanges() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.positionStore.save(frame: self.panel.frame)
        }
    }

    // MARK: - Defaults

    private static func defaultFrame() -> CGRect {
        guard let screen = NSScreen.main else {
            return CGRect(x: 100, y: 100, width: Layout.Keyboard.defaultWidth, height: Layout.Keyboard.defaultHeight)
        }
        let width = Layout.Keyboard.defaultWidth
        let height = Layout.Keyboard.defaultHeight
        let x = screen.visibleFrame.midX - width / 2
        let y = screen.visibleFrame.minY + 80
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
```

**(File is ~95 lines — under 200 limit.)**

**Step 2: Implement `KeyboardRouter.swift`**

```swift
import Cocoa

final class KeyboardRouter: KeyboardRouterInput {

    // MARK: - Dependencies

    var windowController: KeyboardWindowController?
    private let accessibility: AccessibilityServicing

    // MARK: - Init

    init(accessibility: AccessibilityServicing) {
        self.accessibility = accessibility
    }

    // MARK: - KeyboardRouterInput

    var isVisible: Bool { windowController?.isVisible ?? false }

    func show() { windowController?.show() }
    func hide() { windowController?.hide() }

    func presentAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = Strings.Accessibility.permissionTitle
        alert.informativeText = Strings.Accessibility.permissionMessage
        alert.addButton(withTitle: Strings.Accessibility.permissionButtonOpen)
        alert.addButton(withTitle: Strings.Accessibility.permissionButtonCancel)

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            accessibility.openSystemSettings()
        }
    }
}
```

**Step 3: Build — success.**

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: add KeyboardRouter and FloatingKeyboardWindowController"
```

---

## Task 17: KeyboardBuilder

**Files:**
- Create: `mac-keyboard-bar/Modules/Keyboard/KeyboardBuilder.swift`

**Step 1: Implement**

```swift
import Foundation

enum KeyboardBuilder {

    struct Module {
        let presenter: KeyboardPresenter
        let router: KeyboardRouter
        let windowController: KeyboardWindowController
    }

    static func build(
        accessibility: AccessibilityServicing = AccessibilityService(),
        injector: KeyInjecting = KeyInjectionService(),
        positionStore: WindowPositionStoring = WindowPositionService()
    ) -> Module {
        let interactor = KeyboardInteractor(injector: injector, accessibility: accessibility)
        let router = KeyboardRouter(accessibility: accessibility)
        let presenter = KeyboardPresenter(interactor: interactor, router: router)
        let controller = KeyboardWindowController(presenter: presenter, positionStore: positionStore)
        router.windowController = controller
        return Module(presenter: presenter, router: router, windowController: controller)
    }
}
```

**Step 2: Build — success.**

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add KeyboardBuilder"
```

---

## Task 18: MenuBar module (Protocols + Controller + Builder)

**Files:**
- Create: `mac-keyboard-bar/Modules/MenuBar/MenuBarProtocols.swift`
- Create: `mac-keyboard-bar/Modules/MenuBar/MenuBarPresenter.swift`
- Create: `mac-keyboard-bar/Modules/MenuBar/MenuBarController.swift`
- Create: `mac-keyboard-bar/Modules/MenuBar/MenuBarBuilder.swift`

MenuBar is a thin VIPER-lite (no Interactor / no Router — it only reads keyboard visibility and tells the keyboard Router to toggle).

**Step 1: Protocols**

```swift
import Foundation

protocol MenuBarPresenterInput: AnyObject {
    var isKeyboardVisible: Bool { get }
    func toggle()
    func quit()
}
```

**Step 2: Presenter**

```swift
import Cocoa

final class MenuBarPresenter: MenuBarPresenterInput {

    private let keyboardRouter: KeyboardRouterInput

    init(keyboardRouter: KeyboardRouterInput) {
        self.keyboardRouter = keyboardRouter
    }

    var isKeyboardVisible: Bool { keyboardRouter.isVisible }

    func toggle() {
        if keyboardRouter.isVisible {
            keyboardRouter.hide()
        } else {
            keyboardRouter.show()
        }
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}
```

**Step 3: Controller**

```swift
import Cocoa

final class MenuBarController {

    // MARK: - Properties

    private var statusItem: NSStatusItem!
    private let presenter: MenuBarPresenterInput

    // MARK: - Init

    init(presenter: MenuBarPresenterInput) {
        self.presenter = presenter
        setupStatusItem()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: Strings.MenuBar.iconSymbol,
                                   accessibilityDescription: Strings.MenuBar.iconAccessibility)
            button.image?.size = NSSize(width: Layout.MenuBar.iconSize, height: Layout.MenuBar.iconSize)
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    // MARK: - Actions

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showMenu()
        } else {
            presenter.toggle()
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        let toggle = NSMenuItem(
            title: presenter.isKeyboardVisible ? Strings.MenuBar.hide : Strings.MenuBar.show,
            action: #selector(togglePanel),
            keyEquivalent: Strings.empty
        )
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: Strings.App.quit, action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func togglePanel() { presenter.toggle() }
    @objc private func quitApp()    { presenter.quit() }
}
```

**Step 4: Builder**

```swift
enum MenuBarBuilder {

    struct Module {
        let presenter: MenuBarPresenter
        let controller: MenuBarController
    }

    static func build(keyboardRouter: KeyboardRouterInput) -> Module {
        let presenter = MenuBarPresenter(keyboardRouter: keyboardRouter)
        let controller = MenuBarController(presenter: presenter)
        return Module(presenter: presenter, controller: controller)
    }
}
```

**Step 5: Build — success.**

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: add MenuBar VIPER module with status item"
```

---

## Task 19: AppDelegate wires modules and requests Accessibility on first launch

**Files:**
- Modify: `mac-keyboard-bar/AppDelegate.swift`

**Step 1: Fill AppDelegate**

```swift
import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    private var keyboardModule: KeyboardBuilder.Module?
    private var menuBarModule: MenuBarBuilder.Module?
    private let accessibility = AccessibilityService()

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        let keyboard = KeyboardBuilder.build(
            accessibility: accessibility,
            injector: KeyInjectionService(),
            positionStore: WindowPositionService()
        )
        let menuBar = MenuBarBuilder.build(keyboardRouter: keyboard.router)

        keyboardModule = keyboard
        menuBarModule = menuBar

        promptAccessibilityIfNeeded()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Private

    private func promptAccessibilityIfNeeded() {
        guard !accessibility.isTrusted else { return }
        accessibility.requestPermission()
    }
}
```

**Step 2: Build and run**

Run: `xcodebuild build ...` then launch the app.

**Manual verify checklist:**
- [ ] No Dock icon appears.
- [ ] Keyboard icon shows in menu bar, right side next to Wi-Fi/Battery.
- [ ] First launch: macOS prompts for Accessibility.
- [ ] After granting + relaunch: click menu bar icon → floating keyboard appears.
- [ ] Drag the keyboard anywhere on screen.
- [ ] Focus another app (TextEdit), click keys — letters appear in TextEdit.
- [ ] Shift key lights up, next letter is uppercase, shift clears afterward.
- [ ] Quit app, relaunch — keyboard appears at the last position.

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: wire modules in AppDelegate with Accessibility prompt"
```

---

## Task 20: Add Xcode project file refs

All new `.swift` files must be in the Xcode target. After every `Create:` task, add the file to the `mac-keyboard-bar` target via Xcode (drag into navigator, ensure target checkbox is ticked). Test files go to the `mac-keyboard-barTests` target.

**Verify:**

```bash
xcodebuild -project mac-keyboard-bar.xcodeproj -scheme mac-keyboard-bar -configuration Debug build
xcodebuild test -project mac-keyboard-bar.xcodeproj -scheme mac-keyboard-bar -destination 'platform=macOS'
```

All tests green. Commit any project.pbxproj diff:

```bash
git add mac-keyboard-bar.xcodeproj/project.pbxproj
git commit -m "chore: add source files to Xcode target"
```

---

## Done — Manual Acceptance

Demo script:
1. Build & Run.
2. Open TextEdit, new document, give it focus.
3. Click the keyboard menu bar icon.
4. Drag floating keyboard so it doesn't overlap TextEdit.
5. Click `H`, `I` — "HI" appears in TextEdit (or "hi" without shift).
6. Click Shift → toggles blue → click `A` → `A` uppercase appears → shift clears.
7. Click ⌘ → Click `S` → Save dialog opens.
8. Right-click menu bar icon → Quit.
9. Relaunch → keyboard opens at the same position.

---

## Constraints Recap (don't violate)
- 200 lines max / file.
- 1 type per file.
- All user-facing strings in `Strings`; layout numbers in `Layout`.
- No singletons except intentional (`AccessibilityService` instance is passed, not a shared singleton — OK).
- No force unwraps except `statusItem!` on IBOutlet-style lazy init (guarded by `setupStatusItem` call in init).
- MARK sections on every class.
- Commits: `feat:`, `fix:`, `refactor:`, `chore:`.
