import SwiftData
import Domain
import Data
import Presentation

/// A main tab: its chrome and its own router, so each tab keeps independent
/// navigation state that survives switching tabs — and even a session expiry,
/// since the routers live here and not in the view tree.
struct AppTab: Identifiable {
    let id: String
    let systemImage: String
    let router = AppRouter()

    var title: String { id }
}

/// The only type in the whole app allowed to import every layer. It is where
/// abstract Domain protocols get bound to concrete Data implementations, and
/// where every route type is registered with the view that renders it — the
/// one place that knows the whole navigation map.
struct CompositionRoot {
    /// Exposed so the App can attach it with `.modelContainer`: the views'
    /// `@Query` and the repository must share the same container.
    let modelContainer: ModelContainer
    let session = SessionStore()
    let registry = DestinationRegistry()
    let tabs = [
        AppTab(id: "Browse", systemImage: "person.3"),
        AppTab(id: "Team", systemImage: "person.2.badge.gearshape"),
        AppTab(id: "Directory", systemImage: "book.pages")
    ]
    let deepLink: DeepLinkCoordinator
    private let repository: UserRepository

    init() {
        // A schema this small failing to open is unrecoverable dev-time
        // misconfiguration, hence the force-try; a real app would fall back
        // to an in-memory container and report.
        modelContainer = try! ModelContainer(for: User.self)
        let repository = DefaultUserRepository.live(context: modelContainer.mainContext)
        self.repository = repository
        deepLink = DeepLinkCoordinator(
            routers: tabs.map(\.router),
            session: session,
            fetchUser: DefaultFetchUserUseCase(repository: repository)
        )

        // Route -> view bindings. Presentation mode is not part of the
        // registration, and each builder receives the router of the wireframe
        // that presents it, so destinations always act on their own context.
        let session = session
        registry.register(UserDetailRoute.self) { route, router in
            UserDetailView(store: UserDetailStore(
                user: route.user,
                toggleFavorite: DefaultToggleFavoriteUseCase(repository: repository),
                flow: RelatedUserFlow(router: router)
            ))
        }
        registry.register(ManageRelatedRoute.self) { route, router in
            UserListView(
                store: UserListStore(
                    refreshUsers: DefaultRefreshUsersUseCase(repository: repository),
                    removeUser: DefaultRemoveUserUseCase(repository: repository),
                    flow: RelatedListFlow(target: route.target, router: router)
                ),
                mode: .related(of: route.target)
            )
        }
        registry.register(SelectRelatedRoute.self) { route, router in
            SelectRelatedUsersView(store: SelectRelatedUsersStore(
                target: route.target,
                addRelated: DefaultAddRelatedUserUseCase(repository: repository),
                removeRelated: DefaultRemoveRelatedUserUseCase(repository: repository),
                flow: SelectRelatedModalFlow(router: router)
            ))
        }
        registry.register(AddUserRoute.self) { _, router in
            AddUserView(store: AddUserStore(
                addUser: DefaultAddUserUseCase(repository: repository),
                flow: AddUserModalFlow(router: router)
            ))
        }
        registry.register(UserPickerRoute.self) { _, router in
            UserListView(
                store: UserListStore(
                    refreshUsers: DefaultRefreshUsersUseCase(repository: repository),
                    removeUser: DefaultRemoveUserUseCase(repository: repository),
                    flow: PickUserFlow(router: router)
                ),
                mode: .picker(excludingUserID: nil)
            )
        }
    }

    func makeUserListStore(router: any Router) -> UserListStore {
        UserListStore(
            refreshUsers: DefaultRefreshUsersUseCase(repository: repository),
            removeUser: DefaultRemoveUserUseCase(repository: repository),
            flow: BrowseUsersFlow(router: router, session: session)
        )
    }

    func makeLoginStore() -> LoginStore {
        LoginStore(flow: SessionLoginFlow(session: session))
    }
}
