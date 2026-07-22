import Foundation

/// Validation errors live in the Domain layer: they are business rules,
/// not view logic and not persistence logic.
public enum UserValidationError: Error, LocalizedError, Sendable, Equatable {
    case emptyName
    case invalidEmail

    public var errorDescription: String? {
        switch self {
        case .emptyName: return String(localized: "Name cannot be empty.")
        case .invalidEmail: return String(localized: "Please enter a valid email address.")
        }
    }
}

public protocol AddUserUseCase {
    func execute(name: String, email: String) async throws -> User
}

/// A use case that does more than forward to the repository: it enforces the
/// invariant that only valid users are ever created, regardless of which
/// screen or caller triggers the operation.
public struct DefaultAddUserUseCase: AddUserUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute(name: String, email: String) async throws -> User {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw UserValidationError.emptyName }
        guard email.contains("@"), email.contains(".") else { throw UserValidationError.invalidEmail }
        return try await repository.addUser(name: trimmedName, email: email)
    }
}
