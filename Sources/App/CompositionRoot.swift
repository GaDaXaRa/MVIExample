import Domain
import Data
import Presentation

/// The only type in the whole app allowed to import every layer. It is where
/// abstract Domain protocols get bound to concrete Data implementations and
/// handed to Presentation as opaque `some UseCase` values.
@MainActor
struct CompositionRoot {
    private let repository: UserRepository = DefaultUserRepository.live()

    func makeUserListStore(router: AppRouter) -> UserListStore {
        UserListStore(
            observeUsers: DefaultObserveUsersUseCase(repository: repository),
            fetchUsers: DefaultFetchUsersUseCase(repository: repository),
            router: router
        )
    }

    func makeUserDetailStore(userID: User.ID, router: AppRouter) -> UserDetailStore {
        UserDetailStore(
            userID: userID,
            fetchUserDetail: DefaultFetchUserDetailUseCase(repository: repository),
            toggleFavorite: DefaultToggleFavoriteUseCase(repository: repository)
        )
    }

    func makeAddUserStore(router: AppRouter) -> AddUserStore {
        AddUserStore(addUser: DefaultAddUserUseCase(repository: repository), router: router)
    }
}
