import Foundation

enum KeyboardBuilder {

    struct Module {
        let presenter: KeyboardPresenter
        let router: KeyboardRouter
        let windowController: KeyboardWindowController
    }

    static func build(
        accessibility: AccessibilityServicing = AccessibilityService(),
        injector: KeyInjecting = KeyInjectionService(),
        positionStore: WindowPositionStoring = WindowPositionService()
    ) -> Module {
        let interactor = KeyboardInteractor(injector: injector, accessibility: accessibility)
        let router = KeyboardRouter(accessibility: accessibility)
        let presenter = KeyboardPresenter(interactor: interactor, router: router)
        let controller = KeyboardWindowController(presenter: presenter, positionStore: positionStore)
        router.windowController = controller
        return Module(presenter: presenter, router: router, windowController: controller)
    }
}
