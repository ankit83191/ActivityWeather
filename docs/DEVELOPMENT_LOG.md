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

## 2026-09-04 — Milestone 10: ranked activity forecast experience

Selected-location forecast loading, one-at-a-time activity ranking,
explainable weather cards, scoring limitations, and navigation that preserves
the search feature.

### What shipped

- `@MainActor @Observable ActivityForecastViewModel` with privately mutable
  idle/loading/loaded/failure state, single-load/retry rules, cancellation,
  stale-completion protection, and activity selection
- Presentation-only `CivilDate` weather association, locale-aware forecast-
  timezone date formatting, exhaustive reason copy, and relevant metric facts
- Adaptive two-by-two activity selector, best-day summary, seven positional
  ranking cards, safe inconsistent-data state, visible surfing disclaimer,
  and scoring explanation sheet
- Search-owned `NavigationStack` with a generic destination builder; the
  existing search ViewModel remains alive on back navigation
- App-root destination composition that captures only
  `GetActivityForecastUseCase`

### TDD evidence (actual)

With a compiling minimum ViewModel shell whose `load()` was empty,
`testInitialLoadStartsExactlyOneRequest` failed because the repository
received `[]` instead of the selected location and status remained `idle`
instead of `loading`. The focused `xcodebuild test` exited **65**.

The loading state machine then made the focused test green. Subsequent tests
covered repeated loading/success calls, four seven-day rankings, default and
persistent activity selection, activity switching without refetch/rescoring,
Domain order including equal scores, failure/retry, cancellation/reload,
stale success/failure, safe date association, and forecast-timezone formatting
around a DST boundary.

### Manual end-to-end validation

On iPhone 16e (the smallest available iPhone Simulator), iOS 26.2:

- Launched the final installed build, searched the live API for Paris, chose
  the explicit Île-de-France result, and loaded its forecast.
- Switched through skiing, surfing, outdoor, and indoor. For each activity,
  scrolled through and confirmed positional rows 1 through 7.
- Confirmed best-day summaries, numeric scores, Poor/Fair/Good/Great text,
  metric facts, human-readable reasons, and the visible surfing-proxy
  limitation.
- Opened and dismissed the explanation sheet; confirmed score bands,
  rule-based/not-scientifically-validated wording, venue limitation, and
  surfing limitation.
- Navigated back and confirmed `Paris`, its results, and the selected result
  remained. Selected Paris, Texas and observed a fresh forecast with a
  different local first date.
- Checked light and dark appearances and Accessibility Large Dynamic Type.
  The two-by-two selector remained usable and text reflowed without a blank
  screen or crash.
- The final app process had no serious runtime console errors. Expected
  Simulator-only haptic-library messages were ignored.

The live check also exposed an existing timezone-identifier limitation
(`Asia/Kolkata` rejected by `knownTimeZoneIdentifiers`). The successful
required Milestone 10 flow used `Europe/Paris`. That identifier defect was
corrected afterwards; it is no longer a known limitation.

### Verification (2026-09-04)

- App `xcodebuild` **BUILD SUCCEEDED** (exit 0), `-derivedDataPath .derivedData`
- Full `xcodebuild test` **TEST SUCCEEDED** (exit 0): **135** unit tests,
  0 failures; UI target **0** tests
- Focused Milestone 10 suite: **14** tests, 0 failures
- Warning: AppIntents metadata extraction skipped (no AppIntents dependency)
- No Domain, Data, repository, use-case, or scoring changes in Milestone 10

## 2026-09-04 — Fix: accept valid IANA timezone identifiers

Open-Meteo returns `Asia/Kolkata` for Indian locations. Domain previously
required membership in `TimeZone.knownTimeZoneIdentifiers`, which lists
`Asia/Calcutta` but not `Asia/Kolkata`. Foundation still constructs
`TimeZone(identifier: "Asia/Kolkata")`. Forecast loads for Pune, Mumbai and
New Delhi failed as `invalidForecastTimezone`.

### What changed

- `WeeklyForecast` now accepts any identifier Foundation can instantiate
  through `TimeZone(identifier:)`.
- The original Forecast string is stored; Domain does not canonicalize.
- Invalid identifiers such as `Invalid/Timezone` still fail.
- Scoring rules and forecast UI were not changed.

### TDD evidence (actual)

With the existing `knownTimeZoneIdentifiers` guard,
`testAcceptsAsiaKolkataIdentifierRecognizedByFoundation` failed:
`caught error: "invalidForecastTimezone"`. Focused `xcodebuild test` exit **65**.

The `TimeZone(identifier:)` guard then made that test green. Additional
regressions cover `Europe/Paris`, empty and whitespace-only identifiers,
`Invalid/Timezone`, `UTC` canonicalizing to `GMT` while preserving the supplied
string, Forecast mapping of `Asia/Kolkata`, and presentation formatting in
`Asia/Kolkata`.

### Manual verification

On iPhone 16e, iOS 26.2 (`818F8DBA-D98B-4B09-8634-57008C4C2AEB`): searched
live Open-Meteo for **Pune**, selected Pune, Maharashtra, India, and loaded
the forecast successfully (title **Pune**, seven ranked days, local dates such
as Friday 4 September). Switched successfully through skiing, surfing, outdoor
and indoor rankings. No failure screen.

### Verification (2026-09-04)

- Simulator: iPhone 16e, iOS 26.2, id `818F8DBA-D98B-4B09-8634-57008C4C2AEB`
- App `xcodebuild` **BUILD SUCCEEDED** (exit 0), `-derivedDataPath .derivedData`
- Targeted timezone suite **TEST SUCCEEDED** (exit 0): **12** tests
- Full `xcodebuild test` **TEST SUCCEEDED** (exit 0): **142** unit tests,
  0 failures; UI target **0** tests
- Warning: AppIntents metadata extraction skipped (no AppIntents dependency)
- Scoring rules and forecast UI were not modified

## 2026-09-04 — Milestone 11: resilience and accessibility

Hardened repository failures, superseding-search transitions, adaptive
layouts, accessibility semantics, attribution, and one deterministic UI smoke
test without expanding product scope.

### What changed

- Added Domain `RepositoryFailure` categories and translated infrastructure,
  response, mapping, and Domain-integrity errors inside both Data repositories.
  Cancellation still passes through as cancellation.
- Presentation now maps only Domain failure categories to recovery copy; it
  does not inspect API errors, HTTP codes, DTO errors, or raw descriptions.
- Valid edited queries keep existing results visible during debounce, clear
  selection, cancel obsolete work, and enter loading only when the new request
  starts.
- Added combined forecast-card accessibility summaries, selected traits and
  visible selected text, button hints, stable identifiers, 48-point targets,
  long-text wrapping, higher-contrast limitations, and adaptive ranking,
  weather-fact, title, and activity-selector layouts.
- Added visible Open-Meteo forecast attribution, visible Open-Meteo/GeoNames
  search attribution, and clarified that activity scores are application
  heuristics not endorsed by Open-Meteo.
- Added a deterministic UI test for launch and the one-character minimum-query
  journey. A complete stubbed UI journey was not added because it would require
  test-specific application composition disproportionate to this assignment;
  repository, use-case, and ViewModel journeys already have deterministic unit
  coverage.

### TDD evidence (actual)

- Repository translation Red: the new connectivity regression expected
  `backgroundSessionWasDisconnected` to map to `offline`; the initial mapper
  returned `unknown`. Focused `xcodebuild test` exited **65**. Adding that
  connectivity code made the test and repository mapping suites green.
- Search-transition Red: after Paris results were loaded, editing to London
  expected the Paris results to remain during debounce; status was `loading`.
  Focused `xcodebuild test` exited **65**. Deferring the loading transition
  until after the injected sleeper was released made it green.
- ViewModel and repository tests exhaustively cover all four Domain failure
  categories. Accessibility/layout changes were verified with the UI smoke
  and manual inspection, not described as strict test-first TDD.

### Manual validation matrix

- **iPhone 16e, light, default type:** live Paris search/results and forecast;
  visually confirmed old results remain during a replacement debounce. A
  forecast request safely reproduced the offline screen with connection copy;
  retry then loaded the ranking.
- **iPhone 16e, maximum accessibility type:** search field, helper content,
  and multi-line region/country results reflowed. Manual inspection exposed
  severe two-column activity-button wrapping; the selector was changed to one
  column at accessibility sizes and rebuilt.
- **iPad Pro 13-inch, dark, maximum accessibility type:** launch/search layout
  rendered without clipping, blank content, or contrast inversion.
- **VoiceOver:** the Simulator VoiceOver service was enabled and the initial
  navigation focus was observed. Combined search/card labels, values, traits,
  hints, and reading order are covered by accessibility hierarchy and unit/UI
  checks. Spoken traversal could not be completed reliably through automated
  Simulator input, so physical-device spoken output remains unverified.
- **Timezone/activity regression:** the immediately preceding corrective
  verification covered Pune/`Asia/Kolkata`, all four activities, and seven
  rows; Milestone 10 covered Paris/`Europe/Paris`, all four activities,
  explanation, and preserved back-navigation state. Milestone 11 did not alter
  scoring, timezone validation, request contracts, or navigation.
- Long region/country text was inspected at AX5. A deliberately extreme long
  city name was not obtained from the live API, so that specific live case
  remains covered by wrapping constraints rather than a fixture-driven manual
  screen.
- Server-status and invalid-data screens were not manually induced because
  doing so would require a production test hook. Deterministic repository and
  ViewModel tests cover them.

### Verification (2026-09-04)

- Final app build:
  `xcodebuild -project ActivityWeather.xcodeproj -scheme ActivityWeather
  -destination 'platform=iOS Simulator,id=818F8DBA-D98B-4B09-8634-57008C4C2AEB'
  -derivedDataPath .derivedData build` — **BUILD SUCCEEDED**, exit 0.
- Complete suite with the same project, scheme, destination, and DerivedData
  path using `test` — **TEST SUCCEEDED**, exit 0: **152 unit tests** and
  **1 UI test**, 0 failures, 0 skipped.
- Focused repository/ViewModel/presentation suite: **55 tests**, 0 failures.
- Deterministic UI smoke: **1 test**, 0 failures.
- IDE diagnostics: no linter errors.
- Warning: AppIntents metadata extraction was skipped because the target has
  no AppIntents dependency. No compiler warning, test warning, or skipped test
  was reported.
- No scoring weights/rules, API request contracts, timezone validation,
  navigation architecture, persistence, or caching changed.

## 2026-09-04 — Milestone 12: public submission audit

Finalized the public guide, submission evidence, architecture narrative, and
reviewer audit without changing production or test behavior.

### Documentation and assets

- Reworked `README.md` with purpose, features, portable run/test commands,
  screenshots, request flow, architecture, scoring, error/accessibility
  behavior, limitations, TDD accuracy, AI disclosure, attribution/licensing,
  future work, and a documentation index.
- Added `docs/INTERVIEW_WALKTHROUGH.md` covering problem framing,
  assumptions, dependency inversion, state/request flow, scoring, concurrency,
  testing, accessibility, trade-offs, scalability, AI verification, and future
  improvements.
- Added three non-sensitive iPhone 16e Simulator images:
  - `docs/assets/location-search-results.png` — 1170×2532, 233,007 bytes
  - `docs/assets/ranked-activity-forecast.png` — 1170×2532, 236,825 bytes
  - `docs/assets/scoring-explanation.png` — 1170×2532, 203,595 bytes
- Updated assumptions, approach, decisions, and AI disclosure. No production,
  test, project, scheme, fixture, or dependency file is part of this milestone.

### Submission audit

- Starting point: `9edf28d feat: improve resilience and accessibility`; clean
  working tree.
- Shared `ActivityWeather` scheme is tracked and includes app, unit, and UI
  targets. Deployment target is iOS 17.0. `DEVELOPMENT_TEAM` is empty in every
  configuration; Simulator use needs no personal signing.
- Bundle identifiers are explicit and test targets depend on the app. Fixture
  JSON files belong only to the unit-test resource phase; the app resource
  phase contains only `Assets.xcassets`.
- No Swift Package, CocoaPods, Carthage, or third-party dependency manifest was
  found.
- Current production source contains no `try!`, `as!`, `fatalError`,
  `preconditionFailure`, TODO/FIXME marker, or force unwrap. Test-only force
  unwraps are limited to controlled static URL/HTTP response construction and
  an XCTest setup implicitly-unwrapped property; each was reviewed rather than
  mechanically rewritten.
- No `SuitabilityReason.rawValue` is displayed. Presentation uses
  `SuitabilityLevel.rawValue` only for its intentionally user-facing
  `Poor/Fair/Good/Great` text.
- Domain contains no Data/DTO/network references. Features contain no DTO,
  endpoint, API client/error, URLSession, mapper-error, or scoring-engine
  reference. The dependency direction remains Presentation → Domain ← Data.
- Visible attribution was confirmed in source and the final forecast
  screenshot: forecast data links to Open-Meteo; search results link to
  Open-Meteo and GeoNames; score copy identifies application transformations
  and disclaims Open-Meteo endorsement.
- Tracked-file audit found 111 files at the starting commit and zero
  `xcuserdata`, DerivedData/build output, `.DS_Store`, `.env`, certificate,
  provisioning-profile, or Xcode user-state files.
- Secret-pattern audit across all reachable commits found zero paths matching
  private-key headers, GitHub-token forms, common cloud access-key forms, or
  quoted secret assignments. The `origin` URL has no embedded credentials.
  Candidate values were never printed.
- The 13-commit history was reviewed as a readable milestone sequence with no
  merges. Historical commits were not individually rebuilt; executable
  verification applies to the final staged snapshot only.

### Manual journey and screenshot capture

A temporary UI-driving test method was used to make live Simulator interaction
and screenshots repeatable without adding a production fixture hook. It was
removed completely before staging.

On iPhone 16e, iOS 26.2:

1. Launched the app and searched the live API for Paris.
2. Confirmed multiple ambiguous results and explicitly selected Paris,
   Île-de-France, France.
3. Loaded the seven-day `Europe/Paris` forecast.
4. Switched through skiing, surfing, outdoor, and indoor; for every activity,
   confirmed the first card and navigated to positional rank 7.
5. Opened the scoring explanation and captured its bands and limitations.
6. Dismissed it, navigated back, and confirmed the `Paris` query and results
   remained.

The repeatable journey passed in 101.386 seconds. The temporary method called
the live API, so it is manual submission evidence, not part of the committed
automated suite.

The safely reproduced offline/retry evidence occurred during final milestone
11 validation on the same `9edf28d` snapshot: a Paris forecast request reached
the connection failure screen, displayed offline recovery copy, and succeeded
after **Try Again**. Milestone 12 did not manufacture another outage or add a
network test hook. HTTP-status and invalid-data screens were not manually
forced; deterministic repository and ViewModel tests cover them.

### TDD statement

Milestone 12 is documentation/audit work, so TDD does not apply. Strict Red →
Green → Refactor is claimed only for milestones with recorded focused
failures. Milestone 6 was comprehensive fixture-backed testing but is not
claimed as strict test-first. SwiftUI layout evidence comes from the stable UI
smoke and manual visual/accessibility inspection.

### Final staged-snapshot verification

The Git index was exported with:

```sh
EXPORT_DIR=$(mktemp -d /tmp/activity-weather-staged.XXXXXX)
DERIVED_DIR=$(mktemp -d /tmp/activity-weather-derived.XXXXXX)
git checkout-index --all --prefix="$EXPORT_DIR/"
SIMULATOR_ID=$(
  xcrun simctl list devices available |
  awk -F '[()]' '/iPhone|iPad/ && /Booted|Shutdown/ { print $2; exit }'
)
```

The export contained no `.git` directory. The discovered destination was an
iPhone 17 Pro Simulator; no public command assumes that model or UUID.

```sh
xcodebuild -project "$EXPORT_DIR/ActivityWeather.xcodeproj" \
  -scheme ActivityWeather \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DIR" clean build

xcodebuild -project "$EXPORT_DIR/ActivityWeather.xcodeproj" \
  -scheme ActivityWeather \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DIR" test
```

- Clean build: **BUILD SUCCEEDED**, exit 0.
- Complete suite: **TEST SUCCEEDED**, exit 0.
- **152 unit tests + 1 UI test**, 0 failures, 0 skipped.
- No flaky retry was needed.
- Warning: AppIntents metadata extraction was skipped because the target does
  not link AppIntents. No compiler warning was reported.
