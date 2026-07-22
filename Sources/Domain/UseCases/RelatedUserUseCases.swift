import Foundation

public enum UserRelationError: Error, LocalizedError, Sendable, Equatable {
    case selfRelation

    public var errorDescription: String? {
        switch self {
        case .selfRelation: return String(localized: "A user cannot be related to themselves.")
        }
    }
}

/// Adds a user to another's related set, enforcing the one business rule of
/// the relationship (no self-relations) and idempotence (no duplicates).
public protocol AddRelatedUserUseCase {
    func execute(_ related: User, to user: User) throws
}

public struct DefaultAddRelatedUserUseCase: AddRelatedUserUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute(_ related: User, to user: User) throws {
        guard related.id != user.id else { throw UserRelationError.selfRelation }
        guard !user.related.contains(where: { $0.id == related.id }) else { return }
        try repository.addRelated(related, to: user)
    }
}

/// Removes a user from another's related set.
public protocol RemoveRelatedUserUseCase {
    func execute(_ related: User, from user: User) throws
}

public struct DefaultRemoveRelatedUserUseCase: RemoveRelatedUserUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute(_ related: User, from user: User) throws {
        try repository.removeRelated(related, from: user)
    }
}
