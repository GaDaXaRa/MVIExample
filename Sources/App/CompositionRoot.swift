import SwiftData
import Domain
import Data
import Presentation

/// The only type in the whole app allowed to import every layer. It is where
/// abstract Domain protocols get bound to concrete Data implementations, and
/// where every route type is registered with the view that renders it — the
/// one place that knows the whole navigation map.
struct CompositionRoot {
    /// Exposed so the App can attach it with `.modelContainer`: the views'
    /// `@Query` and the repository must share the same container.
    let modelContainer: ModelContainer
    let router = AppRouter()
    let registry = DestinationRegistry()
    private let repository: UserRepository

    init() {
        // A schema this small failing to open is unrecoverable dev-time
        // misconfiguration, hence the force-try; a real app would fall back
        // to an in-memory container and report.
        modelContainer = try! ModelContainer(for: User.self)
        let repository = DefaultUserRepository.live(context: modelContainer.mainContext)
        self.repository = repository

        // Route -> view bindings. Presentation mode is not part of the
        // registration: any of these can be pushed or presented modally.
        let router = router
        registry.register(UserDetailRoute.self) { route in
            UserDetailView(store: UserDetailStore(
                user: route.user,
                toggleFavorite: DefaultToggleFavoriteUseCase(repository: repository)
            ))
        }
        registry.register(AddUserRoute.self) { _ in
            AddUserView(store: AddUserStore(
                addUser: DefaultAddUserUseCase(repository: repository),
                router: router
            ))
        }
    }

    func makeUserListStore() -> UserListStore {
        UserListStore(refreshUsers: DefaultRefreshUsersUseCase(repository: repository), router: router)
    }
}
