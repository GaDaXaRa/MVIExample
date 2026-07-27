# ADR-0010: Model related users as a many-to-many relationship with a declared inverse

- **Status**: accepted
- **Date**: 2025-09-15

## Context

Users first had a single related user (`related: User?`). Deleting a user then
left a dangling reference: a self-referential to-one relationship has no
inverse, so SwiftData cannot know who points at the deleted row. The first fix
was a manual fetch-and-clear loop in the repository — imperative integrity
maintenance that every future relationship would have to repeat.

The requirement then grew to several related users per user, edited through a
list and a multi-select editor.

## Decision

`User.related` is a `[User]` many-to-many, with its inverse declared:

```swift
public var related: [User] = []

@Relationship(deleteRule: .nullify, inverse: \User.related)
public var relatedBy: [User] = []
```

The delete rule lives on the **inverse** (the "who refers to me" side), because
that is what SwiftData consults when deleting a user. `SetRelatedUserUseCase`
splits into `AddRelatedUserUseCase` (rejects self-relations, de-duplicates) and
`RemoveRelatedUserUseCase`.

## Alternatives considered

- **Keep clearing referrers manually in the repository** — worked, but is
  integrity by convention: every new relationship needs its own loop, and
  forgetting one is silent corruption.
- **A join entity (`Relation` with two sides)** — needed if the relation ever
  carries attributes (a role, a date); pure overhead while it does not.
- **Delete rule on `related` instead of the inverse** — governs the opposite
  direction; would not clean up referrers.

## Consequences

- Integrity is declarative: deleting a user removes it from everyone's
  `related`, and `DefaultUserRepository.remove` is back to `delete` + `save`.
- `relatedBy` is public (not merely an implementation detail) because the
  related-users list `@Query`s on it: *U is related to target ⟺ target is in
  U.relatedBy*.
- to-one → to-many is **not** a lightweight migration: existing installs must be
  reinstalled. Acceptable here (seed data), a real migration plan elsewhere.
- Enabled the three-screen flow — detail (count) → related list → multi-select
  editor — with no callbacks up the chain, since the relationship is observable.
