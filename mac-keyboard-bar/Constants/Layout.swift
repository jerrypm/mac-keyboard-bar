import CoreGraphics

/// `nonisolated` so `nonisolated` services can read immutable layout constants
/// without a main-actor hop.
nonisolated enum Layout {

    // MARK: - Keyboard

    enum Keyboard {
        static let defaultWidth: CGFloat = 720
        static let defaultHeight: CGFloat = 260
        static let keyUnitSize: CGFloat = 44
        static let keySpacing: CGFloat = 4
        static let rowSpacing: CGFloat = 6
        static let contentPadding: CGFloat = 10
        static let cornerRadius: CGFloat = 14
    }

    // MARK: - MenuBar

    enum MenuBar {
        static let iconSize: CGFloat = 18
    }
}
