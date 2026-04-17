import Cocoa

final class MenuBarPresenter: MenuBarPresenterInput {

    // MARK: - Dependencies

    private let keyboardRouter: KeyboardRouterInput

    // MARK: - Init

    init(keyboardRouter: KeyboardRouterInput) {
        self.keyboardRouter = keyboardRouter
    }

    // MARK: - MenuBarPresenterInput

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
