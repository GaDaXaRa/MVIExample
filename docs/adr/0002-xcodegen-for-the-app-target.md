# ADR-0002: Generate the App target with XcodeGen instead of committing an .xcodeproj

- **Status**: accepted
- **Date**: 2025-09-12

## Context

`Domain`, `Data` and `Presentation` are SPM library targets, but the app itself
must be installable and runnable on a simulator. An SPM `executableTarget`
compiles fine against the iOS Simulator SDK yet never produces an installable
`.app` bundle (no app-product Info.plist generation, no app code signing).

A hand-authored `.xcodeproj` is a large, undocumented, merge-hostile format that
drifts from the package it is supposed to mirror.

## Decision

`Sources/App` is declared as a native Xcode "iOS App" target in `project.yml`
and generated on demand with `xcodegen generate`. The generated
`MVIExample.xcodeproj` (and the generated `Sources/App/Info.plist`) are
gitignored; `project.yml` is the committed source of truth.

## Alternatives considered

- **Commit the `.xcodeproj`** — the default Xcode flow, but it becomes a
  merge-conflict magnet and can silently disagree with `Package.swift`.
- **SPM `executableTarget` for the app** — cannot yield an installable bundle,
  and sharing the name `App` with a native target invites collisions.
- **Tuist** — more capable (and generates too), but heavier than this project
  needs; XcodeGen's single YAML file is proportionate.

## Consequences

- The project file cannot drift from its spec: it is regenerated, never edited.
- Anyone cloning the repo must run `xcodegen generate` before opening Xcode,
  and must have XcodeGen installed.
- Settings that Xcode's UI would normally own (URL schemes, localizations,
  `SWIFT_DEFAULT_ACTOR_ISOLATION`) are edited as YAML — which is also how they
  stay reviewable in a diff.
- Once an explicit `info:` block was needed (for `CFBundleURLTypes`, an array),
  `GENERATE_INFOPLIST_FILE` was dropped in favor of a generated plist.
