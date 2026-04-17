import XCTest
@testable import mac_keyboard_bar

final class WindowPositionServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makeDefaults() -> (UserDefaults, String) {
        let suiteName = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return (defaults, suiteName)
    }

    private func cleanup(_ defaults: UserDefaults, _ suiteName: String) {
        defaults.removePersistentDomain(forName: suiteName)
    }

    // MARK: - Roundtrip

    func test_saveAndLoad_returnsSameFrame() {
        let (defaults, suiteName) = makeDefaults()
        defer { cleanup(defaults, suiteName) }
        let sut = WindowPositionService(defaults: defaults)
        let frame = CGRect(x: 100, y: 200, width: 720, height: 260)

        sut.save(frame: frame)

        XCTAssertEqual(sut.loadFrame(), frame)
    }

    func test_loadFrame_returnsNilWhenUnset() {
        let (defaults, suiteName) = makeDefaults()
        defer { cleanup(defaults, suiteName) }
        let sut = WindowPositionService(defaults: defaults)

        XCTAssertNil(sut.loadFrame())
    }

    // MARK: - Overwrite

    func test_save_overwritesPreviousFrame() {
        let (defaults, suiteName) = makeDefaults()
        defer { cleanup(defaults, suiteName) }
        let sut = WindowPositionService(defaults: defaults)
        let frameA = CGRect(x: 10, y: 20, width: 720, height: 260)
        let frameB = CGRect(x: 300, y: 400, width: 800, height: 300)

        sut.save(frame: frameA)
        sut.save(frame: frameB)

        XCTAssertEqual(sut.loadFrame(), frameB)
    }

    // MARK: - Persistence Across Instances

    func test_loadFrame_persistsAcrossInstances() {
        let (defaults, suiteName) = makeDefaults()
        defer { cleanup(defaults, suiteName) }
        let frame = CGRect(x: 150, y: 250, width: 720, height: 260)

        let writer = WindowPositionService(defaults: defaults)
        writer.save(frame: frame)

        let reader = WindowPositionService(defaults: defaults)
        XCTAssertEqual(reader.loadFrame(), frame)
    }

    // MARK: - Negative Origin

    func test_saveAndLoad_handlesNegativeOrigin() {
        let (defaults, suiteName) = makeDefaults()
        defer { cleanup(defaults, suiteName) }
        let sut = WindowPositionService(defaults: defaults)
        let frame = CGRect(x: -200, y: 150, width: 720, height: 260)

        sut.save(frame: frame)

        XCTAssertEqual(sut.loadFrame(), frame)
    }
}
