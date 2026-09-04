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
