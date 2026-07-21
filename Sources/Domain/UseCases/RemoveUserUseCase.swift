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
