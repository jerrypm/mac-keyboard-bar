import XCTest
import CoreGraphics
@testable import mac_keyboard_bar

final class KeyInjectionServiceTests: XCTestCase {

    func test_inject_postsDownThenUp() {
        var posted: [(CGKeyCode, Bool)] = []
        let sut = KeyInjectionService { event in
            guard let e = event else { return }
            let keyCode = CGKeyCode(e.getIntegerValueField(.keyboardEventKeycode))
            let isDown = e.type == .keyDown
            posted.append((keyCode, isDown))
        }

        sut.inject(keyCode: 0x00, flags: [])

        XCTAssertEqual(posted.count, 2)
        XCTAssertEqual(posted[0].0, 0x00)
        XCTAssertTrue(posted[0].1)
        XCTAssertEqual(posted[1].0, 0x00)
        XCTAssertFalse(posted[1].1)
    }

    func test_inject_appliesFlags() {
        var capturedFlags: CGEventFlags = []
        let sut = KeyInjectionService { event in
            if event?.type == .keyDown { capturedFlags = event?.flags ?? [] }
        }

        sut.inject(keyCode: 0x00, flags: [.maskShift, .maskCommand])

        XCTAssertTrue(capturedFlags.contains(.maskShift))
        XCTAssertTrue(capturedFlags.contains(.maskCommand))
    }
}
