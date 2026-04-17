import Foundation
import CoreGraphics

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
