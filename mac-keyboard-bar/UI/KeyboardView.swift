import SwiftUI

struct KeyboardView: View {

    // MARK: - Input

    let layout: KeyboardLayout
    @Binding var modifiers: ModifierState
    let onKey: (KeyDefinition) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: Layout.Keyboard.rowSpacing) {
            ForEach(Array(layout.rows.enumerated()), id: \.offset) { _, row in
                KeyRowView(keys: row, activeModifiers: modifiers, onTap: onKey)
            }
        }
        .padding(Layout.Keyboard.contentPadding)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Layout.Keyboard.cornerRadius))
    }
}
