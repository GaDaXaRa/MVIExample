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

    @Test("RelatedUserFlow presents picker and related detail as sheets")
    func relatedUserFlowRoutes() {
        let router = AppRouter()
        let sut = RelatedUserFlow(router: router)
        let user = User(name: "Ada Lovelace", email: "ada@example.com")
        let related = User(name: "Alan Turing", email: "alan@example.com")

        sut.didRequestRelatedPicker(for: user)
        #expect(router.presentedSheet == AnyRoute(RelatedUserPickerRoute(target: user)))

        sut.didSelectRelated(related)
        #expect(router.presentedSheet == AnyRoute(UserDetailRoute(user: related)))
    }

    @Test("PickRelatedUserFlow assigns the selection and bubbles the dismiss")
    func pickRelatedFlowAssignsAndDismisses() {
        let parent = AppRouter()
        let target = User(name: "Ada Lovelace", email: "ada@example.com")
        parent.send(.sheet(RelatedUserPickerRoute(target: target)))
        let child = AppRouter(parent: parent)
        let setRelated = FakeSetRelatedUserUseCase()
        let sut = PickRelatedUserFlow(target: target, setRelated: setRelated, router: child)
        let picked = User(name: "Alan Turing", email: "alan@example.com")

        sut.didSelectUser(picked)

        #expect(target.related === picked)
        #expect(parent.presentedSheet == nil)
    }

    @Test("PickRelatedUserFlow surfaces a failed assignment as an alert and stays open")
    func pickRelatedFlowAlertsOnFailure() {
        let parent = AppRouter()
        let target = User(name: "Ada Lovelace", email: "ada@example.com")
        parent.send(.sheet(RelatedUserPickerRoute(target: target)))
        let child = AppRouter(parent: parent)
        let setRelated = FakeSetRelatedUserUseCase()
        setRelated.errorToThrow = UserRelationError.selfRelation
        let sut = PickRelatedUserFlow(target: target, setRelated: setRelated, router: child)

        sut.didSelectUser(target)

        #expect(child.presentedAlert != nil)
        #expect(parent.presentedSheet != nil)
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
