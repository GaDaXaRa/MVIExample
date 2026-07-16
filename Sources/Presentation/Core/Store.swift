import Observation

/// The MVI contract every feature implements:
/// - `State` (Model): a single struct describing everything the view needs to render.
/// - `Intent`: every user action or lifecycle event the view can produce.
/// - `send(_:)`: the one and only entry point that turns an Intent into a new State.
///
/// State flows one way: View -> Intent -> Store -> State -> View.
/// `Observable` (not `ObservableObject`/`@Published`) is what lets SwiftUI observe
/// only the exact properties a view reads, with no boilerplate.
@MainActor
public protocol Store<State, Intent>: AnyObject, Observable {
    associatedtype State
    associatedtype Intent

    var state: State { get }
    func send(_ intent: Intent)
}
