import Testing
import SwiftUI
@testable import Presentation

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
        #expect(sut.routes == [AnyHashable(TestRoute(id: 1)), AnyHashable(TestRoute(id: 2))])
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
        #expect(sut.routes == [AnyHashable(TestRoute(id: 1)), AnyHashable(TestRoute(id: 2))])
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

        #expect(sut.routes == [AnyHashable(TestRoute(id: 1))])
    }

    @Test("present and dismissSheet drive the sheet state")
    func sheetLifecycle() {
        let sut = AppRouter()

        sut.send(.present(.addUser))
        #expect(sut.presentedSheet?.id == Sheet.addUser.id)

        sut.send(.dismissSheet)
        #expect(sut.presentedSheet == nil)
    }
}
