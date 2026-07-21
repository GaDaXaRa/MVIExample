import Observation
import Domain

// MARK: - Routes

/// This feature's route: a value saying *what* to show, never *how*. Whoever
/// sends it decides push/sheet/cover; `UserDetailView` never knows which.
/// `nonisolated` like the `Route` protocol: routes are inert values.
public nonisolated struct UserDetailRoute: Route {
    public let user: User

    public init(user: User) {
        self.user = user
    }
}

// MARK: - Flow

/// Navigation policy of the detail screen. Editing relations is not here —
/// that happens in the modal it opens; the detail only asks to open it.
public protocol UserDetailFlow {
    func didRequestManageRelated(for user: User)
}

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
    case manageRelatedTapped
}

// MARK: - Store

@Observable
public final class UserDetailStore: Store {
    public private(set) var state: UserDetailState

    private let toggleFavorite: ToggleFavoriteUseCase
    private let flow: any UserDetailFlow

    public init(user: User, toggleFavorite: ToggleFavoriteUseCase, flow: any UserDetailFlow) {
        self.state = UserDetailState(user: user)
        self.toggleFavorite = toggleFavorite
        self.flow = flow
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
        case .manageRelatedTapped:
            flow.didRequestManageRelated(for: state.user)
        }
    }
}
