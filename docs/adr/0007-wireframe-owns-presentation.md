# ADR-0007: A wireframe view owns all presentation; modals nest as child wireframes

- **Status**: accepted
- **Date**: 2025-09-14

## Context

With routes as values ([ADR-0006](0006-routes-as-values-with-a-destination-registry.md)),
something must own the containers that present them. Views that carry their own
`NavigationStack` and dismiss logic cannot be reused across contexts: the
add-user form had a `NavigationStack` and therefore behaved differently when
pushed than when sheeted.

Later requirements raised the bar: a session gate covering everything, a tab bar
where each tab keeps independent navigation, and a modal that itself opens
another modal and shows alerts — with an inner screen able to close the modal it
lives in, without knowing who presented it.

## Decision

`WireframeView` is a superior view that owns **every** presentation container:
the `NavigationStack`, the sheet, the fullscreen cover and the alert. Destination
views contain no navigation chrome at all.

Every modal it presents is wrapped in a **child wireframe** with its own
`AppRouter(parent:)` — its own stack, modals and alerts. `RouterIntent.dismiss`
closes the modal this wireframe presented, or, when it presented none, bubbles
to the parent. Alerts join the same vocabulary as a presentation
(`RouterIntent.alert(AlertContent)`).

Wireframes also *multiply*: each tab is a wireframe with its own router, and the
routers live in the composition root rather than the view tree.

## Alternatives considered

- **Each view owns its `NavigationStack`** — the SwiftUI default; makes screens
  non-reusable across presentation modes.
- **A single global router** — cannot express per-tab stacks or a modal's own
  navigation; `dismiss` becomes ambiguous.
- **Result callbacks from modals** — unnecessary once the model is observable
  ([ADR-0003](0003-swiftdata-model-as-the-domain-entity.md)): a modal mutates
  through a use case and the screens behind it re-render on their own.

## Consequences

- The same view works pushed, sheeted or covered; `AddUserView` lost its
  `NavigationStack` and its toolbar works identically in every mode.
- A fullscreen cover has no swipe-to-dismiss, so "closable only via Cancel" is
  satisfied by choosing the presentation, not by fighting the framework.
- Navigation state survives tab switches **and session expiry**: because the
  routers are owned by the composition root, logging back in restores every
  stack and modal exactly as they were.
- Registry builders must receive the presenting wireframe's router, so a screen
  inside a modal acts on that modal's context.
- A small private `ChildWireframeView` exists to own the child router's lifetime
  (`@State`) and to resolve the route in `body` rather than in `init` — resolving
  in `init` would bind the content to a router the view tree discards.
- Not implemented: a modal's stack has no separate path in the parent router, so
  deep-linking *into* a nested modal is out of scope for now.
