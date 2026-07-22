import SwiftUI
import Wireframe
import SwiftData
import Domain

/// The chrome and data source each context exposes. Selection *behavior* is
/// the flow's business; which buttons exist and which users are listed is the
/// view's. Each case carries exactly the data its context needs — no invalid
/// combinations — and the same `UserListView` serves the browsing tabs, the
/// modal pickers, and the related-users list.
public enum UserListMode {
    case browse
    /// The full list minus one user (a picker never offers self-selection).
    case picker(excludingUserID: UUID?)
    /// Only the users related to `target` — the related-users list.
    case related(of: User)
}

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
    // The optional exclusion filters in the store, not in memory — used by the
    // related-user picker to hide the very user the relation is being set for.
    @Query private var users: [User]
    private let mode: UserListMode

    public init(store: any Store<UserListState, UserListIntent>, mode: UserListMode = .browse) {
        _store = State(initialValue: store)
        self.mode = mode
        // The data source is part of the mode: each context queries exactly the
        // users it should show, in the store rather than in memory.
        switch mode {
        case .browse:
            _users = Query(sort: \.name)
        case .picker(let excludingUserID?):
            _users = Query(filter: #Predicate<User> { $0.id != excludingUserID }, sort: \.name)
        case .picker:
            _users = Query(sort: \.name)
        case .related(let target):
            // A user U is related to `target` iff `target` is in U.relatedBy.
            let targetID = target.id
            _users = Query(filter: #Predicate<User> { $0.relatedBy.contains { $0.id == targetID } }, sort: \.name)
        }
    }

    public var body: some View {
        content
            .navigationTitle("Users")
            .toolbar {
                switch mode {
                case .browse:
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button("Add", systemImage: "plus") {
                            store.send(.addUserTapped)
                        }
                        Button("Pick a user", systemImage: "person.crop.rectangle.stack") {
                            store.send(.userPickerTapped)
                        }
                        Button("End session", systemImage: "lock") {
                            store.send(.endSessionTapped)
                        }
                    }
                case .picker:
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            store.send(.cancelTapped)
                        }
                    }
                case .related:
                    // "Add" reuses the add intent — the injected flow decides
                    // it opens the multi-select editor here; "Done" reuses cancel.
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add", systemImage: "person.badge.plus") {
                            store.send(.addUserTapped)
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            store.send(.cancelTapped)
                        }
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
                .swipeActions {
                    switch mode {
                    case .browse:
                        Button("Remove", systemImage: "trash", role: .destructive) {
                            store.send(.remove(user))
                        }
                    case .related(let fromUser):
                        Button("Remove related", systemImage: "trash", role: .destructive) {
                            store.send(.removeRelated(user, from: fromUser))
                        }
                    default:
                        EmptyView()
                    }
                }
            }
            .overlay {
                if store.state.isLoading && users.isEmpty {
                    ProgressView()
                } else if users.isEmpty, case .related = mode {
                    ContentUnavailableView("No related users", systemImage: "person.2.slash")
                }
            }
            .refreshable { store.send(.refresh) }
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
