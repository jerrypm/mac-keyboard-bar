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
