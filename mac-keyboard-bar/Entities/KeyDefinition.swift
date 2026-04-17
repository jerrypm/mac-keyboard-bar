import CoreGraphics

struct KeyDefinition: Equatable {

    // MARK: - Kind

    enum Kind: Equatable {
        case character
        case modifier(ModifierState.Key)
        case toggle
    }

    // MARK: - Properties

    let label: String
    let keyCode: CGKeyCode
    let kind: Kind
    let widthUnits: CGFloat

    // MARK: - Init

    init(label: String, keyCode: CGKeyCode, kind: Kind = .character, widthUnits: CGFloat = 1) {
        self.label = label
        self.keyCode = keyCode
        self.kind = kind
        self.widthUnits = widthUnits
    }
}
