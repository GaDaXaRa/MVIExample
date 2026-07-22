import Observation

/// App-wide session state. Like the router, it is a side-effect service —
/// deliberately not a feature `State`: whether the user is authenticated is
/// not "what a screen looks like". The root view observes it to swap between
/// the login screen and the main content; flows mutate it.
@Observable
public final class SessionStore {
    public private(set) var isAuthenticated = false

    public init() {}

    public func logIn() {
        isAuthenticated = true
    }

    /// Ends the session (e.g. a timeout). The root view reacts by covering
    /// everything with the login screen; navigation state stays untouched in
    /// the routers, so the app resumes exactly where it was after re-login.
    public func expire() {
        isAuthenticated = false
    }
}
