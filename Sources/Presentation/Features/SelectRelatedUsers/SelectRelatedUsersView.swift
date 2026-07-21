import SwiftUI
import SwiftData
import Domain

public struct SelectRelatedUsersView: View {
    @State private var store: any Store<SelectRelatedState, SelectRelatedIntent>
    // All users except the target (a user can't relate to itself).
    @Query private var users: [User]

    public init(store: any Store<SelectRelatedState, SelectRelatedIntent>) {
        _store = State(initialValue: store)
        let targetID = store.state.target.id
        _users = Query(filter: #Predicate<User> { $0.id != targetID }, sort: \.name)
    }

    // Derived from state: the observable relationship drives the checkmark, so
    // a toggle re-renders the row immediately.
    private func isRelated(_ user: User) -> Bool {
        store.state.target.related.contains { $0.id == user.id }
    }

    public var body: some View {
        List {
            ForEach(users) { user in
                Button {
                    store.send(.toggle(user))
                } label: {
                    HStack {
                        Image(systemName: isRelated(user) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isRelated(user) ? Color.accentColor : Color.secondary)
                        UserRow(user: user)
                    }
                }
                .buttonStyle(.plain)
            }
            if let errorMessage = store.state.errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
        }
        .navigationTitle("Select related")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { store.send(.doneTapped) }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: User.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ada = User(name: "Ada Lovelace", email: "ada@example.com")
    let alan = User(name: "Alan Turing", email: "alan@example.com")
    let grace = User(name: "Grace Hopper", email: "grace@example.com")
    for user in [ada, alan, grace] { container.mainContext.insert(user) }
    ada.related = [alan]
    return NavigationStack {
        SelectRelatedUsersView(store: PreviewStore(state: SelectRelatedState(target: ada)))
    }
    .modelContainer(container)
}
