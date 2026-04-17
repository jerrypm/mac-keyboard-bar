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
