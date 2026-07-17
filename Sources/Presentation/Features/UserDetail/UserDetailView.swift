import SwiftUI
import Domain

public struct UserDetailView: View {
    // `@State` makes the view own the store: parent body re-evaluations
    // re-run the factory and pass a fresh instance here, but SwiftUI keeps
    // the one from the first render.
    @State private var store: any Store<UserDetailState, UserDetailIntent>

    public init(store: any Store<UserDetailState, UserDetailIntent>) {
        _store = State(initialValue: store)
    }

    public var body: some View {
        List {
            LabeledContent("Name", value: store.state.user.name)
            LabeledContent("Email", value: store.state.user.email)
            Button {
                store.send(.toggleFavorite)
            } label: {
                Label(
                    store.state.user.isFavorite ? "Remove from favorites" : "Add to favorites",
                    systemImage: store.state.user.isFavorite ? "star.fill" : "star"
                )
            }

            Section("Related user") {
                if let related = store.state.user.related {
                    Button {
                        store.send(.relatedTapped)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(related.name).font(.headline)
                            Text(related.email).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button("Remove", systemImage: "trash", role: .destructive) {
                            store.send(.removeRelatedTapped)
                        }
                    }
                } else {
                    Button("Add related user", systemImage: "person.badge.plus") {
                        store.send(.addRelatedTapped)
                    }
                }
            }

            if let errorMessage = store.state.errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
        }
        .navigationTitle(store.state.user.name)
    }
}

#Preview {
    let user = User(name: "Ada Lovelace", email: "ada@example.com", isFavorite: true)
    user.related = User(name: "Alan Turing", email: "alan@example.com")
    return NavigationStack {
        UserDetailView(store: PreviewStore(state: UserDetailState(user: user)))
    }
}
