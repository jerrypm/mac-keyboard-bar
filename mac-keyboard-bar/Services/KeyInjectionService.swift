import CoreGraphics

protocol KeyInjecting {
    nonisolated func inject(keyCode: CGKeyCode, flags: CGEventFlags)
}

/// `nonisolated` because CGEvent APIs are thread-safe and this type holds no
/// shared mutable state. Opting out of the project-wide MainActor default also
/// avoids a Swift runtime crash in `swift_task_deinitOnExecutorImpl` when the
/// service is deallocated off-main (e.g., in test teardown).
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
