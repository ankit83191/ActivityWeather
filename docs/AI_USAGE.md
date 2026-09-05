# AI usage

AI is a **reviewed assistant**, not an authority. Generated suggestions are compiled, tested, and checked against official Apple documentation (and this repository’s recorded decisions) before they are accepted. Rejected or materially changed suggestions are logged here.

## Policy

- Prefer Apple platform documentation over training-data defaults when they disagree.
- Do not add third-party packages, secrets, or generated build output because an assistant suggested them.
- Behavioural code follows Red-Green-Refactor; scaffold and documentation milestones are verified by build/test, not by dummy assertions.
- The human reviewer accepts or rejects each milestone commit.

## Milestone 1

**Accepted (after review and local verification):**

- Hand-authored `ActivityWeather.xcodeproj` (no SPM, no CocoaPods, no XcodeGen).
- Swift **6 language mode** (`SWIFT_VERSION = 6.0`) chosen from the inspected toolchain (Xcode 26.2 / Swift 6.2.3) rather than leaving the setting blank.
- Display name “Activity Weather” vs module/target `ActivityWeather`.
- Empty UI test target retained as Xcode convention, documented as unused until milestone 11.
- Project-local `-derivedDataPath .derivedData` for command-line verification.

**Rejected / not used:**

- Dummy unit tests such as `XCTAssertTrue(true)` to force a non-zero test count.
- Pre-creating Domain/Data/Features placeholder types or empty groups “for later.”
- Swift Package Manager or third-party project generators.
- Combine/`ObservableObject` samples in the placeholder app.
- Setting or changing Git `user.name` / `user.email`.

**Documentation check:** Swift 6 language mode and Observation (`@Observable`) align with current Apple guidance for new SwiftUI apps; TCA was not introduced (third-party, out of scope).

## Milestone 2

**Accepted (after review against [Open-Meteo Forecast docs](https://open-meteo.com/en/docs) and [Marine API docs](https://open-meteo.com/en/docs/marine-weather-api)):**

- Daily field names from the official Forecast `daily` list (`weather_code`, `temperature_2m_max` / `_min`, `apparent_temperature_max`, `precipitation_sum`, `rain_sum`, `snowfall_sum`, `precipitation_hours`, `wind_speed_10m_max`, `wind_gusts_10m_max`, `sunshine_duration`, `daylight_duration`, `uv_index_max`).
- `timezone=auto` as the only Forecast timezone mode; interpret dates using the timezone **returned** by Forecast.
- Unavailable/`missingCriticalData` distinct from score `0`.
- WMO `75`/`86` (heavy snow) and `82` (violent rain showers) as indoor travel-risk caps, not skiing outdoor vetoes; thunderstorms `95`/`96`/`99` and freezing rain `66`/`67` as outdoor vetoes.
- Rule-based scoring (ADR-013) instead of binary rules, opaque formulas, or ML.
- Surfing labelled as a weather proxy; Marine API fields not used in v1.

**Rejected / not used:**

- Rejected real-network automated tests because they would be nondeterministic and unnecessarily depend on an external service. Repository tests will use fixtures and an injected mocked transport.
- Using geocoding timezone interchangeably with Forecast `timezone=auto`.
- Mapping missing fields to score `0`.
- Treating heavy snowfall as automatically equivalent to ideal skiing weather.
- Indoor score as `100 - outdoorScore`.
- Live Open-Meteo calls or Swift scoring types in this documentation-only milestone.

## Milestone 3

**Accepted after tests and review:**

- Validated, `Sendable` Domain values for coordinates, civil dates, complete
  daily/weekly forecasts, activities, scores, levels, reasons, locations, and
  daily suitability.
- Focused Red-Green cycles for value invariants rather than one large batch.
- Foundation `TimeZone.knownTimeZoneIdentifiers` for IANA validation
  (later corrected: `TimeZone(identifier:)` so identifiers such as
  `Asia/Kolkata` are accepted; see the timezone identifier fix);
  `CivilDate` itself uses no Foundation date/time conversion.
- Domain-owned `Sendable` repository protocols and a small `ActivityScoring`
  substitution boundary for later use-case tests.

**Rejected / materially corrected:**

- Rejected ranking the four activities within one day. The product ranks seven
  days separately per activity.
- Rejected independently initialized score and level; level is derived from the
  bounded score.
- Rejected optional weather fields in `DailyForecast` and rejected mapping
  missing data to score 0.
- Rejected one fixed `utcOffsetSeconds` in Domain because the forecast can cross
  a daylight-saving transition.
- Rejected Foundation `Date` for a location-local forecast day; a validated
  Gregorian `CivilDate` avoids UTC-midnight ambiguity.
- No generated scoring implementation, DTOs, networking, UI, or speculative
  `ActivityRanking` type.

**Review corrections (still Milestone 3):**

- Accepted splitting Domain tests into mirrored `Domain/Models` files.
- Accepted `DailyForecast` numeric sanitization (`invalidForecastValues`)
  without climate-range temperature/wind limits.
- Accepted deriving `DailyActivitySuitability.date` from the scored
  `DailyForecast` so a result cannot point at a different day.

## Milestone 4

**Accepted after tests and review:**

- Immutable `Sendable` `APIEndpoint` via `URLComponents` / `URLQueryItem`.
- `APIClient.execute` constrained to `Response: Decodable & Sendable`.
- Injected `URLSession` and a fresh `JSONDecoder` per request.
- HTTP `200...299` only; explicit `nonHTTPResponse`; decode after status.
- `CancellationError` and `URLError.cancelled` are not `APIError.transport`.
- Thread-safe, teardown-reset `URLProtocol` stubs keyed by host.
- ATS + HTTPS without certificate pinning for this public unauthenticated API.

**Rejected / not used:**

- Open-Meteo endpoints, DTOs, mappers, repositories, geocoding (Milestone 5).
- `URLSession.shared` as an unreplaceable dependency.
- A process-wide shared `JSONDecoder`.
- Live-network tests and arbitrary `sleep`.
- Retries, exponential backoff, caching, reachability, logging frameworks,
  certificate pinning, authentication, generic POST/upload.
- Asserting query-item order in the serialized query string.
- Equating wrapped `URLError` values by full `userInfo`; tests check the
  typed `URLError.Code` after URLSession attaches session metadata.

## Milestone 5

**Accepted after tests and review:**

- Official Geocoding `/v1/search` with `count=10`, `language=en`, `format=json`.
- Repository short-circuit for trimmed queries shorter than two characters,
  matching the published API matching rules (documented so a later use case
  does not invent a second rule).
- Missing/empty `results` vs all-invalid non-empty `results`
  (`GeocodingError.noValidLocations`).
- Skip incomplete/blank/invalid-coordinate rows; fail decoding on wrong JSON
  types.
- Trim name/country/admin1/timezone; never invent placeholders.
- Test fixtures in the unit-test bundle only; actor-backed `APIClient` stub.

**Rejected / not used:**

- Forecast client, search UI, ViewModels, debounce, retries, caching,
  live-network tests.
- `countryCode` filter (would hide international duplicates).
- Returning `[]` when every returned row is unusable.
- Lossy coercion of JSON string coordinates into `Double`.
- Duplicating minimum-query-length policy outside the repository.

## Milestone 6

**Accepted after tests and review:**

- Official `/v1/forecast` with `forecast_days=7`, `timezone=auto`, metric
  units, and the 13 SCORING.md daily variables (`time` is not in `daily=`).
- Seven-day window = location-local today plus six following days; no device
  clock check.
- Optional DTO containers/elements: missing/null → `missingCriticalData`;
  wrong JSON type → `APIError.decoding`.
- Unexpected units → `ForecastMappingError.unexpectedUnit`; empty UV unit
  accepted.
- POSIX decimal coordinates; IANA timezone only (no `utc_offset_seconds`).
- Test-bundle fixtures; actor-backed forecast `APIClient` stub.

**Test process:** Forecast behaviour was implemented with comprehensive automated tests, but the first captured integrated test run was green because tests and production wiring were introduced together. Therefore, this milestone is test-backed rather than a fully evidenced test-first TDD cycle. No failing result was reconstructed or fabricated retrospectively.

**Rejected / not used:**

- Scoring, UI, ViewModels, retries, caching, live-network tests.
- Silently taking the first seven of extra days or prefix-zipping mismatched
  arrays.
- Treating unexpected units as `missingCriticalData`.
- Locale-sensitive comma decimals.
- Using geocoding timezone or `utc_offset_seconds` to interpret `daily.time`.

## Milestone 7

**Accepted after review and tests:**

- `ActivityScoring` stays a single-day substitution boundary; ranking is a
  protocol extension, not a required method or a second service.
- `SuitabilityScore(clamping:)` instead of `try!` after rounding.
- Polar night: `daylightDuration == 0` → sunshine ratio `0`.
- Reason policy: affected rules only, deduped, veto/cap first, `|contribution|`
  then `rawValue`; outdoor veto skips additives; indoor cap after additives;
  combined veto priority thunderstorm → freezing rain → extreme gust.
- Threshold matrix (below / at / above) plus ranking tests (seven days, one
  activity, score desc / date asc, no mutation).

**Rejected / materially corrected:**

- Rejected requiring every conformer to implement weekly ranking.
- Rejected `ActivityRanking` / a separate ranking service in this milestone.
- Rejected `try!` / `preconditionFailure` for clamped scores.
- Rejected dividing sunshine by daylight when daylight is zero.
- Rejected emitting reasons for zero-contribution rules, and rejected listing
  worked-example reasons in table-row order when `rawValue` tie-break differs.
- Rejected applying the outdoor veto to indoor scoring.
- Rejected emitting `dangerousTravelCap` when raw was already `≤ 40`.
- No UI, DTO, networking, or repository edits in this milestone.

## Milestone 8

**Accepted after review and tests:**

- Use cases orchestrate Domain workflows; JSON mapping stays in Data.
- Search trims and always delegates; repository keeps the `< 2` short-circuit.
- Forecast fetched once; 28 scoring calls (7×4); four `ActivityDayRanking`
  values in `Activity.allCases` order.
- `AppDependencies.live(client:)` as an explicit factory, not a shared
  singleton or environment object.
- Composition proven by driving `searchLocations` through the real geocoding
  repository with `StubAPIClient` (fixture, no live network).
- Deferred wiring: `ContentView` does not receive `AppDependencies`.

**Rejected / not used:**

- Injecting the whole container into `ContentView`.
- Use-case protocols, debounce, ViewModels, feature UI.
- A second search-length rule in the use case.
- `static let shared`, service locators, live-network tests.
- Data-layer or scoring-engine changes.

## Milestone 9

**Accepted after review and tests:**

- `@MainActor @Observable` search state with private mutation and
  implementation-only properties excluded from Observation.
- Injected cancellation-aware debounce so tests release waits manually
  without wall-clock sleeps.
- Generation plus task-cancellation checks for stale result/error protection.
- Presentation-level `< 2` policy alongside the repository's defensive guard;
  the responsibilities are distinct rather than duplicated accidentally.
- Explicit Domain `Location` selection with a visible and accessible selected
  row; no speculative callback.
- Root composition creates the ViewModel from the narrow search use case.

**Rejected / materially changed:**

- Removed the obsolete placeholder `ContentView` when search became the root.
- Rejected passing `AppDependencies` into any View.
- Rejected arbitrary sleeps, live networking, and exposed repository errors
  in ViewModel tests.
- Rejected navigation callbacks/destinations before the forecast experience.
- Rejected a redundant Presentation folder and DesignSystem abstraction.
- No forecast UI, Data, scoring, or UI-test changes.

## Milestone 10

**Accepted after review and tests:**

- Search-owned `NavigationStack` and optional Domain `Location`; generic
  destination builder captures only the forecast use case.
- `@State` ownership of an externally constructed `@Observable` forecast
  ViewModel with explicit idle/loading/loaded/failure transitions.
- Weak task capture, cancellation-to-idle, and generation-based stale
  completion protection.
- Existing Domain ranking selection only: no presentation scoring, sorting,
  threshold interpretation, or activity-switch refetch.
- `CivilDate` lookup for weather association and a safe unavailable state for
  inconsistent data.
- Gregorian, forecast-timezone local-midday date construction plus
  locale-aware formatting, tested around DST with a device/forecast timezone
  mismatch.
- Exhaustive user-facing reason copy, metric facts, textual ranks/scores/
  levels, adaptive two-by-two activity selection, visible limitations, and a
  complete explanation sheet.

**Rejected / materially changed:**

- Rejected `AnyView`, navigation in Domain, passing `AppDependencies` into a
  destination, and replacing the search root.
- Rejected array-index joins, force unwraps, formatted-string ordering, and
  displaying `SuitabilityReason.rawValue`.
- Rejected a four-item segmented control after accounting for full activity
  names and accessibility sizes; used a two-by-two selector with full
  accessibility labels.
- Rejected four scores in every chronological card; one selected ranking is
  the primary presentation.
- No Domain, Data, repository, use-case, or scoring changes. A live
  `Asia/Kolkata` identifier rejection was observed in the existing timezone
  invariant and left outside this milestone; it was later corrected.

## Timezone identifier correction

**Accepted after tests:**

- Validate Forecast timezones with `TimeZone(identifier:)` rather than
  `knownTimeZoneIdentifiers.contains`.
- Store the original Open-Meteo string; do not canonicalize.
- Reject identifiers Foundation cannot instantiate.

**Rejected:**

- Hardcoding or whitelisting `Asia/Kolkata`.
- Requiring `TimeZone(identifier:)?.identifier` to equal the input (that
  would rewrite aliases such as `UTC` → `GMT`).
- Scoring or forecast UI changes.

## Milestone 11

**Accepted after review and tests:**

- Domain repository-failure categories with exhaustive Data-boundary
  translation in both repositories and exhaustive category mapping in both
  ViewModels.
- Cancellation remains control flow rather than a displayed failure.
- Existing search results remain visible only during the superseding debounce;
  loading starts when the request starts.
- Combined VoiceOver forecast-card summaries, explicit selected values and
  traits, textual score levels, larger touch targets, long-text wrapping,
  stable identifiers, and accessibility-size adaptive layouts.
- One deterministic launch/minimum-query UI smoke test without networking or
  fixture-only production composition.
- Visible provider attribution and an explicit statement that app-generated
  heuristic scores are not provider-endorsed.

**Rejected / materially changed:**

- Rejected the initial Feature classifier that inspected `APIError`,
  mapping errors, and Domain validation errors directly; infrastructure
  translation belongs in Data and Presentation sees only Domain categories.
- Rejected switching to loading as soon as a valid query is typed; existing
  results remain available during the debounce interval.
- Rejected a two-column activity selector at accessibility Dynamic Type sizes
  after manual AX5 inspection showed severe wrapping; accessibility sizes use
  one column.
- Rejected live networking, arbitrary sleeps, and production fixture hooks in
  the UI test.
- Rejected colour-only score and selection communication, a DesignSystem
  abstraction, snapshots, analytics, persistence, caching, and unrelated
  cleanup.

## Milestone 12

**Accepted after audit:**

- Documentation/assets-only finalization after confirming the milestone 11
  commit and clean working tree.
- Portable simulator discovery, explicit architecture/request flow, precise
  limitations, provider licensing, and a focused technical solution walkthrough.
- Three screenshots captured from a live final-build journey using a temporary
  UI-driving test method; the method was fully removed before staging.
- Staged-index export for clean-snapshot build/test verification.
- Secret-pattern checks across current tracked files and reachable Git history
  that report only categories/counts/paths, never candidate values.
- Clear separation between current executable verification and review of
  historical commit scope.

**Rejected / constrained:**

- Rejected hardcoded Simulator UUIDs/models in public instructions.
- Rejected claiming that every historical commit was rebuilt.
- Rejected claiming strict test-first TDD where only comprehensive
  after-the-fact test evidence exists, especially milestone 6.
- Rejected adding a production fixture hook for screenshots or manual failure
  states.
- Rejected hiding attribution, surfing limitations, physical-device VoiceOver
  gaps, or offline-cache limitations in secondary documentation.
