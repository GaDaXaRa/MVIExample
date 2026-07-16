import SwiftUI

public struct UserDetailView: View {
    let store: UserDetailStore

    public init(store: UserDetailStore) {
        self.store = store
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
