import Testing
import Foundation
import Domain
@testable import Presentation

@Suite("DeepLink parsing")
struct DeepLinkParsingTests {
    @Test("parses the users list link")
    func parsesUsers() {
        #expect(DeepLink(url: URL(string: "mviexample://users")!) == .users)
    }

    @Test("parses a user link with a UUID")
    func parsesUser() {
        let id = UUID()
        #expect(DeepLink(url: URL(string: "mviexample://user/\(id.uuidString)")!) == .user(id))
    }

    @Test("parses the add-user link")
    func parsesAddUser() {
        #expect(DeepLink(url: URL(string: "mviexample://add-user")!) == .addUser)
    }

    @Test("rejects a foreign scheme, an unknown host, and a malformed id")
    func rejectsInvalid() {
        #expect(DeepLink(url: URL(string: "https://user/123")!) == nil)
        #expect(DeepLink(url: URL(string: "mviexample://unknown")!) == nil)
        #expect(DeepLink(url: URL(string: "mviexample://user/not-a-uuid")!) == nil)
    }
}

@Suite("DeepLinkCoordinator")
@MainActor
struct DeepLinkCoordinatorTests {
    private func makeSut(
        users: [User] = [],
        authenticated: Bool = true
    ) -> (DeepLinkCoordinator, AppRouter, SessionStore) {
        let router = AppRouter()
        let session = SessionStore()
        if authenticated { session.logIn() }
        let fetchUser = FakeFetchUserUseCase()
        fetchUser.usersByID = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
        let sut = DeepLinkCoordinator(routers: [router], session: session, fetchUser: fetchUser)
        return (sut, router, session)
    }

    @Test("a user link resolves the id and pushes the detail route")
    func userLinkPushesDetail() throws {
        let user = User(name: "Ada Lovelace", email: "ada@example.com")
        let (sut, router, _) = makeSut(users: [user])

        sut.open(.user(user.id))

        #expect(router.routes == [AnyRoute(UserDetailRoute(user: user))])
    }

    @Test("an add-user link presents the sheet")
    func addUserLinkPresentsSheet() {
        let (sut, router, _) = makeSut()

        sut.open(.addUser)

        #expect(router.presentedSheet == AnyRoute(AddUserRoute()))
    }

    @Test("a users link pops to root")
    func usersLinkPopsToRoot() {
        let (sut, router, _) = makeSut()
        router.send(.push(AddUserRoute()))

        sut.open(.users)

        #expect(router.path.isEmpty)
    }

    @Test("a link to an unknown id is a no-op")
    func unknownIdIsNoOp() {
        let (sut, router, _) = makeSut(users: [])

        sut.open(.user(UUID()))

        #expect(router.routes.isEmpty)
    }

    @Test("a link arriving while logged out is held and applied on login")
    func linkHeldUntilLogin() {
        let user = User(name: "Ada Lovelace", email: "ada@example.com")
        let (sut, router, session) = makeSut(users: [user], authenticated: false)

        sut.open(.user(user.id))
        #expect(router.routes.isEmpty)   // held, nothing navigated yet

        session.logIn()
        sut.resumePending()

        #expect(router.routes == [AnyRoute(UserDetailRoute(user: user))])
    }

    @Test("resumePending with nothing pending does nothing")
    func resumeWithoutPendingIsNoOp() {
        let (sut, router, _) = makeSut()

        sut.resumePending()

        #expect(router.routes.isEmpty)
        #expect(router.presentedSheet == nil)
    }
}
