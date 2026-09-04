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
