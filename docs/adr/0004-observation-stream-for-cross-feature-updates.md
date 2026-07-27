# ADR-0004: Propagate cross-feature changes with a repository `AsyncStream`

- **Status**: superseded by [ADR-0003](0003-swiftdata-model-as-the-domain-entity.md)
- **Date**: 2025-09-13

## Context

Marking a user as favorite in the detail screen did not update the list.
`UserListStore` held its own `[User]` snapshot, loaded once; nothing
invalidated it when the cache changed. The same class of bug had already been
patched by hand for "add user" with a `userWasAdded` callback from the modal
back into the list — a wire that would have to be added again for every future
cross-feature effect.

## Decision

The local store broadcasts an `AsyncStream<[User]>` snapshot after every
mutation, exposed through `UserRepository.observeUsers()` and an
`ObserveUsersUseCase`. `UserListStore` subscribes when it receives `.onAppear`,
making the stream the single source of truth for its `state.users`.

## Alternatives considered

- **Keep pushing callbacks between stores** — what already existed; couples
  features pairwise and grows with every new interaction.
- **Combine / NotificationCenter / an event bus** — same idea with more
  machinery, and untyped in the last two cases.
- **SwiftData `@Query`** — was on the table and eventually won
  ([ADR-0003](0003-swiftdata-model-as-the-domain-entity.md)); rejected at this
  point because it required making the Domain entity a `@Model`.

## Consequences

- Fixed the bug at its root and removed the `userWasAdded` callback.
- Domain stayed framework-free — the stream is plain Swift concurrency.
- But: continuation bookkeeping in the store, subscription lifecycle in each
  consumer, and a second copy of the data living in `state.users`.
- Superseded weeks later by `@Query`, which is the framework's own version of
  exactly this mechanism. The stream is preserved in history at commit
  `0513b12` as the framework-free alternative.
