import Foundation
@testable import Data

actor FakeRemoteUserDataSource: RemoteUserDataSource {
    var usersToReturn: [UserDTO] = []
    private(set) var createUserCalls: [(name: String, email: String)] = []

    func fetchUsers() async throws -> [UserDTO] {
        usersToReturn
    }

    func createUser(name: String, email: String) async throws -> UserDTO {
        createUserCalls.append((name, email))
        return UserDTO(id: UUID(), name: name, email: email, isFavorite: false)
    }

    func set(usersToReturn: [UserDTO]) {
        self.usersToReturn = usersToReturn
    }
}
