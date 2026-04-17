import Cocoa
import SwiftUI

final class KeyboardWindowController {

    // MARK: - Properties

    private let panel: FloatingPanel
    private let presenter: KeyboardPresenter
    private let positionStore: WindowPositionStoring
    private var hostingView: NSHostingView<AnyView>?

    // MARK: - Init

    init(presenter: KeyboardPresenter, positionStore: WindowPositionStoring) {
        self.presenter = presenter
        self.positionStore = positionStore

        let frame = positionStore.loadFrame() ?? Self.defaultFrame()
        panel = FloatingPanel(
            contentRect: frame,
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        configurePanel()
        installHostingView()
        observePresenter()
        observeFrameChanges()
    }

    // MARK: - API

    func show() {
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    var isVisible: Bool { panel.isVisible }

    // MARK: - Setup

    private func configurePanel() {
        panel.title = Strings.Keyboard.title
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
    }

    private func installHostingView() {
        let root = AnyView(
            KeyboardView(
                layout: .qwerty,
                modifiers: Binding(
                    get: { [unowned self] in self.presenter.modifiers },
                    set: { _ in }
                ),
                onKey: { [weak presenter] key in
                    presenter?.handleKey(key)
                }
            )
        )
        let host = NSHostingView(rootView: root)
        host.frame = panel.contentView?.bounds ?? .zero
        host.autoresizingMask = [.width, .height]
        panel.contentView = host
        hostingView = host
    }

    private func observePresenter() {
        presenter.onStateChange = { [weak self] in
            self?.reinstallRootView()
        }
    }

    private func reinstallRootView() {
        installHostingView()
    }

    private func observeFrameChanges() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.positionStore.save(frame: self.panel.frame)
        }
    }

    // MARK: - Defaults

    private static func defaultFrame() -> CGRect {
        guard let screen = NSScreen.main else {
            return CGRect(x: 100, y: 100, width: Layout.Keyboard.defaultWidth, height: Layout.Keyboard.defaultHeight)
        }
        let width = Layout.Keyboard.defaultWidth
        let height = Layout.Keyboard.defaultHeight
        let x = screen.visibleFrame.midX - width / 2
        let y = screen.visibleFrame.minY + 80
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
