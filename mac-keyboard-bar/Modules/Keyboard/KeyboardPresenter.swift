import CoreGraphics

/// `nonisolated` because this type holds only value-typed state and a
/// closure; it runs on whatever thread the caller uses. Opting out of the
/// project-wide MainActor default avoids a Swift runtime crash in
/// `swift_task_deinitOnExecutorImpl` when the presenter is deallocated
/// off-main (e.g., in test teardown).
nonisolated final class KeyboardPresenter: KeyboardPresenterInput {

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
