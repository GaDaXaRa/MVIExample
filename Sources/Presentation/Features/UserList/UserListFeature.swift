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

    private let observeUsers: ObserveUsersUseCase
    private let fetchUsers: FetchUsersUseCase
    private let router: AppRouter
    // Unstructured because it starts from the synchronous `send`; cancelled in
    // `deinit` so a discarded store never keeps observing. `nonisolated(unsafe)`
    // because `deinit` is nonisolated in Swift 6 — safe here: it is only
    // touched on the main actor and in `deinit`, when no other reference exists.
    @ObservationIgnored private nonisolated(unsafe) var observationTask: Task<Void, Never>?

    public init(observeUsers: ObserveUsersUseCase, fetchUsers: FetchUsersUseCase, router: AppRouter) {
        self.observeUsers = observeUsers
        self.fetchUsers = fetchUsers
        self.router = router
    }

    deinit {
        observationTask?.cancel()
    }

    public func send(_ intent: UserListIntent) {
        switch intent {
        case .onAppear:
            startObservingIfNeeded()
            Task { await refresh() }
        case .refresh:
            Task { await refresh() }
        case .selectUser(let user):
            router.push(.userDetail(user.id))
        case .addUserTapped:
            router.present(.addUser)
        }
    }

    /// `state.users` has a single source of truth: the repository stream.
    /// Favorites toggled in the detail screen and users added from the sheet
    /// arrive through it, with no cross-feature callbacks.
    private func startObservingIfNeeded() {
        guard observationTask == nil else { return }
        observationTask = Task { [weak self] in
            guard let stream = await self?.observeUsers.execute() else { return }
            for await users in stream {
                self?.state.users = users
            }
        }
    }

    private func refresh() async {
        state.isLoading = true
        state.errorMessage = nil
        do {
            // Result deliberately ignored: the refreshed users reach
            // `state.users` through the observation stream.
            _ = try await fetchUsers.execute()
        } catch {
            state.errorMessage = error.localizedDescription
        }
        state.isLoading = false
    }
}
