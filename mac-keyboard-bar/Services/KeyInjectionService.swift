import CoreGraphics

protocol KeyInjecting {
    func inject(keyCode: CGKeyCode, flags: CGEventFlags)
}

nonisolated final class KeyInjectionService: KeyInjecting {

    // MARK: - Types

    typealias EventPoster = (CGEvent?) -> Void

    // MARK: - Properties

    private let source = CGEventSource(stateID: .hidSystemState)
    private let poster: EventPoster

    // MARK: - Init

    init(poster: EventPoster? = nil) {
        self.poster = poster ?? { event in
            event?.post(tap: .cghidEventTap)
        }
    }

    // MARK: - KeyInjecting

    func inject(keyCode: CGKeyCode, flags: CGEventFlags) {
        let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        down?.flags = flags
        poster(down)

        let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        up?.flags = flags
        poster(up)
    }
}
