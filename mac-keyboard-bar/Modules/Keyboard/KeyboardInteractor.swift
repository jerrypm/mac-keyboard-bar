import CoreGraphics

/// `nonisolated` because this type only bridges to thread-safe services and
/// holds no UI state. Opting out of the project-wide MainActor default avoids
/// a Swift runtime crash in `swift_task_deinitOnExecutorImpl` when the
/// interactor is deallocated off-main (e.g., in test teardown).
nonisolated final class KeyboardInteractor: KeyboardInteractorInput {

    // MARK: - Output

    weak var output: KeyboardInteractorOutput?

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
