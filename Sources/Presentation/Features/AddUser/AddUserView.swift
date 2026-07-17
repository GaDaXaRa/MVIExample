import SwiftUI

public struct AddUserView: View {
    // `@State` makes the view own the store: parent body re-evaluations
    // re-run the factory and pass a fresh instance here, but SwiftUI keeps
    // the one from the first render, preserving typed form state.
    @State private var store: AddUserStore

    public init(store: AddUserStore) {
        _store = State(initialValue: store)
    }

    public var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: Binding(
                    get: { store.state.name },
                    set: { store.send(.nameChanged($0)) }
                ))
                TextField("Email", text: Binding(
                    get: { store.state.email },
                    set: { store.send(.emailChanged($0)) }
                ))
                #if os(iOS)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                #endif

                if let errorMessage = store.state.errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("New User")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { store.send(.cancel) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if store.state.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { store.send(.save) }
                    }
                }
            }
        }
    }
}
