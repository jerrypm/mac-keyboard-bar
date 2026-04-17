import XCTest
@testable import mac_keyboard_bar

final class LayoutTests: XCTestCase {

    func test_keyboardDefaults_arePositive() {
        XCTAssertGreaterThan(Layout.Keyboard.defaultWidth, 0)
        XCTAssertGreaterThan(Layout.Keyboard.defaultHeight, 0)
        XCTAssertGreaterThan(Layout.Keyboard.keyUnitSize, 0)
    }
}
