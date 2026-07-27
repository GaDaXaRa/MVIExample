# Architecture

The full architecture documentation lives in **DocC catalogs**, so it renders
inside Xcode's documentation viewer (⇧⌘0) with live links to the real symbols
and stays wired to the API it describes. There are two:

- **Presentation** (`Sources/Presentation/Documentation.docc/`) — how *this app*
  is built: layers, the MVI loop, navigation, composition, testing.
- **Wireframe** — the domain-agnostic MVI + navigation kit this app is built on,
  with an adoption guide for reusing it. It lives in its own repository,
  [GaDaXaRa/swift-wireframe](https://github.com/GaDaXaRa/swift-wireframe), and
  is consumed here as a versioned package dependency.

## Read it

- **In Xcode**: Product → Build Documentation (⌃⇧⌘D), then open *Presentation*
  in the documentation window (*Wireframe* appears too, as a dependency).
- **From the command line** (uses [swift-docc-plugin](https://github.com/swiftlang/swift-docc-plugin),
  already a dependency):

  ```sh
  swift package generate-documentation --target Presentation
  ```

  Add `--transform-for-static-hosting` to produce archives publishable to
  GitHub Pages.

## What's inside

The **Presentation** catalog:

| Article | Covers |
|---------|--------|
| **Presentation** (landing) | The two ideas — Clean Architecture + MVI — and the module graph (including the Wireframe package) |
| **Clean Architecture and the Dependency Rule** | Layers, the compiler-enforced dependency rule, the SwiftData `@Model` entity trade-off, Domain and Data |
| **The MVI Loop** | `State` / `Intent` / `Store`, `@Query` as the Model, bindings, previews |
| **Navigation** | Flows (policy) vs the Router (mechanism), route values, nested & multiplied wireframes, the session gate, deep links |
| **The Composition Root** | Wiring concrete types to protocols; concurrency choices (main-actor by default) |
| **Testing Strategy** | Layer-by-layer testing with Swift Testing |

The **Wireframe** catalog (in [its own repository](https://github.com/GaDaXaRa/swift-wireframe)):

| Article | Covers |
|---------|--------|
| **Wireframe** (landing) | What the kit is: the `Store` contract, intent-based value routing, nesting wireframes, the session gate |
| **Adopting Wireframe in an App** | The four-move recipe (routes → registry → wireframes → flows), why routes are values, testing against the router |

## Why it is this way

The catalogs describe how the system works *today*. The **why** — the
alternatives that were considered and lost, and what each choice costs — lives
in [Architecture Decision Records](docs/adr/README.md): the SwiftData `@Model`
trade-off, routes as values instead of view builders, flows versus the router,
extracting the Wireframe package, and the rest.

To have an AI agent replicate this pattern for a different app, see
[AGENT_GUIDE.md](AGENT_GUIDE.md), which is kept in the repo root because its
audience is tooling that reads the repository, not Xcode.
