# Approach

## Problem

People planning outdoor and indoor activities need weather that is already interpreted for a purpose. A generic seven-day forecast does not say whether a day is better for skiing, surfing, walking a city, or staying indoors. Activity Weather turns Open-Meteo geocoding and forecast data into ranked, explainable suitability for four activities.

## Intended user flow

1. Launch the app.
2. Search for a location (Open-Meteo Geocoding).
3. Select a place.
4. View a seven-day forecast with per-day rankings for skiing, surfing, outdoor sightseeing and indoor sightseeing.
5. Inspect why a rank was given (explainable scoring, not a black-box score).

Product rules: [ASSUMPTIONS.md](ASSUMPTIONS.md). Scoring contract:
[SCORING.md](SCORING.md). The twelve milestones below are now implemented;
their evidence and final verification are recorded in
[DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md).

## Milestones

| # | Milestone | Commit message |
|---|---|---|
| 1 | Project scaffold and engineering plan | `chore: scaffold project and document initial approach` |
| 2 | Product assumptions and scoring specification | `docs: define product assumptions and scoring model` |
| 3 | Domain models and contracts | `feat(domain): define forecast and activity contracts` |
| 4 | Typed networking foundation | `feat(data): add typed networking foundation` |
| 5 | Open-Meteo geocoding | `feat(search): implement Open-Meteo geocoding` |
| 6 | Open-Meteo seven-day forecast | `feat(forecast): implement seven-day forecast retrieval` |
| 7 | Explainable scoring engine | `feat(scoring): add explainable suitability scoring` |
| 8 | Use cases and app composition | `feat(domain): orchestrate search and activity forecasts` |
| 9 | Location search experience | `feat(search): add debounced location search experience` |
| 10 | Ranked forecast experience | `feat(forecast): present ranked activity forecasts` |
| 11 | Resilience, accessibility and UI testing | `feat: improve resilience and accessibility` |
| 12 | Final documentation and submission audit | `docs: finalize submission and verification guide` |

Work one milestone at a time. Do not start the next until the current change is reviewed, built, tested and committed.

## Architecture direction

- **Layers:** Domain, Data, Features. Views and ViewModels depend on Domain protocols; Data implements them. API DTOs stay in Data. Networking stays out of Views and ViewModels.
- **Presentation:** MVVM-style Feature modules with `@Observable` ViewModels and initializer-injected dependencies.
- **Concurrency:** Swift `async/await`. No Combine as the presentation observation mechanism.
- **Dependencies:** Apple frameworks only.
- **Persistence:** None for the MVP (see decisions).

### Target source layout

Folders are created when a milestone adds types. Empty placeholder types are not used to “reserve” structure.

- `ActivityWeather/App`
- `ActivityWeather/Domain/Models`
- `ActivityWeather/Domain/Repositories`
- `ActivityWeather/Domain/UseCases`
- `ActivityWeather/Domain/Scoring`
- `ActivityWeather/Data/DTOs`
- `ActivityWeather/Data/Mappers`
- `ActivityWeather/Data/Networking`
- `ActivityWeather/Data/Repositories`
- `ActivityWeather/Features/LocationSearch`
- `ActivityWeather/Features/ActivityForecast`
- Mirrored groups under `ActivityWeatherTests`

`ActivityWeatherUITests` contains the deterministic launch/minimum-query smoke
introduced in milestone 11.

## Test strategy

Pragmatic TDD:

- **Red-Green-Refactor** for scoring rules, DTO mapping, repositories, use cases and ViewModels.
- Tests and implementation ship together so every completed commit stays green.
- SwiftUI layout is developed iteratively with previews, accessibility inspection and a small UI smoke test (milestone 11), not by pretending every visual detail was test-first.
- Documentation-only and scaffold work are verified (build, scheme, deployment targets) but are not TDD candidates.

For behavioural milestones, record the failing test and the reason it failed in `docs/DEVELOPMENT_LOG.md`, implement the minimum code to pass, refactor while green, then run the complete suite. Never commit a deliberately failing branch.

## Definition of done (MVP)

- Compilable iOS 17+ app (iPhone and iPad) with no third-party packages.
- Location search via Open-Meteo Geocoding.
- Seven-day forecast via Open-Meteo Forecast API.
- Ranked, explainable scores for the four activities.
- Unit tests for scoring, mapping, repositories, use cases and ViewModels.
- Accessibility and UI smoke coverage in milestone 11.
- Public submission guide, screenshots, interview walkthrough, decisions,
  development log, and AI usage kept current.

## MVP exclusions

- Accounts, authentication and user profiles
- On-device persistence, favourites and recent-search storage
- Push notifications, widgets, Live Activities, complications
- Maps, offline caching of forecasts, background refresh, device location permission
- Multiple-city comparison, search history, a product backend
- Resort/beach discovery; Open-Meteo Marine API in v1
- Additional activities beyond the four listed
- Third-party SDKs, analytics and crash reporters
- App Store submission assets beyond what the engineering repo requires
- Custom app icon artwork (catalog exists; no marketing asset in milestone 1)
