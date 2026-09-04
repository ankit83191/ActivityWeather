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

## ADR-013: Rule-based scoring (not binary rules, opaque formulas, or ML)

**Context:** The product must rank four activities for seven days and **explain why**. Open-Meteo returns physical quantities and WMO codes, not activity labels. Alternatives considered:

1. **Binary rules** (“ski if snow else don’t”) — easy to explain, but cannot rank a decent day above a marginal one, and cannot show partial suitability.
2. **Opaque weighted formulas** (unnamed coefficients, undocumented caps) — can rank, but fails the “inspect why” user flow and is untestable as a specification.
3. **Machine learning** — unjustified with no labelled dataset, conflicts with Apple-only MVP, and cannot emit stable reason codes without a second model.
4. **Rule-based scoring with named weights** — integer `0...100`, named contributions, explicit veto/cap/unavailable paths.

**Decision:** Use the rule-based model in [SCORING.md](SCORING.md). It is an **explainable product heuristic**, not a validated scientific model. Surfing is a Forecast **weather proxy**, not a Marine-API surf forecast.

**Consequences:** Milestone 7 implements the tables as deterministic pure functions with unit tests. Changing a threshold is a spec change, not a silent tweak in UI code.

## ADR-014: Complete forecast values and civil calendar dates in Domain

**Context:** A missing weather value is not the same as unsuitable weather, and
Foundation `Date` represents an instant rather than the location-local calendar
day ranked by this product. A single UTC offset is also wrong for a seven-day
window that crosses a daylight-saving transition.

**Decision:**

- `DailyForecast` contains every v1 scoring input as a non-optional value.
  Construction rejects non-finite numbers; negative precipitation, rain, snow,
  wind, gusts, UV and durations; precipitation hours outside `0...24`; and
  sunshine longer than daylight (`DomainError.invalidForecastValues`). It does
  **not** impose subjective real-world temperature or wind climate limits.
  Data mapping must still reject missing, null, non-aligned payload values
  before a `DailyForecast` reaches Domain (`DomainError.missingCriticalData`).
  Neither path manufactures a zero score.
- `CivilDate` is a validated Gregorian year/month/day value. It is
  `Comparable` by those components and models the Forecast API's daily `time`
  value without converting local midnight to a UTC instant.
- `WeeklyForecast` owns exactly seven unique, strictly chronological,
  consecutive civil dates and a validated IANA timezone identifier returned by
  the Forecast API. Domain does not store `utcOffsetSeconds`; the IANA timezone
  remains the source of truth across daylight-saving changes.
- `SuitabilityLevel` is derived only from `SuitabilityScore`, using the bands in
  [SCORING.md](SCORING.md). It cannot be supplied independently.
- `Activity.allCases` is stable display order only. The product ranks days
  within one activity; it does not rank activities against one another.
- `DailyActivitySuitability` is one activity on one civil date. Its `date` is
  taken from the scored `DailyForecast`, and `SuitabilityLevel` is derived from
  `SuitabilityScore`. `ActivityRanking` remains a later use-case type.
- Domain values and repository/scoring protocols crossing async boundaries
  conform to `Sendable`. `ActivityScoring` is a synchronous substitution
  boundary with no implementation in this milestone.

**Consequences:** Partial API payloads cannot masquerade as valid forecasts.
Data mapping has responsibility for structural validation. `WeeklyForecast`
imports Foundation only to validate `TimeZone`; the remaining Domain values use
the Swift standard library. Later use cases sort `[DailyActivitySuitability]`
by score descending, then `CivilDate` ascending.

## ADR-015: Typed HTTPS client without pinning, retries, or caching

**Context:** Milestone 4 needs a replaceable HTTP JSON client for later Open-Meteo
calls. The APIs are public, unauthenticated HTTPS JSON. Alternatives considered
included `URLSession.shared` as a hard-coded dependency, a retained shared
`JSONDecoder`, live-network tests, and certificate pinning.

**Decision:**

- Represent requests as an immutable `Sendable` `APIEndpoint` that builds URLs
  only through `URLComponents` and `URLQueryItem`.
- Inject `URLSession` into `URLSessionAPIClient`. Tests install a
  `URLProtocol` on an ephemeral configuration; production composition can pass
  any session. `URLSession.shared` is not an unreplaceable dependency.
- Create a new `JSONDecoder()` per request so concurrent `execute` calls do not
  share a mutable decoder.
- Treat only HTTP status `200...299` as success. Reject a non-`HTTPURLResponse`
  before decoding. Map other `URLError` values to `APIError.transport` while
  rethrowing `CancellationError` and `URLError.cancelled` unchanged.
- `APIError` carries HTTP status or the typed `URLError`. It does not store
  response bodies. `decoding` has no associated payload so decoder internals
  are not presented as user-facing context.
- App Transport Security plus HTTPS is appropriate for this exercise: Open-Meteo
  is a public HTTPS API with no client credentials in transit. ATS already
  blocks accidental cleartext. Certificate pinning is not used: there is no
  demonstrated threat model that requires pinning, and pinning would fail
  clients whenever the remote certificate rotates until an app update ships a
  new pin.

**Consequences:** Milestone 5 can add Open-Meteo endpoints and DTOs on top of
this client. Retries, caching, reachability, logging frameworks,
authentication, and generic POST/upload are out of scope until a later
requirement exists. `URLSessionAPIClient` is `@unchecked Sendable` because
`URLSession` is thread-safe for data tasks but is not `Sendable` in the SDK.

## ADR-016: Open-Meteo geocoding mapping and query short-circuit

**Context:** The official Geocoding API (`https://geocoding-api.open-meteo.com/v1/search`)
requires `name`, defaults `count` to 10, `language` to `en`, and `format` to
`json`. Empty and single-character searches return no `results`. Two characters
are an exact name match. Absent optional fields are omitted from JSON. The user
must pick among ambiguous matches; the app must not invent a location.

**Decision:**

- `OpenMeteoLocationRepository` trims the query and returns `[]` without a
  network call when the trimmed length is fewer than two characters. That
  matches the API matching rules. A later search use case must not add a
  conflicting minimum-length rule.
- Requests send `name` (trimmed), `count=10`, `language=en`, `format=json`.
  `countryCode` is omitted so international duplicates remain visible.
- Missing `results` or `results: []` map to `[]`. Mixed payloads keep every
  record that can become a Domain `Location` and skip the rest. A non-empty
  `results` array where **every** row is unusable throws
  `GeocodingError.noValidLocations` so the UI cannot treat a corrupt payload as
  “no matches.”
- Records are skipped when required `id`, `name`, `latitude`, `longitude`, or
  `country` are missing, blank after trim, or fail Domain `Coordinate`
  validation. Optional `admin1` and `timezone` become `nil` when blank.
  Placeholder country/region strings are not invented. `Location.id` is the
  official geocoding id.
- Wrong JSON types or an incompatible envelope fail `JSONDecoder` and surface
  as `APIError.decoding`. Result DTO numeric/string fields are not coerced
  from the wrong JSON type.
- DTOs and the mapper stay in Data. Cancellation and `APIError` values from
  `APIClient` pass through unchanged.

**Consequences:** Search UI (milestone 9) renders `[Location]` and mapping
failures separately. Forecast still uses Forecast `timezone=auto`, not the
optional geocoding timezone.

## ADR-017: Seven-day Forecast retrieval and closed mapping

**Context:** `docs/SCORING.md` requires `GET /v1/forecast` with metric units,
`forecast_days=7`, `timezone=auto`, and thirteen daily variables. Domain
`WeeklyForecast` accepts only seven consecutive `CivilDate` values and an IANA
timezone. Open-Meteo may omit keys, emit JSON nulls, or (if misconfigured)
return imperial units. A live metric response listed `uv_index_max` unit as an
empty string.

**Decision:**

- `forecast_days=7` means the location’s current local calendar day plus the
  following six local days. The mapper does **not** compare `daily.time[0]`
  with the device clock; it only validates seven consecutive civil dates.
- Request `timezone=auto` and store the returned IANA identifier. Do not
  persist `utc_offset_seconds` or use it to parse dates. Parse `YYYY-MM-DD`
  into `CivilDate` without converting through a UTC midnight `Date`.
- Serialize latitude/longitude with `en_US_POSIX` so the decimal separator is
  always `.`, without rounding away precision.
- DTOs use optional containers and optional elements so missing keys and null
  elements become `DomainError.missingCriticalData`. Wrong JSON types fail
  `JSONDecoder` (`APIError.decoding` via `APIClient`).
- Unexpected `daily_units` throw Data-layer
  `ForecastMappingError.unexpectedUnit`. Metric units are accepted, including
  an empty or `"Index"` UV unit. Domain errors remain
  `invalidCivilDate`, `invalidForecastValues`, `invalidForecastTimezone`, and
  `invalidForecastWindow`.
- Fewer or extra days are **not** truncated; `WeeklyForecast` rejects them as
  `invalidForecastWindow`. Array length mismatches fail closed as
  `missingCriticalData`.

**Consequences:** Scoring (milestone 7) receives only structurally complete
weeks. Presentation maps `ForecastMappingError` later; it is not user-facing
copy.

## ADR-018: Single-day scoring protocol and explainable ranking

**Context:** Milestone 7 implements `docs/SCORING.md` as a pure Domain engine.
Tests need a small substitution boundary. Ranking seven days is mechanical
once daily scores exist. `SuitabilityScore`’s validating initializer throws,
so production rounding must not use `try!`. Polar night allows
`daylight_duration == 0`.

**Decision:**

- `ActivityScoring` requires only `suitability(for:activity:)`. Weekly ranking
  is a default protocol extension `rankedSuitability(for:activity:)`: score
  descending, then `CivilDate` ascending. No `ActivityRanking` type and no
  separate ranking service.
- `SuitabilityScore.init(_:)` still throws outside `0...100`.
  `SuitabilityScore.init(clamping:)` is the non-throwing factory used by the
  engine after rounding.
- `daylightDuration == 0` → sunshine ratio `0` (no divide-by-zero / `NaN`).
- Reasons: only rules that changed the score; deduplicated; veto/cap first;
  then absolute contribution descending; ties by `SuitabilityReason.rawValue`.
  Outdoor veto skips additives. Indoor never uses the outdoor veto; the
  indoor cap applies after additives and emits `dangerousTravelCap` only when
  raw exceeds 40. Combined outdoor vetoes use thunderstorm → freezing rain →
  extreme gust. UI later still shows raw weather values.

**Consequences:** Test doubles implement one method. Ranking behaviour has one
canonical implementation. Weights stay in `docs/SCORING.md`.

## ADR-019: Use cases and a live composition factory

**Context:** Presentation must run search and forecast-then-score workflows
without knowing Open-Meteo, DTOs, or `URLSession`. Injecting a whole
dependency container into views would let any screen reach any service.

**Decision:**

- `SearchLocationsUseCase` trims whitespace/newlines and delegates once to
  `LocationRepository`. It does not apply a second minimum-length
  short-circuit (ADR-016 stays in `OpenMeteoLocationRepository`).
- `GetActivityForecastUseCase` fetches `WeeklyForecast` once, then ranks all
  four `Activity.allCases` in display order via `ActivityScoring`. The Domain
  result is `LocationActivityForecast` / `ActivityDayRanking` (scores and raw
  weather, no UI formatting).
- `AppDependencies.live(client:)` is the single composition factory: one
  shared `APIClient`, both Open-Meteo repositories, `SuitabilityScoringEngine`,
  both use cases. No `static let shared`, environment objects, or service
  lookup.
- Milestone 8 does **not** wire `AppDependencies` into `ContentView` or
  `ActivityWeatherApp`. Milestone 9 will construct the search ViewModel from
  `AppDependencies` and inject only that narrow dependency.

**Consequences:** ViewModels receive use cases (or similarly narrow types)
through initializers. Domain still does not import Data. Placeholder UI is
unchanged until search UI exists.

## ADR-020: Debounced location-search presentation

**Context:** Search-as-you-type must avoid unnecessary requests, cancel
obsolete work, and never let a late response replace a newer query. A
one-character query intentionally produces no repository request, so showing
it as a genuine empty result would be misleading.

**Decision:**

- `@MainActor @Observable LocationSearchViewModel` owns explicit idle,
  loading, results, empty, and generic failure states. Mutation is private
  outside intent methods.
- Typing waits 350 ms through an injected cancellation-aware `SearchSleeping`
  dependency. Submit and retry bypass the delay. Task, sleeper, use case, and
  request generation are implementation-only Observation state.
- Empty and trimmed one-character queries remain idle and do not invoke the
  use case. The ViewModel check is presentation policy (accurate helper copy
  and less work); the repository retains its separate `< 2` guard as
  defensive enforcement at the external API boundary.
- Every new query, submit, or retry cancels prior work. A generation check and
  task cancellation prevent stale values and errors from changing visible
  state. Cancellation itself is not a failure.
- Selection stores only the chosen Domain `Location`. Navigation remains
  deferred; the selected row visibly and accessibly shows a checkmark.
- `ActivityWeatherApp` creates `AppDependencies.live()`, constructs the
  ViewModel from only `SearchLocationsUseCase`, owns it with `@State`, and
  injects only the ViewModel into `LocationSearchView`. The container never
  enters presentation. Obsolete `ContentView` is removed.

**Consequences:** Feature files stay flat under `Features/LocationSearch`.
A presentation subfolder can be introduced if the feature grows enough to
need one; it adds no value at this scale. Forecast navigation is Milestone 10.
