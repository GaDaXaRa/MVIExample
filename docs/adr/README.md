# Architecture Decision Records

Each ADR captures **why** a decision was made, which alternatives lost, and what
it costs — the part the DocC catalogs (which describe how the system works
*today*) deliberately leave out.

ADRs are immutable: when a decision changes, add a new record that supersedes
the old one instead of editing it. The trail matters — ADR-0004 is kept
precisely because the app shipped a hand-rolled observation stream before
SwiftData replaced it.

Only decisions that are expensive to reverse belong here. Reversible or obvious
choices are just code.

| # | Decision | Status |
|---|----------|--------|
| [0001](0001-clean-architecture-with-mvi.md) | Clean Architecture + MVI, enforced by SPM targets | accepted |
| [0002](0002-xcodegen-for-the-app-target.md) | Generate the App target with XcodeGen | accepted |
| [0003](0003-swiftdata-model-as-the-domain-entity.md) | SwiftData `@Model` as the Domain entity; `@Query` as the Model of MVI | accepted |
| [0004](0004-observation-stream-for-cross-feature-updates.md) | Cross-feature updates via a repository `AsyncStream` | superseded by 0003 |
| [0005](0005-main-actor-by-default.md) | Swift 6.2 default MainActor isolation | accepted |
| [0006](0006-routes-as-values-with-a-destination-registry.md) | Routes as values, resolved by a destination registry | accepted |
| [0007](0007-wireframe-owns-presentation.md) | A wireframe owns all presentation; modals nest | accepted |
| [0008](0008-flows-separate-navigation-policy-from-mechanism.md) | Flows (policy) separated from the router (mechanism) | accepted |
| [0009](0009-deep-links-over-value-routes.md) | Deep links build the same route values as in-app flows | accepted |
| [0010](0010-many-to-many-related-users.md) | Many-to-many related users with a declared inverse | accepted |
| [0011](0011-extract-wireframe-as-its-own-package.md) | Extract the domain-agnostic core into its own package | accepted |
| [0012](0012-docc-catalogs-over-monolithic-markdown.md) | DocC catalogs instead of one architecture markdown | accepted |
| [0013](0013-consume-wireframe-as-a-remote-package.md) | Consume Wireframe as a remote package from its own repository | accepted |

New records start from [the template](0000-template.md).
