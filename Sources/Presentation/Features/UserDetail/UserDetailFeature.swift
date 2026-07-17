import Observation
import Domain

// MARK: - Model

/// The user arrives already loaded (it is the navigation payload), so there
/// is no loading state and no not-found state. The `@Model` object is itself
/// observable: mutating it re-renders this screen and the list at once.
public struct UserDetailState {
    public var user: User
    public var errorMessage: String?

    public init(user: User) {
        self.user = user
    }
}

// MARK: - Intent

public enum UserDetailIntent {
    case toggleFavorite
}

// MARK: - Store

@Observable
@MainActor
public final class UserDetailStore: Store {
    public private(set) var state: UserDetailState

    private let toggleFavorite: ToggleFavoriteUseCase

    public init(user: User, toggleFavorite: ToggleFavoriteUseCase) {
        self.state = UserDetailState(user: user)
        self.toggleFavorite = toggleFavorite
    }

    public func send(_ intent: UserDetailIntent) {
        switch intent {
        case .toggleFavorite:
            // Synchronous and local: no optimistic update or rollback needed.
            do {
                try toggleFavorite.execute(user: state.user, isFavorite: !state.user.isFavorite)
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }
}
