import Testing
import Domain
@testable import Presentation

@Suite("User flows")
struct UserFlowsTests {
    @Test("BrowseUsersFlow pushes the detail, sheets add-user and covers with the picker")
    func browseFlowRoutes() {
        let router = AppRouter()
        let sut = BrowseUsersFlow(router: router, session: SessionStore())
        let user = User(name: "Ada Lovelace", email: "ada@example.com")

        sut.didSelectUser(user)
        sut.didRequestAddUser()
        sut.didRequestUserPicker()

        #expect(router.routes == [AnyRoute(UserDetailRoute(user: user))])
        #expect(router.presentedSheet == AnyRoute(AddUserRoute()))
        #expect(router.presentedCover == AnyRoute(UserPickerRoute()))
    }

    @Test("BrowseUsersFlow ends the session on request")
    func browseFlowEndsSession() {
        let session = SessionStore()
        session.logIn()
        let sut = BrowseUsersFlow(router: AppRouter(), session: session)

        sut.didRequestEndSession()

        #expect(session.isAuthenticated == false)
    }

    @Test("PickUserFlow alerts the selected user's data instead of navigating")
    func pickFlowAlertsSelection() {
        let router = AppRouter()
        let sut = PickUserFlow(router: router)
        let user = User(name: "Ada Lovelace", email: "ada@example.com")

        sut.didSelectUser(user)

        #expect(router.routes.isEmpty)
        #expect(router.presentedAlert == AlertContent(title: "Ada Lovelace", message: "ada@example.com"))
    }

    @Test("PickUserFlow's cancel bubbles the dismiss to the presenting wireframe")
    func pickFlowCancelBubbles() {
        let parent = AppRouter()
        parent.send(.present(UserPickerRoute()))
        let child = AppRouter(parent: parent)
        let sut = PickUserFlow(router: child)

        sut.didCancel()

        #expect(parent.presentedCover == nil)
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

    @Test("SessionLoginFlow starts the session")
    func loginFlowStartsSession() {
        let session = SessionStore()
        let sut = SessionLoginFlow(session: session)

        sut.didLogIn()

        #expect(session.isAuthenticated == true)
    }
}

@Suite("LoginStore")
struct LoginStoreTests {
    @Test("tapping log in reports it to the flow")
    func logInReportsToFlow() {
        let flow = LoginFlowSpy()
        let sut = LoginStore(flow: flow)

        sut.send(.logInTapped)

        #expect(flow.logIns == 1)
    }
}
