import Cocoa

/// Nonactivating NSPanel that never becomes key or main, so injected
/// keystrokes reach the previously-focused app instead of the panel itself.
final class FloatingPanel: NSPanel {

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
