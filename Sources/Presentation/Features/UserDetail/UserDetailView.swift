import SwiftUI

public struct UserDetailView: View {
    // `@State` makes the view own the store: parent body re-evaluations
    // re-run the factory and pass a fresh instance here, but SwiftUI keeps
    // the one from the first render, preserving loaded state.
    @State private var store: UserDetailStore

    public init(store: UserDetailStore) {
        _store = State(initialValue: store)
    }

    public var body: some View {
        Group {
            if let user = store.state.user {
                List {
                    LabeledContent("Name", value: user.name)
                    LabeledContent("Email", value: user.email)
                    Button {
                        store.send(.toggleFavorite)
                    } label: {
                        Label(
                            user.isFavorite ? "Remove from favorites" : "Add to favorites",
                            systemImage: user.isFavorite ? "star.fill" : "star"
                        )
                    }
                }
            } else if store.state.isLoading {
                ProgressView()
            } else if let errorMessage = store.state.errorMessage {
                ContentUnavailableView("Not found", systemImage: "person.slash", description: Text(errorMessage))
            }
        }
        .navigationTitle(store.state.user?.name ?? "Detail")
        .onAppear { store.send(.onAppear) }
    }
}
