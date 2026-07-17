import SwiftUI
import SwiftData
import Domain

public struct UserListView: View {
    @Bindable var router: AppRouter
    // The existential (`any Store<State, Intent>`) decouples the view from the
    // concrete store class: previews and tests can back the same view with a
    // stub. `@State` makes the view own the instance across parent re-renders.
    @State private var store: any Store<UserListState, UserListIntent>
    // The Model half of the MVI loop: `@Query` observes SwiftData directly,
    // so any change to any `User`, made anywhere in the app, updates the list
    // automatically. Intents remain the only way the view talks to the store.
    @Query(sort: \User.name) private var users: [User]
    let makeDetailStore: (User) -> any Store<UserDetailState, UserDetailIntent>
    let makeAddUserStore: () -> any Store<AddUserState, AddUserIntent>

    public init(
        router: AppRouter,
        store: any Store<UserListState, UserListIntent>,
        makeDetailStore: @escaping (User) -> any Store<UserDetailState, UserDetailIntent>,
        makeAddUserStore: @escaping () -> any Store<AddUserState, AddUserIntent>
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
                // One registration per feature whose screens can be pushed
                // from here — decentralized, and fully typed (no AnyView).
                .userDetailDestination(makeStore: makeDetailStore)
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

#Preview {
    let container = try! ModelContainer(
        for: User.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    for user in [
        User(name: "Ada Lovelace", email: "ada@example.com", isFavorite: true),
        User(name: "Alan Turing", email: "alan@example.com"),
        User(name: "Grace Hopper", email: "grace@example.com")
    ] {
        container.mainContext.insert(user)
    }
    return UserListView(
        router: AppRouter(),
        store: PreviewStore(state: UserListState()),
        makeDetailStore: { user in PreviewStore(state: UserDetailState(user: user)) },
        makeAddUserStore: { PreviewStore(state: AddUserState()) }
    )
    .modelContainer(container)
}
