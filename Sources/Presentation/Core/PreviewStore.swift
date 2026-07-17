import Observation

/// A `Store` stub for SwiftUI previews: fixed state, intents are no-ops.
/// Views depend on `any Store<State, Intent>` — the contract, not a concrete
/// class — so any screen can be previewed without wiring use cases or a
/// repository behind it.
@Observable
public final class PreviewStore<State, Intent>: Store {
    public private(set) var state: State

    public init(state: State) {
        self.state = state
    }

    public func send(_ intent: Intent) {}
}
