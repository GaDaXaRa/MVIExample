import SwiftUI
import SwiftData
import Domain

/// Presentation-agnostic, like every screen: it renders content and sends
/// intents. Navigation containers (stack, sheet, cover) belong to the
/// wireframe; destination resolution belongs to the registry.
public struct UserListView: View {
    // The existential (`any Store<State, Intent>`) decouples the view from the
    // concrete store class: previews and tests can back the same view with a
    // stub. `@State` makes the view own the instance across parent re-renders.
    @State private var store: any Store<UserListState, UserListIntent>
    // The Model half of the MVI loop: `@Query` observes SwiftData directly,
    // so any change to any `User`, made anywhere in the app, updates the list
    // automatically. Intents remain the only way the view talks to the store.
    @Query(sort: \User.name) private var users: [User]

    public init(store: any Store<UserListState, UserListIntent>) {
        _store = State(initialValue: store)
    }

    public var body: some View {
        content
            .navigationTitle("Users")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus") {
                        store.send(.addUserTapped)
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
    return NavigationStack {
        UserListView(store: PreviewStore(state: UserListState()))
    }
    .modelContainer(container)
}
