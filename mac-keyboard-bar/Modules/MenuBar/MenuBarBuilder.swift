import Foundation

enum MenuBarBuilder {

    struct Module {
        let presenter: MenuBarPresenter
        let controller: MenuBarController
    }

    static func build(keyboardRouter: KeyboardRouterInput) -> Module {
        let presenter = MenuBarPresenter(keyboardRouter: keyboardRouter)
        let controller = MenuBarController(presenter: presenter)
        return Module(presenter: presenter, controller: controller)
    }
}
