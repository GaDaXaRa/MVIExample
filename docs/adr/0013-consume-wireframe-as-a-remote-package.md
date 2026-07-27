# ADR-0013: Consume Wireframe as a remote package from its own repository

- **Status**: accepted
- **Date**: 2026-07-27
- **Follows**: [ADR-0011](0011-extract-wireframe-as-its-own-package.md)

## Context

[ADR-0011](0011-extract-wireframe-as-its-own-package.md) extracted the
domain-agnostic core into a separate local package and deliberately deferred
publishing it, noting the reuse payoff was still theoretical with one consumer.

The kit has since stayed inside its boundary — it still imports only SwiftUI and
Observation — and acquired its own tests, DocC catalog and README. Keeping it as
a subdirectory of this app meant nobody else could use it without vendoring a
folder, and its history stayed mixed with an app it knows nothing about.

## Decision

Wireframe lives in [GaDaXaRa/swift-wireframe](https://github.com/GaDaXaRa/swift-wireframe)
and this app depends on it as a versioned remote package:

```swift
.package(url: "https://github.com/GaDaXaRa/swift-wireframe.git", from: "1.0.0")
```

The `Wireframe/` directory is removed from this repository. The three ADRs that
explain the kit's design (0006, 0007, 0011) were **copied** to the new
repository and renumbered there; they remain here because they are also part of
this app's decision trail.

The repository is named `swift-wireframe` while the package and module keep the
name `Wireframe` — the convention used across the Swift ecosystem
(`apple/swift-collections` vends `Collections`). Note that SPM derives package
*identity* from the URL, so product references read
`.product(name: "Wireframe", package: "swift-wireframe")`.

## Alternatives considered

- **Keep the local path dependency** — no release ceremony and atomic changes
  across both, but the kit stays unusable by anyone else, which was the point of
  extracting it.
- **Git submodule** — keeps sources in the working copy and pins a commit, but
  submodules are a well-known source of contributor friction, and SPM already
  resolves versioned dependencies natively.
- **Name the repository `Wireframe`** — matches the module exactly, but
  `swift-` prefixed repositories are the ecosystem convention for Swift
  packages, and the bare name is generic on a public account.

## Consequences

- The kit is installable by anyone and versioned independently.
- Changes to it are no longer atomic with app changes: a kit fix now needs a
  tag before this app can consume it. That friction is the boundary being real.
- Breaking changes surface as a resolution/version decision instead of a
  compile error in one workspace, so the kit needs semantic versioning
  discipline.
- Local development against an unreleased kit requires a temporary
  `.package(path:)` override, which must not be committed.
- Both DocC catalogs still build; the app's catalog keeps referring to kit types
  as plain code spans, since cross-package symbol links do not resolve.
