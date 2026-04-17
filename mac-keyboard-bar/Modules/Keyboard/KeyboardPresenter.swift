import CoreGraphics

final class KeyboardPresenter: KeyboardPresenterInput {

    // MARK: - Dependencies

    private let interactor: KeyboardInteractorInput
    private let router: KeyboardRouterInput

    // MARK: - State

    private(set) var modifiers = ModifierState()

    /// Notifies observer (KeyboardWindowController -> SwiftUI binding) after state change.
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
