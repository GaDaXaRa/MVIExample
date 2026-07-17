import Observation
import SwiftUI

/// The MVI contract every feature implements:
/// - `State` (Model): a single struct describing everything the view needs to render.
/// - `Intent`: every user action or lifecycle event the view can produce.
/// - `send(_:)`: the one and only entry point that turns an Intent into a new State.
///
/// State flows one way: View -> Intent -> Store -> State -> View.
/// `Observable` (not `ObservableObject`/`@Published`) is what lets SwiftUI observe
/// only the exact properties a view reads, with no boilerplate.
/// Main-actor-bound via the module's default isolation — no annotation needed.
public protocol Store<State, Intent>: AnyObject, Observable {
    associatedtype State
    associatedtype Intent

    var state: State { get }
    func send(_ intent: Intent)
}

extension Store {
    /// Two-way binding that routes every write through an Intent, so form
    /// fields can't mutate state behind the store's back:
    ///
    ///     TextField("Name", text: store.binding(\.name, send: AddUserIntent.nameChanged))
    public func binding<Value>(
        _ keyPath: KeyPath<State, Value>,
        send intent: @escaping (Value) -> Intent
    ) -> Binding<Value> {
        Binding {
            self.state[keyPath: keyPath]
        } set: { newValue in
            self.send(intent(newValue))
        }
    }
}
