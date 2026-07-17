import SwiftUI
import SwiftData
import Domain

public struct UserListView: View {
    @Bindable var router: AppRouter
    // `@State` makes the view own the store: parent body re-evaluations
    // re-run the factory and pass a fresh instance here, but SwiftUI keeps
    // the one from the first render.
    @State private var store: UserListStore
    // The Model half of the MVI loop: `@Query` observes SwiftData directly,
    // so any change to any `User`, made anywhere in the app, updates the list
    // automatically. Intents remain the only way the view talks to the store.
    @Query(sort: \User.name) private var users: [User]
    let makeDetailStore: (User) -> UserDetailStore
    let makeAddUserStore: () -> AddUserStore

    public init(
        router: AppRouter,
        store: UserListStore,
        makeDetailStore: @escaping (User) -> UserDetailStore,
        makeAddUserStore: @escaping () -> AddUserStore
    ) {
        self.router = router
        _store = State(initialValue: store)
        self.makeDetailStore = makeDetailStore
        self.makeAddUserStore = makeAddUserStore
    }

    public var body: some View {
        NavigationStack(path: $router.path) {
            content
                .navigationTitle("Users")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add", systemImage: "plus") {
                            store.send(.addUserTapped)
                        }
                    }
                }
                .navigationDestination(for: AppRouter.Route.self) { route in
                    switch route {
                    case .userDetail(let user):
                        UserDetailView(store: makeDetailStore(user))
                    }
                }
                .sheet(item: $router.presentedSheet) { sheet in
                    switch sheet {
                    case .addUser:
                        AddUserView(store: makeAddUserStore())
                    }
                }
        }
        .onAppear { store.send(.onAppear) }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = store.state.errorMessage {
            ContentUnavailableView("Something went wrong", systemImage: "wifi.slash", description: Text(errorMessage))
        } else {
            List(users) { user in
                Button {
                    store.send(.selectUser(user))
                } label: {
                    UserRow(user: user)
                }
                .buttonStyle(.plain)
            }
            .overlay {
                if store.state.isLoading && users.isEmpty {
                    ProgressView()
                }
            }
            .refreshable { store.send(.refresh) }
        }
    }
}

private struct UserRow: View {
    let user: User

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(user.name).font(.headline)
                Text(user.email).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if user.isFavorite {
                Image(systemName: "star.fill").foregroundStyle(.yellow)
            }
        }
    }
}
