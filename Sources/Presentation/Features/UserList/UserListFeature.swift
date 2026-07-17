import Observation
import Domain

// MARK: - Routes

/// The user list presented as a modal picker: same feature, different flow —
/// selecting a user reports it instead of navigating into it.
public nonisolated struct UserPickerRoute: Route {
    public init() {}
}

// MARK: - Flow

/// The feature's navigation *policy*, expressed in domain language: the store
/// reports what happened, never where it leads. The composition root injects
/// a concrete flow, so the same list can push a detail in one context and
/// show an alert in another — without touching this feature.
///
/// Defaults are no-ops: a context only wires the events its chrome exposes
/// (`UserListMode` decides which buttons exist).
public protocol UserListFlow {
    func didSelectUser(_ user: User)
    func didRequestAddUser()
    func didRequestUserPicker()
    func didRequestEndSession()
    func didCancel()
}

public extension UserListFlow {
    func didRequestAddUser() {}
    func didRequestUserPicker() {}
    func didRequestEndSession() {}
    func didCancel() {}
}

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
    case userPickerTapped
    case endSessionTapped
    case cancelTapped
}

// MARK: - Store

@Observable
public final class UserListStore: Store {
    public private(set) var state = UserListState()

    private let refreshUsers: RefreshUsersUseCase
    private let flow: any UserListFlow

    public init(refreshUsers: RefreshUsersUseCase, flow: any UserListFlow) {
        self.refreshUsers = refreshUsers
        self.flow = flow
    }

    public func send(_ intent: UserListIntent) {
        switch intent {
        case .onAppear, .refresh:
            Task { await refresh() }
        // The store reports semantic events; the injected flow decides what
        // screen (if any) comes next and how it is presented.
        case .selectUser(let user):
            flow.didSelectUser(user)
        case .addUserTapped:
            flow.didRequestAddUser()
        case .userPickerTapped:
            flow.didRequestUserPicker()
        case .endSessionTapped:
            flow.didRequestEndSession()
        case .cancelTapped:
            flow.didCancel()
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
