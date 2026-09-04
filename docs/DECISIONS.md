# Decisions

Architecture Decision Records for Activity Weather. Newest last. Status is Accepted unless noted.

## ADR-001: SwiftUI as the UI framework

**Context:** Native iOS 17+ client with two primary screens and no legacy UIKit surface.

**Decision:** Implement the UI in SwiftUI.

**Consequences:** Previews and Apple accessibility APIs are first-class. UIKit interop is not planned for the MVP.

## ADR-002: iOS 17 minimum deployment target

**Context:** `@Observable`, modern SwiftUI and Swift concurrency APIs should be available without availability branching.

**Decision:** `IPHONEOS_DEPLOYMENT_TARGET = 17.0` for the app and both test targets. iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`).

**Consequences:** Devices on iOS 16 and earlier are out of scope.

## ADR-003: Lightweight Clean Architecture

**Context:** Forecast retrieval, mapping and scoring must stay testable and independent of SwiftUI.

**Decision:** Three layers — Domain (models, repository protocols, use cases, scoring), Data (DTOs, mappers, networking, repository implementations), Features (screens). Folder depth is not the scalability mechanism; dependency direction is.

**Consequences:** Types are added when a milestone needs them. Empty placeholder types are not created to pre-fill folders.

## ADR-004: MVVM-style presentation

**Context:** Location search needs debounced queries with cancellation. The forecast screen needs fetch-then-score orchestration. Plain views would own too much async policy.

**Decision:** Feature ViewModels coordinate async work and expose `@Observable` presentation state. Views render state and forward user intent.

**Consequences:** ViewModels are unit-tested. Views stay thin.

## ADR-005: Apple frameworks only

**Context:** Scope is two HTTP JSON APIs and local scoring.

**Decision:** No third-party Swift packages. Use `URLSession`, `Codable` and Swift concurrency.

**Consequences:** No SPM dependencies in the project. Networking is typed in-house (milestone 4).

## ADR-006: Protocol-based initializer injection

**Context:** Tests need to replace geocoding, forecast and scoring collaborators.

**Decision:** Depend on protocols. Inject implementations through initializers. No service locators or singletons as the composition mechanism.

**Consequences:** Composition lives at the app boundary (milestone 8). Features do not look up global dependencies.

## ADR-007: No persistence in the MVP

**Context:** The product is “search a place, see a ranked week.” Recents and favourites are not required to demonstrate the scoring idea.

**Decision:** No Core Data, SwiftData, `UserDefaults` feature storage or file cache for MVP.

**Consequences:** Each session starts without saved locations. Networking failures are handled in memory (milestone 11).

## ADR-008: `@Observable` instead of `ObservableObject` / Combine

**Context:** Presentation state must update SwiftUI. Combine `ObservableObject` remains available but is more boilerplate under Swift 6 and is no longer Apple’s recommended default for new SwiftUI state.

**Decision:** Use the Observation framework (`@Observable`) for ViewModel state.

**Consequences:** Combine is not introduced for view observation. `async/await` remains the concurrency model.

## ADR-009: The Composable Architecture (TCA) rejected

**Context:** TCA can structure effects and testing, at the cost of a third-party dependency and substantial ceremony.

**Decision:** Reject TCA. The app has two screens and a small set of use cases; TCA’s runtime and reducer surface is unjustified overhead for this scope and conflicts with ADR-005.

**Consequences:** Testing uses protocols and in-memory fakes rather than a TCA TestStore.

## ADR-010: Plain MV (no ViewModel layer) rejected

**Context:** A View-only design would put debounce, task cancellation and forecast-then-score sequencing in SwiftUI views.

**Decision:** Reject plain MV. Those screens need a testable orchestration layer (see ADR-004).

**Consequences:** Views do not own `URLSession` or scoring. ViewModels do not own HTTP DTOs.

## ADR-011: Swift 6 language mode

**Context:** The machine used for milestone 1 has Xcode 26.2 (build 17C52) and Apple Swift 6.2.3. Leaving `SWIFT_VERSION` unset would inherit an unexplained Xcode default.

**Decision:** Set `SWIFT_VERSION = 6.0` at project and target level (Swift 6 language mode). Enable `SWIFT_APPROACHABLE_CONCURRENCY` on app and test targets so new Swift 6 concurrency defaults remain usable in application code without extra ceremony.

**Consequences:** Data races are compiler-diagnosed. Later milestones must treat isolation (`@MainActor` on ViewModels, sendable DTOs) as part of the design, not an afterthought.

## ADR-012: Display name vs module name

**Context:** The product name includes a space; Swift modules and xcodebuild paths should not.

**Decision:** User-visible name is **Activity Weather** (`CFBundleDisplayName` and placeholder copy). Project, targets, scheme, product name and Swift module remain **ActivityWeather**.

**Consequences:** Simulator bundle is `ActivityWeather.app`. SpringBoard label is Activity Weather.
