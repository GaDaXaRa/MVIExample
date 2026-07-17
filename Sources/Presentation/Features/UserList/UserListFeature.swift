import Observation
import Domain

// MARK: - Model

/// Only transient UI state lives here. The users themselves reach the view
/// through `@Query`: SwiftData is the single source of truth, so favorites
/// toggled in the detail screen and users added from the sheet show up in
/// the list automatically.
public struct UserListState: Equatable, Sendable {
    public var isLoading = false
    public var errorMessage: String?

    public init() {}
}

// MARK: - Intent

public enum UserListIntent {
    case onAppear
    case refresh
    case selectUser(User)
    case addUserTapped
}

// MARK: - Store

@Observable
@MainActor
public final class UserListStore: Store {
    public private(set) var state = UserListState()

    private let refreshUsers: RefreshUsersUseCase
    private let router: AppRouter

    public init(refreshUsers: RefreshUsersUseCase, router: AppRouter) {
        self.refreshUsers = refreshUsers
        self.router = router
    }

    public func send(_ intent: UserListIntent) {
        switch intent {
        case .onAppear, .refresh:
            Task { await refresh() }
        case .selectUser(let user):
            router.push(.userDetail(user))
        case .addUserTapped:
            router.present(.addUser)
        }
    }

    private func refresh() async {
        state.isLoading = true
        state.errorMessage = nil
        do {
            try await refreshUsers.execute()
        } catch {
            state.errorMessage = error.localizedDescription
        }
        state.isLoading = false
    }
}
