import Testing
import SwiftUI
@testable import Wireframe

private nonisolated struct TestRoute: Route {
    let id: Int
}

@Suite("AppRouter")
struct AppRouterTests {
    @Test("push appends to both the path and the routes mirror")
    func pushAppends() {
        let sut = AppRouter()

        sut.send(.push(TestRoute(id: 1)))
        sut.send(.push(TestRoute(id: 2)))

        #expect(sut.path.count == 2)
        #expect(sut.routes == [AnyRoute(TestRoute(id: 1)), AnyRoute(TestRoute(id: 2))])
    }

    @Test("pop removes the last route; popping an empty stack is a no-op")
    func popRemovesLast() {
        let sut = AppRouter()
        sut.send(.push(TestRoute(id: 1)))

        sut.send(.pop)
        sut.send(.pop)

        #expect(sut.path.count == 0)
        #expect(sut.routes.isEmpty)
    }

    @Test("popToRoot clears the whole stack")
    func popToRootClears() {
        let sut = AppRouter()
        sut.send(.push(TestRoute(id: 1)))
        sut.send(.push(TestRoute(id: 2)))

        sut.send(.popToRoot)

        #expect(sut.path.count == 0)
        #expect(sut.routes.isEmpty)
    }

    @Test("popTo pops everything above the target route, keeping the target")
    func popToKeepsTarget() {
        let sut = AppRouter()
        sut.send(.push(TestRoute(id: 1)))
        sut.send(.push(TestRoute(id: 2)))
        sut.send(.push(TestRoute(id: 3)))

        sut.send(.popTo(TestRoute(id: 2)))

        #expect(sut.path.count == 2)
        #expect(sut.routes == [AnyRoute(TestRoute(id: 1)), AnyRoute(TestRoute(id: 2))])
    }

    @Test("popTo an unknown route is a no-op")
    func popToUnknownRouteDoesNothing() {
        let sut = AppRouter()
        sut.send(.push(TestRoute(id: 1)))

        sut.send(.popTo(TestRoute(id: 99)))

        #expect(sut.path.count == 1)
    }

    @Test("an interactive pop (back button mutating the path binding) keeps the mirror in sync")
    func interactivePopSyncsMirror() {
        let sut = AppRouter()
        sut.send(.push(TestRoute(id: 1)))
        sut.send(.push(TestRoute(id: 2)))

        sut.path.removeLast() // what NavigationStack does on back/swipe

        #expect(sut.routes == [AnyRoute(TestRoute(id: 1))])
    }

    @Test("the same route can be pushed, shown as a sheet or as a cover")
    func sameRouteAnyPresentation() {
        let sut = AppRouter()
        let route = TestRoute(id: 1)

        sut.send(.push(route))
        sut.send(.sheet(route))
        sut.send(.present(route))

        #expect(sut.routes == [AnyRoute(route)])
        #expect(sut.presentedSheet == AnyRoute(route))
        #expect(sut.presentedCover == AnyRoute(route))
    }

    @Test("dismiss clears whichever modal is presented")
    func dismissClearsModals() {
        let sut = AppRouter()
        sut.send(.sheet(TestRoute(id: 1)))
        sut.send(.present(TestRoute(id: 2)))

        sut.send(.dismiss)

        #expect(sut.presentedSheet == nil)
        #expect(sut.presentedCover == nil)
    }

    @Test("dismiss bubbles to the parent when this wireframe presented nothing")
    func dismissBubblesToParent() {
        let parent = AppRouter()
        parent.send(.sheet(TestRoute(id: 1)))
        let sut = AppRouter(parent: parent)

        sut.send(.dismiss)

        #expect(parent.presentedSheet == nil)
    }

    @Test("a child's own modal is dismissed before bubbling")
    func childDismissesOwnModalFirst() {
        let parent = AppRouter()
        parent.send(.sheet(TestRoute(id: 1)))
        let sut = AppRouter(parent: parent)
        sut.send(.sheet(TestRoute(id: 2)))

        sut.send(.dismiss)

        #expect(sut.presentedSheet == nil)
        #expect(parent.presentedSheet == AnyRoute(TestRoute(id: 1)))
    }

    @Test("alert intent drives the alert state and its derived binding")
    func alertLifecycle() {
        let sut = AppRouter()

        sut.send(.alert(AlertContent(title: "Ada", message: "ada@example.com")))
        #expect(sut.presentedAlert == AlertContent(title: "Ada", message: "ada@example.com"))
        #expect(sut.isAlertPresented == true)

        sut.isAlertPresented = false // what the .alert modifier does on OK
        #expect(sut.presentedAlert == nil)
    }
}
