import ApplicationServices
import AppKit

protocol AccessibilityServicing {
    nonisolated var isTrusted: Bool { get }
    nonisolated func requestPermission()
    nonisolated func openSystemSettings()
}

/// `nonisolated` because AX APIs are thread-safe and this type holds no
/// shared mutable state. Opting out of the project-wide MainActor default
/// avoids a Swift runtime crash in `swift_task_deinitOnExecutorImpl` when the
/// service is deallocated off-main (e.g., in test teardown).
nonisolated final class AccessibilityService: AccessibilityServicing {

    // MARK: - AccessibilityServicing

    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: CFDictionary = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
