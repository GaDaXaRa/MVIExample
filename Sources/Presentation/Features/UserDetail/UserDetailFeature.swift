import Observation
import Domain

// MARK: - Model

public struct UserDetailState: Equatable, Sendable {
    public var user: User?
    public var isLoading = false
    public var errorMessage: String?

    public init() {}
}

// MARK: - Intent

public enum UserDetailIntent {
    case onAppear
    case toggleFavorite
}

// MARK: - Store

@Observable
@MainActor
public final class UserDetailStore: Store {
    public private(set) var state = UserDetailState()

    private let userID: User.ID
    private let fetchUserDetail: FetchUserDetailUseCase
    private let toggleFavorite: ToggleFavoriteUseCase

    public init(
        userID: User.ID,
        fetchUserDetail: FetchUserDetailUseCase,
        toggleFavorite: ToggleFavoriteUseCase
    ) {
        self.userID = userID
        self.fetchUserDetail = fetchUserDetail
        self.toggleFavorite = toggleFavorite
    }

    public func send(_ intent: UserDetailIntent) {
        switch intent {
        case .onAppear:
            Task { await load() }
        case .toggleFavorite:
            Task { await flipFavorite() }
        }
    }

    private func load() async {
        state.isLoading = true
        state.errorMessage = nil
        do {
            state.user = try await fetchUserDetail.execute(id: userID)
        } catch {
            state.errorMessage = error.localizedDescription
        }
        state.isLoading = false
    }

    /// Optimistic update: flip the UI immediately, roll back only if the
    /// use case actually fails. Demonstrates a common async UI pattern
    /// without blocking the view on the round trip.
    private func flipFavorite() async {
        guard let user = state.user else { return }
        let newValue = !user.isFavorite
        state.user?.isFavorite = newValue
        do {
            try await toggleFavorite.execute(id: user.id, isFavorite: newValue)
        } catch {
            state.user?.isFavorite = !newValue
            state.errorMessage = error.localizedDescription
        }
    }
}
