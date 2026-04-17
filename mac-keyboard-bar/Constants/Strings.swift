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
