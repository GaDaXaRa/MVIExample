import SwiftUI
import Domain

public struct UserListView: View {
    @Bindable var router: AppRouter
    @State private var store: UserListStore
    let makeDetailStore: (User.ID) -> UserDetailStore
    let makeAddUserStore: () -> AddUserStore

    public init(
        router: AppRouter,
        store: UserListStore,
        makeDetailStore: @escaping (User.ID) -> UserDetailStore,
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
                    case .userDetail(let id):
                        UserDetailView(store: makeDetailStore(id))
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
            List(store.state.users) { user in
                Button {
                    store.send(.selectUser(user))
                } label: {
                    UserRow(user: user)
                }
                .buttonStyle(.plain)
            }
            .overlay {
                if store.state.isLoading && store.state.users.isEmpty {
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
