import Observation
import Wireframe
import Domain

// MARK: - Route

/// This feature's route: a value saying *what* to show, never *how*. Whoever
/// sends it decides push/sheet/cover; `AddUserView` never knows which.
public nonisolated struct AddUserRoute: Route {
    public init() {}
}

// MARK: - Flow

/// Semantic outcomes of this screen. The store doesn't even assume it is in a
/// modal: whether finishing means dismissing a sheet, popping, or chaining a
/// confirmation screen is the injected flow's decision.
public protocol AddUserFlow {
    func didFinish()
    func didCancel()
}

// MARK: - Model

public struct AddUserState: Equatable, Sendable {
    public var name = ""
    public var email = ""
    public var isSaving = false
    public var errorMessage: String?

    public init() {}
}

// MARK: - Intent

public enum AddUserIntent {
    case nameChanged(String)
    case emailChanged(String)
    case save
    case cancel
}

// MARK: - Store

@Observable
public final class AddUserStore: Store {
    public private(set) var state = AddUserState()

    private let addUser: AddUserUseCase
    private let flow: any AddUserFlow

    public init(addUser: AddUserUseCase, flow: any AddUserFlow) {
        self.addUser = addUser
        self.flow = flow
    }

    public func send(_ intent: AddUserIntent) {
        switch intent {
        case .nameChanged(let name):
            state.name = name
        case .emailChanged(let email):
            state.email = email
        case .cancel:
            flow.didCancel()
        case .save:
            Task { await save() }
        }
    }

    private func save() async {
        state.isSaving = true
        state.errorMessage = nil
        do {
            // No callback to the list: the repository inserts the new user
            // into SwiftData and the list's @Query picks it up.
            _ = try await addUser.execute(name: state.name, email: state.email)
            flow.didFinish()
        } catch {
            state.errorMessage = error.localizedDescription
        }
        state.isSaving = false
    }
}
