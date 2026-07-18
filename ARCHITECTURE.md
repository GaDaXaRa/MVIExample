# Architecture

The full architecture documentation now lives in a **DocC catalog** in the
`Presentation` target, so it renders inside Xcode's documentation viewer
(⇧⌘0) with live links to the real symbols (`Store`, `Router`, `WireframeView`…)
and stays wired to the API it describes.

## Read it

- **In Xcode**: Product → Build Documentation (⌃⇧⌘D), then open
  *Presentation* in the documentation window.
- **From the command line** (uses [swift-docc-plugin](https://github.com/swiftlang/swift-docc-plugin),
  already a package dependency):

  ```sh
  swift package generate-documentation --target Presentation
  ```

  Add `--transform-for-static-hosting` to produce an archive publishable to
  GitHub Pages.

## What's inside

The catalog (`Sources/Presentation/Documentation.docc/`) is organized as:

| Article | Covers |
|---------|--------|
| **Presentation** (landing) | The two ideas — Clean Architecture + MVI — and the module graph |
| **Clean Architecture and the Dependency Rule** | Layers, the compiler-enforced dependency rule, Domain and Data |
| **The MVI Loop** | `State` / `Intent` / `Store`, `@Query` as the Model, bindings, previews |
| **Navigation** | Flows (policy) vs the Router (mechanism), route values, nested & multiplied wireframes, the session gate |
| **The Composition Root** | Wiring concrete types to protocols; concurrency choices |
| **Testing Strategy** | Layer-by-layer testing with Swift Testing |

To have an AI agent replicate this pattern for a different app, see
[AGENT_GUIDE.md](AGENT_GUIDE.md), which is kept in the repo root because its
audience is tooling that reads the repository, not Xcode.
