import ApplicationServices
import AppKit

protocol AccessibilityServicing {
    var isTrusted: Bool { get }
    func requestPermission()
    func openSystemSettings()
}

final class AccessibilityService: AccessibilityServicing {

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
