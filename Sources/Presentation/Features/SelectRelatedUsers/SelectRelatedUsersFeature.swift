import Observation
import Wireframe
import Domain

// MARK: - Route

/// The full user list as a multi-select editor for `target`'s relations.
public nonisolated struct SelectRelatedRoute: Route {
    public let target: User

    public init(target: User) {
        self.target = target
    }
}

// MARK: - Flow

public protocol SelectRelatedFlow {
    func didFinish()
}

// MARK: - Model

public struct SelectRelatedState {
    public var target: User
    public var errorMessage: String?

    public init(target: User) {
        self.target = target
    }
}

// MARK: - Intent

public enum SelectRelatedIntent {
    case toggle(User)
    case doneTapped
}

// MARK: - Store

@Observable
public final class SelectRelatedUsersStore: Store {
    public private(set) var state: SelectRelatedState

    private let addRelated: AddRelatedUserUseCase
    private let removeRelated: RemoveRelatedUserUseCase
    private let flow: any SelectRelatedFlow

    public init(
        target: User,
        addRelated: AddRelatedUserUseCase,
        removeRelated: RemoveRelatedUserUseCase,
        flow: any SelectRelatedFlow
    ) {
        self.state = SelectRelatedState(target: target)
        self.addRelated = addRelated
        self.removeRelated = removeRelated
        self.flow = flow
    }

    private func isRelated(_ user: User) -> Bool {
        state.target.related.contains { $0.id == user.id }
    }

    public func send(_ intent: SelectRelatedIntent) {
        switch intent {
        case .toggle(let user):
            // Applied immediately; the observable relationship re-renders the
            // checkmark and the list behind the modal at once.
            do {
                if isRelated(user) {
                    try removeRelated.execute(user, from: state.target)
                } else {
                    try addRelated.execute(user, to: state.target)
                }
            } catch {
                state.errorMessage = error.localizedDescription
            }
        case .doneTapped:
            flow.didFinish()
        }
    }
}
