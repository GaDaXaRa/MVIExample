# The MVI Loop

State flows one way: View → Intent → Store → State → View.

## Overview

Every screen is built from three pieces that always appear together, plus one
`Store` that ties them into a loop:

```
      ┌────────────────────────────────────────────┐
      │                                              │
      ▼                                              │
   ┌──────┐   send(Intent)   ┌───────┐   mutates   ┌───────┐
   │ View │ ───────────────► │ Store │ ──────────► │ State │
   └──────┘                  └───────┘             └───────┘
      ▲                                                  │
      └──────────────── @Observable re-render ───────────┘
```

- **Model** — a plain `State` struct: everything the view needs, nothing it doesn't.
- **Intent** — an `enum` of every action the view can produce.
- **Store** — the only place that turns an `Intent` into a new `State`.

The contract every feature implements is `Store`. It uses the Swift Observation
framework, not `ObservableObject`/`@Published`: a view that reads `store.state.name`
re-renders only when `name` changes, with no per-field boilerplate.

## A feature end to end

``UserListStore`` handles lifecycle and refresh, and reports everything else to its
flow (see <doc:NavigationDesign>):

```swift
public func send(_ intent: UserListIntent) {
    switch intent {
    case .onAppear, .refresh: Task { await refresh() }
    case .selectUser(let user): flow.didSelectUser(user)
    case .addUserTapped:        flow.didRequestAddUser()
    // ...
    }
}
```

Note what is *not* in ``UserListState``: the users. They reach the view through
`@Query`, which observes SwiftData directly — the Model half of the loop:

```swift
// Sources/Presentation/Features/UserList/UserListView.swift
@Query(sort: \User.name) private var users: [User]
```

SwiftData is the single source of truth and `@Query` is its change-propagation
mechanism, replacing any hand-rolled stream or cross-feature callback.

## Two rules keep the pattern honest

1. **`send` never does async work directly.** It wraps it in `Task { }` and returns
   immediately, so the View's action stays synchronous and non-blocking.
2. **Only the Store mutates `state`.** Views read it and call `send`. For form
   fields, `Store.binding(_:send:)` builds a `Binding` whose setter routes through
   an Intent, so even two-way controls can't mutate state behind the store's back:

   ```swift
   TextField("Name", text: store.binding(\.name, send: AddUserIntent.nameChanged))
   ```

## Views depend on the contract, not the class

Each view stores `any Store<State, Intent>` — the protocol has primary associated
types, so no type-erasing wrapper is needed. That is what lets every screen have a
`#Preview` backed by `PreviewStore`, a generic stub with fixed state and no-op
intents, without wiring use cases or a repository behind it. Chrome that varies by
context (``UserListView`` in `.browse` vs `.picker` mode) is a ``UserListMode``
parameter; behavior that varies stays in the flow.

## Topics

- ``UserListStore``
- ``UserDetailStore``
- ``AddUserStore``
- <doc:NavigationDesign>
