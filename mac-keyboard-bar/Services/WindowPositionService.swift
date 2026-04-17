import AppKit

protocol WindowPositionStoring {
    nonisolated func loadFrame() -> CGRect?
    nonisolated func save(frame: CGRect)
}

/// `nonisolated` to opt out of the project-wide MainActor default; this is a
/// thin UserDefaults wrapper with no shared mutable state and is safely
/// callable from any actor.
nonisolated final class WindowPositionService: WindowPositionStoring {

    // MARK: - Properties

    private let defaults: UserDefaults
    private let key = Strings.Defaults.windowFrameKey

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - WindowPositionStoring

    func loadFrame() -> CGRect? {
        guard let string = defaults.string(forKey: key) else { return nil }
        let rect = NSRectFromString(string)
        return rect == .zero ? nil : rect
    }

    func save(frame: CGRect) {
        defaults.set(NSStringFromRect(frame), forKey: key)
    }
}
