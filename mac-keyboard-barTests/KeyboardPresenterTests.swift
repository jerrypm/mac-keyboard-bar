import XCTest
import CoreGraphics
@testable import mac_keyboard_bar

final class KeyboardPresenterTests: XCTestCase {

    // MARK: - Test Doubles

    final class FakeInteractor: KeyboardInteractorInput {
        weak var output: KeyboardInteractorOutput?
        var calls: [(CGKeyCode, CGEventFlags)] = []
        var trusted = true
        var hasAccessibilityPermission: Bool { trusted }
        func requestAccessibilityPermission() {}
        func sendKey(keyCode: CGKeyCode, flags: CGEventFlags) {
            calls.append((keyCode, flags))
        }
    }

    final class FakeRouter: KeyboardRouterInput {
        var shown = false
        var alertShown = false
        var isVisible: Bool { shown }
        func show() { shown = true }
        func hide() { shown = false }
        func presentAccessibilityAlert() { alertShown = true }
    }

    // MARK: - Helpers

    private func makeSUT(
        interactor: FakeInteractor = FakeInteractor(),
        router: FakeRouter = FakeRouter()
    ) -> KeyboardPresenter {
        KeyboardPresenter(interactor: interactor, router: router)
    }

    // MARK: - Tests

    func test_handleKey_modifier_togglesState() {
        let interactor = FakeInteractor()
        let router = FakeRouter()
        let sut = makeSUT(interactor: interactor, router: router)

        let shiftKey = KeyDefinition(
            label: "shift",
            keyCode: 0x38,
            kind: .modifier(.shift)
        )

        sut.handleKey(shiftKey)

        XCTAssertTrue(sut.modifiers.shift)
    }

    func test_handleKey_character_sendsKeyAndClearsModifiers() {
        let interactor = FakeInteractor()
        let router = FakeRouter()
        let sut = makeSUT(interactor: interactor, router: router)

        let shiftKey = KeyDefinition(
            label: "shift",
            keyCode: 0x38,
            kind: .modifier(.shift)
        )
        let aKey = KeyDefinition(
            label: "A",
            keyCode: 0x00,
            kind: .character
        )

        sut.handleKey(shiftKey)
        sut.handleKey(aKey)

        XCTAssertEqual(interactor.calls.count, 1)
        XCTAssertTrue(interactor.calls[0].1.contains(.maskShift))
        XCTAssertFalse(sut.modifiers.shift)
    }

    func test_handleKey_character_noPermission_presentsAlert() {
        let interactor = FakeInteractor()
        interactor.trusted = false
        let router = FakeRouter()
        let sut = makeSUT(interactor: interactor, router: router)

        let aKey = KeyDefinition(
            label: "A",
            keyCode: 0x00,
            kind: .character
        )

        sut.handleKey(aKey)

        XCTAssertTrue(router.alertShown)
        XCTAssertEqual(interactor.calls.count, 0)
    }
}
