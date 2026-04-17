import Foundation

/// `nonisolated` so `nonisolated` services (e.g., `WindowPositionService`) can
/// reference these immutable string constants without a main-actor hop.
nonisolated enum Strings {
    static let empty = ""

    // MARK: - App

    enum App {
        static let name = "Keyboard Bar"
        static let quit = "Quit"
        static let about = "About"
    }

    // MARK: - MenuBar

    enum MenuBar {
        static let iconSymbol = "keyboard"
        static let iconAccessibility = "Toggle floating keyboard"
        static let show = "Show Keyboard"
        static let hide = "Hide Keyboard"
        static let openAccessibilitySettings = "Open Accessibility Settings…"
    }

    // MARK: - Keyboard

    enum Keyboard {
        static let title = "Floating Keyboard"
    }

    // MARK: - Accessibility

    enum Accessibility {
        static let permissionTitle = "Accessibility Access Required"
        static let permissionMessage = "Grant Accessibility access so Keyboard Bar can send keystrokes to the focused app."
        static let permissionButtonOpen = "Open System Settings"
        static let permissionButtonCancel = "Cancel"
    }

    // MARK: - Defaults

    enum Defaults {
        static let windowFrameKey = "keyboard.window.frame"
    }
}
