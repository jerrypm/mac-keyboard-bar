import XCTest
import CoreGraphics
@testable import mac_keyboard_bar

final class KeyboardInteractorTests: XCTestCase {

    // MARK: - Test Doubles

    /// `nonisolated` matches `KeyInjecting` protocol requirement.
    /// Captured calls are stored in a `SendableBox` to avoid crossing
    /// actor isolation boundaries from the `nonisolated inject` method.
    nonisolated final class SpyInjector: KeyInjecting {
        final class SendableBox: @unchecked Sendable {
            var calls: [(CGKeyCode, CGEventFlags)] = []
        }
        let box = SendableBox()
        func inject(keyCode: CGKeyCode, flags: CGEventFlags) {
            box.calls.append((keyCode, flags))
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

        XCTAssertEqual(injector.box.calls.count, 1)
        XCTAssertEqual(injector.box.calls[0].0, 0x00)
        XCTAssertTrue(injector.box.calls[0].1.contains(.maskShift))
    }

    func test_hasAccessibilityPermission_reflectsService() {
        let access = StubAccessibility()
        access.isTrusted = false
        let sut = KeyboardInteractor(injector: SpyInjector(), accessibility: access)
        XCTAssertFalse(sut.hasAccessibilityPermission)
    }
}
