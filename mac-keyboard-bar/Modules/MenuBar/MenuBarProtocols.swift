import Foundation

protocol MenuBarPresenterInput: AnyObject {
    var isKeyboardVisible: Bool { get }
    func toggle()
    func quit()
}
