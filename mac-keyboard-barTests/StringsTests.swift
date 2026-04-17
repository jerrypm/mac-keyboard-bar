import XCTest
@testable import mac_keyboard_bar

final class StringsTests: XCTestCase {

    func test_appStrings_areNonEmpty() {
        XCTAssertFalse(Strings.App.name.isEmpty)
        XCTAssertFalse(Strings.App.quit.isEmpty)
    }

    func test_accessibilityStrings_hasPermissionTitle() {
        XCTAssertFalse(Strings.Accessibility.permissionTitle.isEmpty)
        XCTAssertFalse(Strings.Accessibility.permissionMessage.isEmpty)
    }
}
