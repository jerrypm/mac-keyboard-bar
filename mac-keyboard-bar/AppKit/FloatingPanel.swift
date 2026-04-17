import Cocoa

/// Nonactivating NSPanel that can become key without stealing focus
/// from the frontmost app — required so injected keystrokes reach the
/// previously-focused app instead of the keyboard panel itself.
final class FloatingPanel: NSPanel {

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
