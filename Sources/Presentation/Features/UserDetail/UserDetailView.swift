import SwiftUI
import Domain

public struct UserDetailView: View {
    // The existential (`any Store<State, Intent>`) decouples the view from the
    // concrete store class: previews and tests can back the same view with a
    // stub. `@State` makes the view own the instance across parent re-renders.
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
            if let errorMessage = store.state.errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
        }
        .navigationTitle(store.state.user.name)
    }
}

#Preview {
    NavigationStack {
        UserDetailView(store: PreviewStore(state: UserDetailState(
            user: User(name: "Ada Lovelace", email: "ada@example.com", isFavorite: true)
        )))
    }
}
