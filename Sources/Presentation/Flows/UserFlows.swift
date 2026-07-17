import Domain

// Concrete navigation policies. A flow is allowed to know several features —
// knitting screens together is precisely its job; the features themselves
// never know each other. The composition root decides which flow each screen
// gets, so the same feature can navigate differently in different contexts.

/// Browsing context: selecting a user pushes its detail; adding opens a sheet.
public struct BrowseUsersFlow: UserListFlow {
    private let router: any Router

    public init(router: any Router) {
        self.router = router
    }

    public func didSelectUser(_ user: User) {
        router.send(.push(UserDetailRoute(user: user)))
    }

    public func didRequestAddUser() {
        router.send(.sheet(AddUserRoute()))
    }
}

/// Alternative context for the *same* list feature: selecting a user shows
/// the detail as a sheet instead of pushing it. Swapping this in at the
/// composition root changes the app's navigation without touching UserList,
/// UserDetail, or any view.
public struct QuickLookUsersFlow: UserListFlow {
    private let router: any Router

    public init(router: any Router) {
        self.router = router
    }

    public func didSelectUser(_ user: User) {
        router.send(.sheet(UserDetailRoute(user: user)))
    }

    public func didRequestAddUser() {
        router.send(.sheet(AddUserRoute()))
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
