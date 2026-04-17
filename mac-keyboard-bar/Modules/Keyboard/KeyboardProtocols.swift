import Foundation
import CoreGraphics

// MARK: - View -> Presenter

protocol KeyboardPresenterInput: AnyObject {
    var modifiers: ModifierState { get }
    func handleKey(_ key: KeyDefinition)
}

// MARK: - Presenter -> Interactor

protocol KeyboardInteractorInput: AnyObject {
    var output: KeyboardInteractorOutput? { get set }
    func sendKey(keyCode: CGKeyCode, flags: CGEventFlags)
    var hasAccessibilityPermission: Bool { get }
    func requestAccessibilityPermission()
}

// MARK: - Interactor -> Presenter

protocol KeyboardInteractorOutput: AnyObject {
    func accessibilityPermissionDidChange(_ granted: Bool)
}

// MARK: - Presenter -> Router

protocol KeyboardRouterInput: AnyObject {
    func show()
    func hide()
    var isVisible: Bool { get }
    func presentAccessibilityAlert()
}
