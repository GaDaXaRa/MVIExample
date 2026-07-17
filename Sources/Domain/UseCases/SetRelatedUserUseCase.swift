import Foundation

public enum UserRelationError: Error, LocalizedError, Sendable, Equatable {
    case selfRelation

    public var errorDescription: String? {
        switch self {
        case .selfRelation: return "A user cannot be related to themselves."
        }
    }
}

/// Sets (or clears, with `nil`) a user's related user, enforcing the one
/// business rule of the relationship: no self-relations.
public protocol SetRelatedUserUseCase {
    func execute(user: User, related: User?) throws
}

public struct DefaultSetRelatedUserUseCase: SetRelatedUserUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute(user: User, related: User?) throws {
        if let related, related.id == user.id {
            throw UserRelationError.selfRelation
        }
        try repository.setRelated(related, for: user)
    }
}
