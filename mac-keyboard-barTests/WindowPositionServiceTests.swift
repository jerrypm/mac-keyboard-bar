import XCTest
@testable import mac_keyboard_bar

final class WindowPositionServiceTests: XCTestCase {

    func test_saveAndLoad_returnsSameFrame() {
        let defaults = UserDefaults(suiteName: "test-\(UUID())")!
        let sut = WindowPositionService(defaults: defaults)
        let frame = CGRect(x: 100, y: 200, width: 720, height: 260)

        sut.save(frame: frame)

        XCTAssertEqual(sut.loadFrame(), frame)
    }

    func test_loadFrame_returnsNilWhenUnset() {
        let defaults = UserDefaults(suiteName: "test-\(UUID())")!
        let sut = WindowPositionService(defaults: defaults)

        XCTAssertNil(sut.loadFrame())
    }
}
