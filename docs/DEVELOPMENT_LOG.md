# Development log

## 2026-09-04 — Milestone 1: project scaffold and engineering plan

### Toolchain (inspected, not assumed)

- Xcode 26.2 (build 17C52)
- Apple Swift 6.2.3 (`swift-driver` 1.127.14.1, `swiftlang-6.2.3.3.21`)
- `xcode-select -p` → `/Users/apatel14/Downloads/Xcode.app/Contents/Developer`

Swift language mode is **6.0** (`SWIFT_VERSION = 6.0` on the project and every target). This is an explicit setting, not an inherited Xcode default (ADR-011).

### What shipped

- `ActivityWeather.xcodeproj` with app target `ActivityWeather`, unit-test target `ActivityWeatherTests`, UI-test target `ActivityWeatherUITests`
- Shared scheme `ActivityWeather`: app in Build; both test targets in Test
- SwiftUI entry (`ActivityWeatherApp`) and placeholder `ContentView` showing “Activity Weather” and “Weather-based activity rankings” only
- iOS 17.0 deployment target, iPhone and iPad
- `.gitignore` for DerivedData, `.derivedData/`, build products and user-specific Xcode files
- README skeleton and `docs/APPROACH.md`, `docs/DECISIONS.md`, `docs/AI_USAGE.md`

Command-line builds use `-derivedDataPath .derivedData` so generated output does not land in the default DerivedData tree or in git.

### ActivityWeatherUITests is empty on purpose

`ActivityWeatherUITests` is standard Xcode project-structure convention (app + unit tests + UI tests). It is **not** speculative product scope. The target compiles and is included in the shared scheme’s Test action. It contains only an empty `XCTestCase` subclass and **no test methods**. It stays unused until **milestone 11** (resilience, accessibility and UI testing).

### TDD

Not applicable. Milestone 1 is scaffold and documentation. There is no testable behaviour (no scoring, mapping, repositories, use cases or ViewModels).

Test targets contain compiling scaffolds only. There are **no** `XCTAssertTrue(true)` (or equivalent) dummy assertions. A full `xcodebuild test` is expected to **succeed with zero behavioural tests** until later milestones add them.

### Verification (2026-09-04)

- Simulator: iPhone 17, iOS 26.2, id `095EEBAB-7398-4FA5-94B5-EE546882F7EF` (discovered via `-showdestinations`, not assumed).
- `xcodebuild` **BUILD SUCCEEDED** (exit 0) with `-derivedDataPath .derivedData`. Compiler invoked with `-swift-version 6` and `-target arm64-apple-ios17.0-simulator`.
- `xcodebuild test` **TEST SUCCEEDED** (exit 0). Executed **0 tests** twice (unit + UI), 0 failures. Expected: no behavioural tests in this milestone.
- Warning: `appintentsmetadataprocessor`: “Metadata extraction skipped. No AppIntents.framework dependency found.” Harmless; the app does not use App Intents.
- UI test runner logged Core Animation launch-measurement send failures (`FirstFramePresentationMetric` / `ExtendedLaunchMetrics`). Not treated as test failures.
- Visual placeholder on a booted SpringBoard was not screenshot-verified separately from the test-runner launch.

### Not in this milestone

Networking, Open-Meteo clients, domain models, scoring, search UI, forecast UI, persistence, third-party packages, secrets.

## 2026-09-04 — Milestone 2: product assumptions and scoring specification

Documentation-only. No Swift, networking, or scoring engine.

### What shipped

- `docs/ASSUMPTIONS.md` — suitability vs infrastructure, explicit geocoding selection, seven metric days, `timezone=auto` + Forecast-returned timezone, surfing as weather proxy, independent indoor rules, unavailable ≠ 0, test/network policy, MVP exclusions
- `docs/SCORING.md` — required daily fields, named weights/thresholds/caps/reason codes, WMO outdoor veto vs indoor cap vs penalty, skiing fresh snow vs heavy active snowfall, worked examples
- ADR-013 in `docs/DECISIONS.md`
- README / APPROACH / AI_USAGE links and review notes

### TDD

Not applicable. Documentation-only; no behavioural production code.

### Verification (2026-09-04)

- Simulator rediscovered: iPhone 17, iOS 26.2, id `095EEBAB-7398-4FA5-94B5-EE546882F7EF`
- `xcodebuild` **BUILD SUCCEEDED** (exit 0), `-derivedDataPath .derivedData`
- `xcodebuild test` **TEST SUCCEEDED** (exit 0). Executed **0 tests** twice (unit + UI). Expected: still no behavioural tests
- No Swift files modified; placeholder app unchanged
- Warning: AppIntents metadata skipped (same as milestone 1)

### Not in this milestone

Domain types, networking, scoring implementation, search/forecast UI.

## 2026-09-04 — Milestone 3: domain models and contracts

### Specification correction before implementation

`docs/SCORING.md` now states the approved suitability level bands
(`0...24` Poor, `25...49` Fair, `50...74` Good, `75...100` Great) and
corrects ranking language: seven days are ranked independently for each
activity. Activities are never sorted against one another;
`Activity.allCases` is display order only.

### TDD evidence

Focused Red → Green cycles were run against the discovered iPhone 17 simulator:

1. **Coordinate**
   - Red (exit 65): test target did not compile — `cannot find 'Coordinate' in scope`.
   - Green (exit 0): 2 tests, 0 failures.
2. **SuitabilityScore**
   - Red (exit 65): `cannot find 'SuitabilityScore' in scope`.
   - First green attempt compiled but the simulator rejected app launch as
     `Busy` (exit 65); no assertion or compiler failure.
   - Retry green (exit 0): 2 tests, 0 failures.
3. **CivilDate**
   - Red (exit 65): `cannot find 'CivilDate' in scope`.
   - Green (exit 0): 3 tests, 0 failures.
4. **WeeklyForecast**
   - Red (exit 65): `cannot find 'WeeklyForecast' in scope`.
   - Green (exit 0): 5 tests, 0 failures.
5. **Remaining Domain values**
   - Red (exit 65): `Activity`, `Location`, and
     `DailyActivitySuitability` were not in scope.
   - Green (exit 0): 3 tests, 0 failures.

### Domain boundaries

- Complete non-optional `DailyForecast`; partial API data is rejected before
  Domain and reported as `missingCriticalData`, never score 0.
- `CivilDate` plus Forecast-returned IANA timezone; no fixed UTC offset.
- `DailyActivitySuitability` derives its level from its bounded score.
- `LocationRepository`, `ForecastRepository`, and `ActivityScoring` are
  Domain-owned `Sendable` substitution boundaries.
- No scoring arithmetic, DTOs, networking, use cases, ViewModels, or UI.

### Verification (2026-09-04)

- Project and shared `ActivityWeather` scheme rediscovered with `xcodebuild`;
  iPhone 17 and iPhone 16e (iOS 26.2) were available.
- App build on iPhone 17: **BUILD SUCCEEDED** (exit 0).
- The first two full-suite runs on iPhone 17 and the first on iPhone 16e failed
  before unit-test execution because SpringBoard rejected the app preflight as
  `Busy` (exit 65). This was simulator infrastructure, not an assertion or
  compiler failure.
- After shutting down simulator runtimes, booting the discovered iPhone 16e,
  and waiting for boot completion, the unchanged full suite
  **TEST SUCCEEDED** (exit 0): 15 unit tests, 0 failures; UI target 0 tests as
  expected until milestone 11.
- Warning: AppIntents metadata extraction skipped because the app has no
  AppIntents dependency (unchanged from earlier milestones).

### Review corrections (before follow-up commit)

- Split Domain tests into `ActivityWeatherTests/Domain/Models/` focused files;
  removed the miscellaneous `ActivityWeatherTests.swift`.
- Dedicated `SuitabilityLevelTests` for inclusive bands 0/24, 25/49, 50/74,
  75/100.
- `DailyForecast` now throws `invalidForecastValues` for non-finite numbers,
  negative amounts/durations/wind/UV, precipitation hours outside `0...24`,
  and sunshine longer than daylight. No climate-range temperature/wind caps.
  Red: `XCTAssertThrowsError failed: did not throw an error` (13 failures).
- `DailyActivitySuitability` is one activity on one date; `date` is copied from
  the scored `DailyForecast`. Level remains derived from `SuitabilityScore`.
- `ActivityRanking` is still deferred. `ActivityScoring` is synchronous and has
  no implementation.

### Verification after review corrections (2026-09-04)

- Simulator rediscovered: iPhone 16e, iOS 26.2,
  id `818F8DBA-D98B-4B09-8634-57008C4C2AEB`.
- `xcodebuild` **BUILD SUCCEEDED** (exit 0).
- Full `xcodebuild test` **TEST SUCCEEDED** (exit 0): **20** unit tests,
  0 failures; UI target 0 tests.

## 2026-09-04 — Milestone 4: typed networking foundation

HTTP JSON client only. No Open-Meteo endpoints, DTOs, mappers, repositories, or
geocoding.

### What shipped

- `ActivityWeather/Data/Networking/`: `APIEndpoint`, `APIClient`, `APIError`,
  `URLSessionAPIClient`
- Tests under `ActivityWeatherTests/Data/Networking/` with a lock-protected
  test `URLProtocol` (host-keyed handlers, reset in teardown)
- ADR-015: ATS + HTTPS without certificate pinning

### TDD evidence

Simulator: iPhone 16e, iOS 26.2, id `818F8DBA-D98B-4B09-8634-57008C4C2AEB`.

1. **Valid endpoint URL construction**
   - Red (exit 65): `cannot find 'APIEndpoint' in scope` (`APIEndpointTests`).
   - Green (exit 0): 2 tests, 0 failures (URL construction + encoding together
     once the type compiled).
2. **Spaces and reserved query-character encoding**
   - Covered in the same `APIEndpointTests` green run. Query values are
     asserted via `URLComponents.queryItems` by name, not query-string order.
     The serialized URL still contains percent-encoding (`Los%20Angeles`,
     `a%26b%3Dc`).
3–10. **`URLSessionAPIClient` behaviour** (injected `URLProtocol`, no live
   network, no sleeps):
   - Compile red (exit 65): Swift 6 rejected nonisolated mutable handler
     storage on `StubURLProtocol`.
   - Compile red (exit 65): `Task { execute }` captured XCTest `self`
     (`sending` / data-race diagnostic).
   - Behavioural red (exit 65): `testMapsTransportFailure` —
     `XCTAssertEqual` of full `URLError` values failed because URLSession
     attached extra `userInfo` (`NSURLErrorDomain` `-1009`). Assertion was
     narrowed to the typed `URLError.Code`.
   - Green (exit 0): 8 tests, 0 failures (HTTP 200, HTTP 201, non-2xx,
     non-HTTP `URLResponse`, transport mapping, malformed JSON →
     `APIError.decoding`, `URLError.cancelled` passthrough, task
     cancellation passthrough).

### Boundaries kept

- Injected `URLSession`; new `JSONDecoder()` per request.
- Success only for HTTP `200...299`; status validated before decode.
- No retries, cache, reachability, logging framework, pinning, auth, or POST
  helpers.
- No Open-Meteo types.

### Verification (2026-09-04)

- Simulator: iPhone 16e, iOS 26.2, id `818F8DBA-D98B-4B09-8634-57008C4C2AEB`.
- App `xcodebuild` **BUILD SUCCEEDED** (exit 0), `-derivedDataPath .derivedData`.
- Full `xcodebuild test` **TEST SUCCEEDED** (exit 0): **30** unit tests,
  0 failures; UI target **0** tests (unused until milestone 11).
- Warning: AppIntents metadata extraction skipped (no AppIntents dependency).
- No live-network requests in tests.

## 2026-09-04 — Milestone 5: Open-Meteo geocoding

Search text → Domain `[Location]` only. No UI, debounce, ViewModels, or Forecast.

### What shipped

- `OpenMeteoGeocodingEndpoint`, internal `GeocodingResponseDTO`,
  `GeocodingLocationMapper`, `GeocodingError`, `OpenMeteoLocationRepository`
- Test-bundle JSON fixtures (not in the app target)
- Actor `StubAPIClient` for repository tests
- ADR-016

### TDD evidence

Simulator: iPhone 16e, iOS 26.2, id `818F8DBA-D98B-4B09-8634-57008C4C2AEB`.

1. **Endpoint / mapper / repository tests**
   - Red (exit 65): `cannot find type 'GeocodingResponseDTO' in scope`
     (`GeocodingFixture.swift`, `StubAPIClient.swift`) after `@testable import`.
   - Green (exit 0): **19** tests, 0 failures (2 endpoint, 9 mapper, 8
     repository).

### Behaviour recorded in tests

- Trimmed queries shorter than two characters return `[]` with **no** client
  invocation.
- Missing `results` and empty `results` → `[]`.
- Mixed rows keep valid hits; all-invalid non-empty `results` throws
  `GeocodingError.noValidLocations`.
- Blank required text / invalid coordinates skip records; blank optional
  metadata becomes `nil`.
- Wrong JSON types fail decoding (not silent skip).
- Ambiguous matches preserved in API order; transport, decoding, and
  cancellation pass through.

### Verification (2026-09-04)

- Simulator: iPhone 16e, iOS 26.2, id `818F8DBA-D98B-4B09-8634-57008C4C2AEB`
  (discovered via `-showdestinations`).
- App `xcodebuild` **BUILD SUCCEEDED** (exit 0), `-derivedDataPath .derivedData`.
- Full `xcodebuild test` **TEST SUCCEEDED** (exit 0): **49** unit tests,
  0 failures; UI target **0** tests.
- Warning: AppIntents metadata extraction skipped (no AppIntents dependency).
- No live-network requests.

## 2026-09-04 — Milestone 6: seven-day forecast retrieval

Mapping Open-Meteo `/v1/forecast` into Domain `WeeklyForecast`. No scoring or UI.

### What shipped

- `OpenMeteoForecastEndpoint`, `ForecastResponseDTO`, `ForecastMapper`,
  `ForecastMappingError`, `OpenMeteoForecastRepository`
- Test-bundle forecast fixtures
- Actor `ForecastStubAPIClient`
- ADR-017; ASSUMPTIONS updated for the seven-day window and IANA-only timezone

### Test evidence

Forecast behaviour was implemented with comprehensive automated tests, but the first captured integrated test run was green because tests and production wiring were introduced together. Therefore, this milestone is test-backed rather than a fully evidenced test-first TDD cycle. No failing result was reconstructed or fabricated retrospectively.

The first compiled `xcodebuild test` of the forecast classes **TEST SUCCEEDED** (exit 0): **21** tests, then additional error-boundary and coordinate round-trip assertions were added in review. The overall project still uses pragmatic TDD; Milestone 6 is reported accurately as test-backed.

### Fixtures

Thirteen test-bundle JSON files remain. Each is a different wire-format case (missing keys, null element, wrong JSON type, unexpected unit, length mismatch, invalid date, fewer/extra days, success). JSON is required where Codable behaviour is under test: omitted keys, `null` elements, and a string where an integer is required cannot be expressed by constructing a Swift DTO. The remaining envelopes stay as JSON so mapping is proven against the same decoder path rather than a hand-built DTO that could skip Codable.

### Behaviour recorded in tests

- `daily` query is exactly the 13 documented variables; `time` is omitted;
  `timezone=auto`.
- Coordinates use a POSIX decimal point.
- Missing `daily` / `daily_units` / timezone / `time` / required arrays / null
  elements / length mismatch → `missingCriticalData`.
- Wrong JSON types fail decoding; unexpected units → `unexpectedUnit`.
- Seven consecutive civil dates succeed; fewer/extra days →
  `invalidForecastWindow`; invalid calendar date → `invalidCivilDate`.
- Transport, decoding, and cancellation pass through.

### Verification (2026-09-04)

- Simulator: iPhone 16e, iOS 26.2, id `818F8DBA-D98B-4B09-8634-57008C4C2AEB`
  (discovered via `-showdestinations`).
- App `xcodebuild` **BUILD SUCCEEDED** (exit 0), `-derivedDataPath .derivedData`.
- Full `xcodebuild test` **TEST SUCCEEDED** (exit 0): **73** unit tests,
  0 failures; UI target **0** tests.
- Warning: AppIntents metadata extraction skipped (no AppIntents dependency).
- No live-network requests.

## 2026-09-04 — Milestone 7: explainable suitability scoring

Pure Domain engine from `docs/SCORING.md`. No UI, networking, DTO, or
repository changes.

### What shipped

- `SuitabilityScoringEngine` conforming to `ActivityScoring`
- `ScoringSpecification` named weights/thresholds
- `SuitabilityScore.init(clamping:)` (validating `init(_:)` still throws)
- Default `rankedSuitability(for:activity:)` on `ActivityScoring`
- Worked-example, combination, polar-night, reason-order, threshold-matrix,
  and ranking tests

### TDD evidence (actual)

1. Compiling stub engine (constant score `0`, empty reasons).
2. **Assertion-red** (not a missing-type compile failure):
   `testSkiWorkedExampleScores77` —
   `XCTAssertEqual failed: ("0") is not equal to ("77")`;
   reasons `[]` vs expected snowfall/snow-weather/freeze reasons.
   Simulator iPhone 16e (`818F8DBA-D98B-4B09-8634-57008C4C2AEB`),
   `xcodebuild test` exit **65**.
3. Engine implementation. Score **77** then matched; a follow-up assertion
   compared reason order to the worked-example table order
   (`snowfallAmount`, `snowWeather`, `freezeMax`) and failed because equal
   contributions sort by `rawValue` (`snowWeather` first). The test was
   aligned to the approved ordering; that failure was not reconstructed.

### Not in this milestone

UI, ViewModels, networking, DTOs, repositories, composition root.

### Verification (2026-09-04)

- Simulator: iPhone 16e, iOS 26.2, id `818F8DBA-D98B-4B09-8634-57008C4C2AEB`
- App `xcodebuild` **BUILD SUCCEEDED** (exit 0), `-derivedDataPath .derivedData`
- Full `xcodebuild test` **TEST SUCCEEDED** (exit 0): **98** unit tests,
  0 failures; UI target **0** tests
- Warning: AppIntents metadata extraction skipped (no AppIntents dependency)

## 2026-09-04 — Milestone 8: use cases and composition root

Thin Domain orchestration plus `AppDependencies.live`. No feature UI or
ViewModels. `ContentView` and `ActivityWeatherApp` are unchanged.

### What shipped

- `SearchLocationsUseCase`, `GetActivityForecastUseCase`
- `LocationActivityForecast` / `ActivityDayRanking`
- `AppDependencies.live(client:)`
- Spy tests and a composed search path through `OpenMeteoLocationRepository`

### TDD evidence (actual)

1. Compiling `SearchLocationsUseCase` stub that returned `[]` without calling
   the repository.
2. **Assertion-red:** `testTrimsQueryAndDelegatesToTheRepositoryOnce` —
   `XCTAssertEqual failed: ("[]") is not equal to ("["Paris"]")` (and locations
   `[]` vs the expected Paris result). Simulator iPhone 16e, exit **65**.
3. Search use case implemented (trim + one repository call).
4. Compiling `GetActivityForecastUseCase` stub that threw
   `missingCriticalData`.
5. **Red:** `testFetchesOnceAndScoresEveryDayForEveryActivity` failed: caught
   error `"missingCriticalData"` (exit **65**). Then the real fetch-once /
   score-28-times implementation.

### Deferred wiring

`AppDependencies` is created and tested. Root-view injection waits for
Milestone 9 so `ContentView` does not receive the whole container.

### Not in this milestone

Search/forecast UI, ViewModels, debounce, use-case protocols, Data or scoring
changes, environment injection, live-network tests.

### Verification (2026-09-04)

- Simulator: iPhone 16e, iOS 26.2, id `818F8DBA-D98B-4B09-8634-57008C4C2AEB`
- App `xcodebuild` **BUILD SUCCEEDED** (exit 0), `-derivedDataPath .derivedData`
- Full `xcodebuild test` **TEST SUCCEEDED** (exit 0): **106** unit tests,
  0 failures; UI target **0** tests
- Warning: AppIntents metadata extraction skipped (no AppIntents dependency)
- `ContentView.swift` and `ActivityWeatherApp.swift` unchanged

## 2026-09-04 — Milestone 9: debounced location search experience

Location-search presentation through explicit Domain `Location` selection.
No forecast screen or navigation destination.

### What shipped

- `@MainActor @Observable LocationSearchViewModel` with idle, loading,
  results, empty, and generic failure states
- 350 ms cancellable debounce, immediate submit/retry, request-generation
  stale-response protection, and explicit selection
- `LocationSearchView` with semantic Dynamic Type fonts, search-keyboard
  submit, progress feedback, helper/empty/failure states, accessible result
  labels, and a visible/VoiceOver-readable selected checkmark
- App-root composition that injects only `SearchLocationsUseCase` into the
  ViewModel and only the ViewModel into the View
- Removal of obsolete `ContentView.swift`

### TDD evidence (actual)

The first project-wired test run found a test compile issue (`await` inside an
XCTest autoclosure); this was corrected before behavioral evidence and is not
reported as the Red.

With a compiling minimum ViewModel shape,
`testSearchStartsOnlyAfterDebounceRelease` failed after the manual sleeper was
released: repository queries were `[]`, expected `["Paris"]`.
`xcodebuild test` exited **65**. The minimum debounced delegation then made the
focused test pass, followed by cancellation, stale-result/error, submit,
retry, state, ordering, and selection tests while green.

### Decisions and scope

The ViewModel's `< 2` check is UX policy; the repository guard remains
defensive API-contract enforcement. Errors are intentionally generic in
presentation. No API errors, DTOs, or dependency container enter the View.
Feature files remain flat at this size.

### Not in this milestone

Forecast screen, navigation destination, Data/scoring changes, DesignSystem,
environment injection, UI tests, live-network tests.

### Verification (2026-09-04)

- Simulator destinations rediscovered with `xcodebuild -showdestinations`;
  selected iPhone 16e, iOS 26.2,
  `818F8DBA-D98B-4B09-8634-57008C4C2AEB`
- App `xcodebuild` **BUILD SUCCEEDED** (exit 0), `-derivedDataPath .derivedData`
- Full `xcodebuild test` **TEST SUCCEEDED** (exit 0): **121** unit tests,
  0 failures; UI target **0** tests; no skipped tests
- Warning: AppIntents metadata extraction skipped (no AppIntents dependency)
- No live-network requests
