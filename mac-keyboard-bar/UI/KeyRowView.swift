import SwiftUI

struct KeyRowView: View {

    // MARK: - Input

    let keys: [KeyDefinition]
    let activeModifiers: ModifierState
    let onTap: (KeyDefinition) -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: Layout.Keyboard.keySpacing) {
            ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                KeyButtonView(key: key, isActive: isActive(key), onTap: onTap)
            }
        }
    }

    // MARK: - Helpers

    private func isActive(_ key: KeyDefinition) -> Bool {
        guard case .modifier(let mod) = key.kind else { return false }
        return activeModifiers.isActive(mod)
    }
}
