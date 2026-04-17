import XCTest
import CoreGraphics
@testable import mac_keyboard_bar

final class KeyboardInteractorTests: XCTestCase {

    // MARK: - Test Doubles

    nonisolated final class SpyInjector: KeyInjecting {
        var calls: [(CGKeyCode, CGEventFlags)] = []
        func inject(keyCode: CGKeyCode, flags: CGEventFlags) {
            calls.append((keyCode, flags))
        }
    }

    nonisolated final class StubAccessibility: AccessibilityServicing {
        var isTrusted = true
        func requestPermission() {}
        func openSystemSettings() {}
    }

    // MARK: - Tests

    func test_sendKey_delegatesToInjector() {
        let injector = SpyInjector()
        let sut = KeyboardInteractor(injector: injector, accessibility: StubAccessibility())

        sut.sendKey(keyCode: 0x00, flags: [.maskShift])

        XCTAssertEqual(injector.calls.count, 1)
        XCTAssertEqual(injector.calls[0].0, 0x00)
        XCTAssertTrue(injector.calls[0].1.contains(.maskShift))
    }

    func test_hasAccessibilityPermission_reflectsService() {
        let access = StubAccessibility()
        access.isTrusted = false
        let sut = KeyboardInteractor(injector: SpyInjector(), accessibility: access)
        XCTAssertFalse(sut.hasAccessibilityPermission)
    }
}
