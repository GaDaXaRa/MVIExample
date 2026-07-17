import Domain
@testable import Presentation

// Lightweight use case fakes: each Presentation test only needs to control
// one operation's result, so a small main-actor class is enough — no need to
// go through a full fake repository as the Domain/Data tests do.

final class UserListFlowSpy: UserListFlow {
    private(set) var selectedUsers: [User] = []
    private(set) var addUserRequests = 0
    private(set) var userPickerRequests = 0
    private(set) var endSessionRequests = 0
    private(set) var cancellations = 0

    func didSelectUser(_ user: User) { selectedUsers.append(user) }
    func didRequestAddUser() { addUserRequests += 1 }
    func didRequestUserPicker() { userPickerRequests += 1 }
    func didRequestEndSession() { endSessionRequests += 1 }
    func didCancel() { cancellations += 1 }
}

final class LoginFlowSpy: LoginFlow {
    private(set) var logIns = 0

    func didLogIn() { logIns += 1 }
}

final class UserDetailFlowSpy: UserDetailFlow {
    private(set) var pickerRequests: [User] = []
    private(set) var selectedRelated: [User] = []

    func didRequestRelatedPicker(for user: User) { pickerRequests.append(user) }
    func didSelectRelated(_ user: User) { selectedRelated.append(user) }
}

final class FakeSetRelatedUserUseCase: SetRelatedUserUseCase {
    var errorToThrow: Error?
    private(set) var calls: [(user: User, related: User?)] = []

    func execute(user: User, related: User?) throws {
        calls.append((user, related))
        if let errorToThrow { throw errorToThrow }
        user.related = related
    }
}

final class AddUserFlowSpy: AddUserFlow {
    private(set) var finishCount = 0
    private(set) var cancelCount = 0

    func didFinish() { finishCount += 1 }
    func didCancel() { cancelCount += 1 }
}

final class FakeRefreshUsersUseCase: RefreshUsersUseCase {
    var errorToThrow: Error?
    private(set) var calls = 0

    func execute() async throws {
        calls += 1
        if let errorToThrow { throw errorToThrow }
    }
}

final class FakeToggleFavoriteUseCase: ToggleFavoriteUseCase {
    var errorToThrow: Error?
    private(set) var calls: [(user: User, isFavorite: Bool)] = []

    func execute(user: User, isFavorite: Bool) throws {
        calls.append((user, isFavorite))
        if let errorToThrow { throw errorToThrow }
        user.isFavorite = isFavorite
    }
}

final class FakeAddUserUseCase: AddUserUseCase {
    var userToReturn: User?
    var errorToThrow: Error?

    func execute(name: String, email: String) async throws -> User {
        if let errorToThrow { throw errorToThrow }
        return userToReturn ?? User(name: name, email: email)
    }
}
