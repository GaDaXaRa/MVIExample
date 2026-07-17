import Testing
import Domain
@testable import Presentation

@Suite("User flows")
struct UserFlowsTests {
    @Test("BrowseUsersFlow pushes the detail and opens add-user as a sheet")
    func browseFlowRoutes() {
        let router = AppRouter()
        let sut = BrowseUsersFlow(router: router)
        let user = User(name: "Ada Lovelace", email: "ada@example.com")

        sut.didSelectUser(user)
        sut.didRequestAddUser()

        #expect(router.routes == [AnyRoute(UserDetailRoute(user: user))])
        #expect(router.presentedSheet == AnyRoute(AddUserRoute()))
    }

    @Test("QuickLookUsersFlow shows the same detail as a sheet instead of a push")
    func quickLookFlowPresentsDetailModally() {
        let router = AppRouter()
        let sut = QuickLookUsersFlow(router: router)
        let user = User(name: "Ada Lovelace", email: "ada@example.com")

        sut.didSelectUser(user)

        #expect(router.routes.isEmpty)
        #expect(router.presentedSheet == AnyRoute(UserDetailRoute(user: user)))
    }

    @Test("AddUserModalFlow dismisses on both finish and cancel")
    func addUserModalFlowDismisses() {
        let router = AppRouter()
        let sut = AddUserModalFlow(router: router)

        router.send(.sheet(AddUserRoute()))
        sut.didFinish()
        #expect(router.presentedSheet == nil)

        router.send(.sheet(AddUserRoute()))
        sut.didCancel()
        #expect(router.presentedSheet == nil)
    }
}
