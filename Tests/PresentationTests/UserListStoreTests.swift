import Testing
import Foundation
import Domain
@testable import Presentation

@Suite("UserListStore")
struct UserListStoreTests {
    private func makeSut(
        refresh: FakeRefreshUsersUseCase = FakeRefreshUsersUseCase(),
        remove: FakeRemoveUserUseCase = FakeRemoveUserUseCase(),
        removeRelated: FakeRemoveRelatedUserUseCase = FakeRemoveRelatedUserUseCase(),
        flow: UserListFlowSpy = UserListFlowSpy()
    ) -> UserListStore {
        UserListStore(refreshUsers: refresh, removeUser: remove, removeRelated: removeRelated, flow: flow)
    }

    @Test("onAppear triggers a remote refresh")
    func onAppearTriggersRefresh() async throws {
        let refresh = FakeRefreshUsersUseCase()
        let sut = makeSut(refresh: refresh)

        sut.send(.onAppear)
        try await waitUntil { refresh.calls == 1 }

        #expect(refresh.calls == 1)
        #expect(sut.state.errorMessage == nil)
    }

    @Test("a failed refresh surfaces the error message")
    func failedRefreshSurfacesError() async throws {
        struct SampleError: Error, Sendable, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        let refresh = FakeRefreshUsersUseCase()
        refresh.errorToThrow = SampleError()
        let sut = makeSut(refresh: refresh)

        sut.send(.refresh)
        try await waitUntil { sut.state.errorMessage != nil }

        #expect(sut.state.errorMessage == "boom")
        #expect(sut.state.isLoading == false)
    }

    @Test("selecting a user reports it to the flow — the store never picks the destination")
    func selectUserReportsToFlow() {
        let flow = UserListFlowSpy()
        let sut = makeSut(flow: flow)
        let user = User(name: "Ada Lovelace", email: "ada@example.com")

        sut.send(.selectUser(user))

        #expect(flow.selectedUsers == [user])
    }

    @Test("tapping add reports the request to the flow")
    func addUserTappedReportsToFlow() {
        let flow = UserListFlowSpy()
        let sut = makeSut(flow: flow)

        sut.send(.addUserTapped)

        #expect(flow.addUserRequests == 1)
    }

    @Test("picker, end-session and cancel intents are forwarded to the flow")
    func chromeIntentsAreForwarded() {
        let flow = UserListFlowSpy()
        let sut = makeSut(flow: flow)

        sut.send(.userPickerTapped)
        sut.send(.endSessionTapped)
        sut.send(.cancelTapped)

        #expect(flow.userPickerRequests == 1)
        #expect(flow.endSessionRequests == 1)
        #expect(flow.cancellations == 1)
    }

    @Test("removing a related user forwards to the use case")
    func removeRelatedForwardsToUseCase() {
        let removeRelated = FakeRemoveRelatedUserUseCase()
        let sut = makeSut(removeRelated: removeRelated)
        let target = User(name: "Ada Lovelace", email: "ada@example.com")
        let related = User(name: "Alan Turing", email: "alan@example.com")
        target.related = [related]

        sut.send(.removeRelated(related, from: target))

        #expect(removeRelated.calls.count == 1)
        #expect(target.related.isEmpty)
        #expect(sut.state.errorMessage == nil)
    }
}

/// Stores kick off work with `Task { ... }` from a synchronous `send`, so tests
/// poll briefly instead of assuming the update already landed by the next line.
func waitUntil(timeout: Duration = .seconds(1), _ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now + timeout
    while !condition(), ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(5))
    }
}
