import Observation
import Domain

// MARK: - Route

/// Shows the users related to `target`, modally. Carries the target as payload
/// so the same screen works for any user, from a tab stack or a nested modal.
public nonisolated struct ManageRelatedRoute: Route {
    public let target: User

    public init(target: User) {
        self.target = target
    }
}

// MARK: - Flow

/// Navigation policy of the related-users list: it can open the multi-select
/// editor, inspect one related user, or close. Adding/removing itself is a
/// data mutation that happens in the editor, not here.
public protocol RelatedUsersFlow {
    func didRequestEditor(for user: User)
    func didSelectRelated(_ user: User)
    func didFinish()
}

// MARK: - Model

public struct RelatedUsersState {
    public var target: User

    public init(target: User) {
        self.target = target
    }
}

// MARK: - Intent

public enum RelatedUsersIntent {
    case editTapped
    case selectRelated(User)
    case doneTapped
}

// MARK: - Store

@Observable
public final class RelatedUsersStore: Store {
    public private(set) var state: RelatedUsersState

    private let flow: any RelatedUsersFlow

    public init(target: User, flow: any RelatedUsersFlow) {
        self.state = RelatedUsersState(target: target)
        self.flow = flow
    }

    public func send(_ intent: RelatedUsersIntent) {
        switch intent {
        case .editTapped:
            flow.didRequestEditor(for: state.target)
        case .selectRelated(let user):
            flow.didSelectRelated(user)
        case .doneTapped:
            flow.didFinish()
        }
    }
}
