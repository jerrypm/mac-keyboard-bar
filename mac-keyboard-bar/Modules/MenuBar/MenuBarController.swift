import Cocoa

final class MenuBarController {

    // MARK: - Properties

    private var statusItem: NSStatusItem!
    private let presenter: MenuBarPresenterInput

    // MARK: - Init

    init(presenter: MenuBarPresenterInput) {
        self.presenter = presenter
        setupStatusItem()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: Strings.MenuBar.iconSymbol,
                                   accessibilityDescription: Strings.MenuBar.iconAccessibility)
            button.image?.size = NSSize(width: Layout.MenuBar.iconSize, height: Layout.MenuBar.iconSize)
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    // MARK: - Actions

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showMenu()
        } else {
            presenter.toggle()
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        let toggle = NSMenuItem(
            title: presenter.isKeyboardVisible ? Strings.MenuBar.hide : Strings.MenuBar.show,
            action: #selector(togglePanel),
            keyEquivalent: Strings.empty
        )
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: Strings.App.quit, action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func togglePanel() { presenter.toggle() }
    @objc private func quitApp()    { presenter.quit() }
}
