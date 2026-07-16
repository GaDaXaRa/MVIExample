import Observation
import Domain

// MARK: - Model

public struct UserListState: Equatable, Sendable {
    public var users: [User] = []
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

    private let fetchUsers: FetchUsersUseCase
    private let router: AppRouter

    public init(fetchUsers: FetchUsersUseCase, router: AppRouter) {
        self.fetchUsers = fetchUsers
        self.router = router
    }

    public func send(_ intent: UserListIntent) {
        switch intent {
        case .onAppear, .refresh:
            Task { await load() }
        case .selectUser(let user):
            router.push(.userDetail(user.id))
        case .addUserTapped:
            router.present(.addUser)
        }
    }

    /// Called back by `AddUserStore` after a successful save, so the list
    /// reflects the new user without a full re-fetch.
    public func userWasAdded(_ user: User) {
        state.users.append(user)
        state.users.sort { $0.name < $1.name }
    }

    private func load() async {
        state.isLoading = true
        state.errorMessage = nil
        do {
            state.users = try await fetchUsers.execute()
        } catch {
            state.errorMessage = error.localizedDescription
        }
        state.isLoading = false
    }
}
