import SwiftUI
import Domain

public struct RelatedUsersView: View {
    @State private var store: any Store<RelatedUsersState, RelatedUsersIntent>

    public init(store: any Store<RelatedUsersState, RelatedUsersIntent>) {
        _store = State(initialValue: store)
    }

    public var body: some View {
        // `target.related` is an observable @Model relationship, so the list
        // updates the moment the editor adds or removes someone.
        List(store.state.target.related) { user in
            Button {
                store.send(.selectRelated(user))
            } label: {
                UserRow(user: user)
            }
            .buttonStyle(.plain)
        }
        .overlay {
            if store.state.target.related.isEmpty {
                ContentUnavailableView("No related users", systemImage: "person.2.slash")
            }
        }
        .navigationTitle("Related users")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") {
                    store.send(.editTapped)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { store.send(.doneTapped) }
            }
        }
    }
}

#Preview {
    let ada = User(name: "Ada Lovelace", email: "ada@example.com")
    ada.related = [
        User(name: "Alan Turing", email: "alan@example.com"),
        User(name: "Grace Hopper", email: "grace@example.com")
    ]
    return NavigationStack {
        RelatedUsersView(store: PreviewStore(state: RelatedUsersState(target: ada)))
    }
}
