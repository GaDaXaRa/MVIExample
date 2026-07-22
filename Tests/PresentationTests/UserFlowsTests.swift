import Testing
import Wireframe
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

    @Test("RelatedUserFlow opens the list when there are relations, the editor when there are none")
    func relatedUserFlowOpensListOrEditor() {
        let withRelations = User(name: "Ada Lovelace", email: "ada@example.com")
        withRelations.related = [User(name: "Alan Turing", email: "alan@example.com")]
        let router1 = AppRouter()
        RelatedUserFlow(router: router1).didRequestManageRelated(for: withRelations)
        #expect(router1.presentedSheet == AnyRoute(ManageRelatedRoute(target: withRelations)))

        let noRelations = User(name: "Grace Hopper", email: "grace@example.com")
        let router2 = AppRouter()
        RelatedUserFlow(router: router2).didRequestManageRelated(for: noRelations)
        #expect(router2.presentedSheet == AnyRoute(SelectRelatedRoute(target: noRelations)))
    }

    @Test("RelatedListFlow opens the editor on add, inspects a related user, and dismisses")
    func relatedListFlowRoutes() {
        let target = User(name: "Ada Lovelace", email: "ada@example.com")
        let related = User(name: "Alan Turing", email: "alan@example.com")
        let router = AppRouter()
        let sut = RelatedListFlow(target: target, router: router)

        sut.didRequestAddUser()
        #expect(router.presentedSheet == AnyRoute(SelectRelatedRoute(target: target)))

        sut.didSelectUser(related)
        #expect(router.presentedSheet == AnyRoute(UserDetailRoute(user: related)))
    }

    @Test("SelectRelatedModalFlow's finish bubbles the dismiss to the presenting wireframe")
    func selectRelatedFlowDismissBubbles() {
        let parent = AppRouter()
        let target = User(name: "Ada Lovelace", email: "ada@example.com")
        parent.send(.sheet(SelectRelatedRoute(target: target)))
        let child = AppRouter(parent: parent)
        let sut = SelectRelatedModalFlow(router: child)

        sut.didFinish()

        #expect(parent.presentedSheet == nil)
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
