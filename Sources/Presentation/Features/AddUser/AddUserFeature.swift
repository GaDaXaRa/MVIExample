import Observation
import Domain

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
    private let router: AppRouter

    public init(addUser: AddUserUseCase, router: AppRouter) {
        self.addUser = addUser
        self.router = router
    }

    public func send(_ intent: AddUserIntent) {
        switch intent {
        case .nameChanged(let name):
            state.name = name
        case .emailChanged(let email):
            state.email = email
        case .cancel:
            router.dismissSheet()
        case .save:
            Task { await save() }
        }
    }

    private func save() async {
        state.isSaving = true
        state.errorMessage = nil
        do {
            // No callback to the list: the repository caches the new user and
            // the list's observation stream picks it up.
            _ = try await addUser.execute(name: state.name, email: state.email)
            router.dismissSheet()
        } catch {
            state.errorMessage = error.localizedDescription
        }
        state.isSaving = false
    }
}
