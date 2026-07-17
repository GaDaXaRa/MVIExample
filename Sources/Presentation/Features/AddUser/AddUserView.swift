import SwiftUI

/// Presentation-agnostic: no `NavigationStack`, no dismiss logic, no idea
/// whether it is on a sheet, a cover or a pushed screen. The wireframe
/// provides the navigation chrome; dismissal happens through router intents.
public struct AddUserView: View {
    // The existential (`any Store<State, Intent>`) decouples the view from the
    // concrete store class: previews and tests can back the same view with a
    // stub. `@State` makes the view own the instance across parent re-renders.
    @State private var store: any Store<AddUserState, AddUserIntent>

    public init(store: any Store<AddUserState, AddUserIntent>) {
        _store = State(initialValue: store)
    }

    public var body: some View {
        Form {
            TextField("Name", text: store.binding(\.name, send: AddUserIntent.nameChanged))
            TextField("Email", text: store.binding(\.email, send: AddUserIntent.emailChanged))
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

#Preview {
    var state = AddUserState()
    state.name = "Ada Lovelace"
    state.email = "ada@example.com"
    return NavigationStack {
        AddUserView(store: PreviewStore(state: state))
    }
}
