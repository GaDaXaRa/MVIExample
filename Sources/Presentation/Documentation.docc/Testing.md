# Testing Strategy

Every layer tested in isolation, against the layer below it faked out.

## Overview

No test touches the real network or a real store. All tests use the **Swift
Testing** framework (`import Testing`, `@Test`, `#expect`), not XCTest.

| Target              | Fakes                              | Verifies                                              |
|---------------------|------------------------------------|------------------------------------------------------|
| `DomainTests`       | `UserRepository`                   | Use-case business rules (validation, self-relation)  |
| `DataTests`         | `RemoteUserDataSource`             | Repository merge/persistence policy                  |
| `PresentationTests` | Use cases and flows (spies)        | Store state transitions; flow route/mode decisions   |

Business rules are proven without any implementation. `@Test(arguments:)` runs one
assertion over many inputs:

```swift
@Test("rejects malformed emails", arguments: ["not-an-email", "missing-at.com", "missing-dot@example"])
func rejectsInvalidEmail(email: String) async throws {
    let sut = DefaultAddUserUseCase(repository: FakeUserRepository())
    await #expect(throws: UserValidationError.invalidEmail) {
        _ = try await sut.execute(name: "Ada Lovelace", email: email)
    }
}
```

## Testing the split navigation

Because policy and mechanism are separate, tests are too. A **store** test asserts
the semantic event reached a flow spy — never a concrete destination:

```swift
sut.send(.selectUser(user))
#expect(flow.selectedUsers == [user])
```

A **flow** test asserts the resulting router intent, including nested-modal
behavior like a dismiss bubbling to the parent:

```swift
sut.didSelectUser(picked)
#expect(target.related === picked)
#expect(parent.presentedSheet == nil)   // child dismissed, bubbled up
```

## Async stores

Stores fire async work via `Task { }` inside a synchronous `send`, so tests poll
with a small `waitUntil` helper instead of an arbitrary `sleep`:

```swift
sut.send(.onAppear)
try await waitUntil { refresh.calls == 1 }
```

Run everything with `swift test`; each target runs in isolation
(`swift test --filter DomainTests`) since they don't depend on each other.
