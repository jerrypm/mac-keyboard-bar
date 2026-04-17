import SwiftUI

struct KeyButtonView: View {

    // MARK: - Input

    let key: KeyDefinition
    let isActive: Bool
    let onTap: (KeyDefinition) -> Void

    // MARK: - Body

    var body: some View {
        Button {
            onTap(key)
        } label: {
            Text(key.label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .frame(
                    width: Layout.Keyboard.keyUnitSize * key.widthUnits
                        + Layout.Keyboard.keySpacing * (key.widthUnits - 1),
                    height: Layout.Keyboard.keyUnitSize
                )
                .background(background)
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isActive ? Color.accentColor.opacity(0.8) : Color.secondary.opacity(0.25))
    }
}
