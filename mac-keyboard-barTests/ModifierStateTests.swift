import XCTest
@testable import mac_keyboard_bar

final class ModifierStateTests: XCTestCase {

    func test_default_allFalse() {
        let s = ModifierState()
        XCTAssertFalse(s.shift)
        XCTAssertFalse(s.command)
        XCTAssertFalse(s.option)
        XCTAssertFalse(s.control)
        XCTAssertFalse(s.fn)
    }

    func test_isActive_returnsFieldValue() {
        var s = ModifierState()
        XCTAssertFalse(s.isActive(.command))
        s.command = true
        XCTAssertTrue(s.isActive(.command))
        XCTAssertFalse(s.isActive(.shift))
    }

    func test_toggle_flipsFlag() {
        var s = ModifierState()
        s.toggle(.shift)
        XCTAssertTrue(s.shift)
        s.toggle(.shift)
        XCTAssertFalse(s.shift)
    }

    func test_cgEventFlags_reflectsActiveModifiers() {
        var s = ModifierState()
        s.shift = true
        s.command = true
        let flags = s.cgEventFlags
        XCTAssertTrue(flags.contains(.maskShift))
        XCTAssertTrue(flags.contains(.maskCommand))
        XCTAssertFalse(flags.contains(.maskAlternate))
    }

    func test_clearOneShot_clearsNonStickyModifiers() {
        var s = ModifierState()
        s.shift = true
        s.command = true
        s.clearOneShot()
        XCTAssertFalse(s.shift)
        XCTAssertFalse(s.command)
    }
}
