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
