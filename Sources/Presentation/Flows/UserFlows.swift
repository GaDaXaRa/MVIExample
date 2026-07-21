import Domain

// Concrete navigation policies. A flow is allowed to know several features —
// knitting screens together is precisely its job; the features themselves
// never know each other. The composition root decides which flow each screen
// gets, so the same feature can navigate differently in different contexts.

/// Browsing context (the tabs): selecting a user pushes its detail, adding
/// opens a sheet, and the user picker covers the tab fullscreen — a cover has
/// no swipe-to-dismiss, so it can only be closed through its Cancel button.
public struct BrowseUsersFlow: UserListFlow {
    private let router: any Router
    private let session: SessionStore

    public init(router: any Router, session: SessionStore) {
        self.router = router
        self.session = session
    }

    public func didSelectUser(_ user: User) {
        router.send(.push(UserDetailRoute(user: user)))
    }

    public func didRequestAddUser() {
        router.send(.sheet(AddUserRoute()))
    }

    public func didRequestUserPicker() {
        router.send(.present(UserPickerRoute()))
    }

    public func didRequestEndSession() {
        session.expire()
    }
}

/// Picker context (the modal): the *same* list feature, but selecting a user
/// shows its data in an alert instead of navigating anywhere, and Cancel
/// closes the modal. Injected with the modal's own child router, so both the
/// alert and the dismissal happen in the modal's context.
public struct PickUserFlow: UserListFlow {
    private let router: any Router

    public init(router: any Router) {
        self.router = router
    }

    public func didSelectUser(_ user: User) {
        router.send(.alert(AlertContent(title: user.name, message: user.email)))
    }

    public func didCancel() {
        router.send(.dismiss)
    }
}

/// Detail-screen context: picking a related user and inspecting the current
/// one both happen in sheets over wherever the detail lives — a tab stack or
/// another modal; the child-wireframe chain makes that irrelevant here.
public struct RelatedUserFlow: UserDetailFlow {
    private let router: any Router

    public init(router: any Router) {
        self.router = router
    }

    public func didRequestRelatedPicker(for user: User) {
        router.send(.sheet(RelatedUserPickerRoute(target: user)))
    }

    public func didSelectRelated(_ user: User) {
        router.send(.sheet(UserDetailRoute(user: user)))
    }
}

/// The modal that *returns* a value: selecting a user assigns it as the
/// target's related user and dismisses; the detail screen needs no callback,
/// because the `@Model` relationship is observable. A business-rule failure
/// (self-relation) surfaces as a wireframe alert instead of dismissing.
public struct PickRelatedUserFlow: UserListFlow {
    private let target: User
    private let setRelated: SetRelatedUserUseCase
    private let router: any Router

    public init(target: User, setRelated: SetRelatedUserUseCase, router: any Router) {
        self.target = target
        self.setRelated = setRelated
        self.router = router
    }

    public func didSelectUser(_ user: User) {
        do {
            try setRelated.execute(user: target, related: user)
            router.send(.dismiss)
        } catch {
            router.send(.alert(AlertContent(title: "Cannot relate", message: error.localizedDescription)))
        }
    }

    public func didCancel() {
        router.send(.dismiss)
    }
}

/// The add-user form is presented modally in this app, so both outcomes
/// dismiss it. Another context could pop, or chain a confirmation screen.
public struct AddUserModalFlow: AddUserFlow {
    private let router: any Router

    public init(router: any Router) {
        self.router = router
    }

    public func didFinish() {
        router.send(.dismiss)
    }

    public func didCancel() {
        router.send(.dismiss)
    }
}

/// Logging in starts the session; the root view reacts by swapping the login
/// screen for the main tabs.
public struct SessionLoginFlow: LoginFlow {
    private let session: SessionStore

    public init(session: SessionStore) {
        self.session = session
    }

    public func didLogIn() {
        session.logIn()
    }
}
