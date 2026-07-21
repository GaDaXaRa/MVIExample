/// Deletes a user. Like toggling a favorite or setting a relation, removal is
/// a data mutation, not navigation — so it is a use case the store calls
/// directly, never a flow event.
public protocol RemoveUserUseCase {
    func execute(user: User) throws
}

public struct DefeaultRemoveUserUseCase: RemoveUserUseCase {
    private let repository: UserRepository
    
    public init(repository: UserRepository) {
        self.repository = repository
    }
    
    public func execute(user: User) throws {
        try repository.remove(user)
    }
}
