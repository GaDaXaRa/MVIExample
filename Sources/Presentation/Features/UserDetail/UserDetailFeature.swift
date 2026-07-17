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

/// The user list presented to pick a related user for `target`: same list
/// feature, yet another flow — selecting assigns the relation and dismisses.
public nonisolated struct RelatedUserPickerRoute: Route {
    public let target: User

    public init(target: User) {
        self.target = target
    }
}

// MARK: - Flow

/// Navigation policy of the detail screen. Removing the relation is not
/// here: that is a data mutation (a use case), not navigation.
public protocol UserDetailFlow {
    func didRequestRelatedPicker(for user: User)
    func didSelectRelated(_ user: User)
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
    case addRelatedTapped
    case relatedTapped
    case removeRelatedTapped
}

// MARK: - Store

@Observable
public final class UserDetailStore: Store {
    public private(set) var state: UserDetailState

    private let toggleFavorite: ToggleFavoriteUseCase
    private let setRelated: SetRelatedUserUseCase
    private let flow: any UserDetailFlow

    public init(
        user: User,
        toggleFavorite: ToggleFavoriteUseCase,
        setRelated: SetRelatedUserUseCase,
        flow: any UserDetailFlow
    ) {
        self.state = UserDetailState(user: user)
        self.toggleFavorite = toggleFavorite
        self.setRelated = setRelated
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
        case .addRelatedTapped:
            flow.didRequestRelatedPicker(for: state.user)
        case .relatedTapped:
            guard let related = state.user.related else { return }
            flow.didSelectRelated(related)
        case .removeRelatedTapped:
            do {
                try setRelated.execute(user: state.user, related: nil)
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }
}
