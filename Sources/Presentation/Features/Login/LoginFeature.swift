import Observation

// MARK: - Flow

/// What logging in *means* (starting a session, here) is the flow's decision,
/// not this feature's: tomorrow it could also restore pending deep links.
public protocol LoginFlow {
    func didLogIn()
}

// MARK: - Intent

public enum LoginIntent {
    case logInTapped
}

// MARK: - Store

/// Stateless on purpose: this sample's login is just a gate. Credentials,
/// validation and errors would live in a `LoginState` exactly like AddUser's.
@Observable
public final class LoginStore: Store {
    public let state: Void = ()

    private let flow: any LoginFlow

    public init(flow: any LoginFlow) {
        self.flow = flow
    }

    public func send(_ intent: LoginIntent) {
        switch intent {
        case .logInTapped:
            flow.didLogIn()
        }
    }
}
