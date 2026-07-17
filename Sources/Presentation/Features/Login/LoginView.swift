import SwiftUI

public struct LoginView: View {
    @State private var store: any Store<Void, LoginIntent>

    public init(store: any Store<Void, LoginIntent>) {
        _store = State(initialValue: store)
    }

    public var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.badge.key")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Welcome back")
                .font(.largeTitle.bold())
            Button("Log in") {
                store.send(.logInTapped)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background()
    }
}

#Preview {
    LoginView(store: PreviewStore(state: ()))
}
