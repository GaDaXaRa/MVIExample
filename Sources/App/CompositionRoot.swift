import SwiftData
import Domain
import Data
import Presentation

/// The only type in the whole app allowed to import every layer. It is where
/// abstract Domain protocols get bound to concrete Data implementations and
/// handed to Presentation as opaque `some UseCase` values.
struct CompositionRoot {
    /// Exposed so the App can attach it with `.modelContainer`: the views'
    /// `@Query` and the repository must share the same container.
    let modelContainer: ModelContainer
    private let repository: UserRepository

    init() {
        // A schema this small failing to open is unrecoverable dev-time
        // misconfiguration, hence the force-try; a real app would fall back
        // to an in-memory container and report.
        modelContainer = try! ModelContainer(for: User.self)
        repository = DefaultUserRepository.live(context: modelContainer.mainContext)
    }

    func makeUserListStore(router: AppRouter) -> UserListStore {
        UserListStore(refreshUsers: DefaultRefreshUsersUseCase(repository: repository), router: router)
    }

    func makeUserDetailStore(user: User) -> UserDetailStore {
        UserDetailStore(user: user, toggleFavorite: DefaultToggleFavoriteUseCase(repository: repository))
    }

    func makeAddUserStore(router: AppRouter) -> AddUserStore {
        AddUserStore(addUser: DefaultAddUserUseCase(repository: repository), router: router)
    }
}
