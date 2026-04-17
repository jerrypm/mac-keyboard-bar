import CoreGraphics

struct KeyboardLayout {

    let rows: [[KeyDefinition]]

    // MARK: - QWERTY

    static let qwerty = KeyboardLayout(rows: [
        // Row 0 — numbers
        [
            .init(label: "1", keyCode: 0x12),
            .init(label: "2", keyCode: 0x13),
            .init(label: "3", keyCode: 0x14),
            .init(label: "4", keyCode: 0x15),
            .init(label: "5", keyCode: 0x17),
            .init(label: "6", keyCode: 0x16),
            .init(label: "7", keyCode: 0x1A),
            .init(label: "8", keyCode: 0x1C),
            .init(label: "9", keyCode: 0x19),
            .init(label: "0", keyCode: 0x1D),
        ],
        // Row 1 — QWERTY
        [
            .init(label: "Q", keyCode: 0x0C),
            .init(label: "W", keyCode: 0x0D),
            .init(label: "E", keyCode: 0x0E),
            .init(label: "R", keyCode: 0x0F),
            .init(label: "T", keyCode: 0x11),
            .init(label: "Y", keyCode: 0x10),
            .init(label: "U", keyCode: 0x20),
            .init(label: "I", keyCode: 0x22),
            .init(label: "O", keyCode: 0x1F),
            .init(label: "P", keyCode: 0x23),
        ],
        // Row 2 — ASDF
        [
            .init(label: "A", keyCode: 0x00),
            .init(label: "S", keyCode: 0x01),
            .init(label: "D", keyCode: 0x02),
            .init(label: "F", keyCode: 0x03),
            .init(label: "G", keyCode: 0x05),
            .init(label: "H", keyCode: 0x04),
            .init(label: "J", keyCode: 0x26),
            .init(label: "K", keyCode: 0x28),
            .init(label: "L", keyCode: 0x25),
            .init(label: "⏎", keyCode: 0x24, widthUnits: 1.5),
        ],
        // Row 3 — ZXCV
        [
            .init(label: "⇧", keyCode: 0x38, kind: .modifier(.shift), widthUnits: 1.5),
            .init(label: "Z", keyCode: 0x06),
            .init(label: "X", keyCode: 0x07),
            .init(label: "C", keyCode: 0x08),
            .init(label: "V", keyCode: 0x09),
            .init(label: "B", keyCode: 0x0B),
            .init(label: "N", keyCode: 0x2D),
            .init(label: "M", keyCode: 0x2E),
            .init(label: ",", keyCode: 0x2B),
            .init(label: ".", keyCode: 0x2F),
            .init(label: "⌫", keyCode: 0x33),
        ],
        // Row 4 — modifiers + space
        [
            .init(label: "⌃", keyCode: 0x3B, kind: .modifier(.control)),
            .init(label: "⌥", keyCode: 0x3A, kind: .modifier(.option)),
            .init(label: "⌘", keyCode: 0x37, kind: .modifier(.command), widthUnits: 1.2),
            .init(label: "space", keyCode: 0x31, widthUnits: 4),
            .init(label: "⌘", keyCode: 0x36, kind: .modifier(.command), widthUnits: 1.2),
            .init(label: "←", keyCode: 0x7B),
            .init(label: "↓", keyCode: 0x7D),
            .init(label: "↑", keyCode: 0x7E),
            .init(label: "→", keyCode: 0x7C),
        ],
    ])
}
