import XCTest
@testable import mac_keyboard_bar

final class KeyboardLayoutTests: XCTestCase {

    func test_qwertyLayout_hasFiveRows() {
        XCTAssertEqual(KeyboardLayout.qwerty.rows.count, 5)
    }

    func test_qwertyLayout_numberRowHasTenKeys() {
        let row = KeyboardLayout.qwerty.rows[0]
        XCTAssertEqual(row.count, 10)
        XCTAssertEqual(row.first?.label, "1")
    }

    func test_keyDefinition_modifierFlagIsSet() {
        let shift = KeyDefinition(label: "⇧", keyCode: 0x38, kind: .modifier(.shift))
        if case .modifier(let mod) = shift.kind {
            XCTAssertEqual(mod, .shift)
        } else {
            XCTFail("expected modifier")
        }
    }
}
