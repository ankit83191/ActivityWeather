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
- Foundation `TimeZone.knownTimeZoneIdentifiers` for IANA validation;
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
