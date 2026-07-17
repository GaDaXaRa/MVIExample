import SwiftUI

public struct UserDetailView: View {
    // `@State` makes the view own the store: parent body re-evaluations
    // re-run the factory and pass a fresh instance here, but SwiftUI keeps
    // the one from the first render.
    @State private var store: UserDetailStore

    public init(store: UserDetailStore) {
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
