# Interview walkthrough

## 1. Problem framing

A generic weather forecast exposes measurements but does not answer a planning
question. Activity Weather interprets one consistent seven-day forecast for
four activities and makes every ranking explainable.

The output is weather suitability, not venue discovery, safety advice, or a
scientifically validated recommendation.

## 2. Assumptions

- The user explicitly selects an ambiguous geocoding result.
- The Forecast API returns exactly seven local civil dates with required
  metric fields.
- The forecast response timezone is authoritative.
- Surfing is a weather-only proxy because v1 has no marine data.
- The app has no backend, API key, persistence, cache, or device location.

See [ASSUMPTIONS.md](ASSUMPTIONS.md) for the complete product boundaries.

## 3. Architecture

The repository uses lightweight Clean Architecture:

- **Domain** owns validated models, repository contracts, use cases, failure
  categories, and pure scoring.
- **Data** owns URLSession, endpoints, DTOs, mapping, repository
  implementations, and infrastructure-error translation.
- **Features** own `@Observable` ViewModels, SwiftUI state rendering,
  formatting, user-facing copy, and accessibility.
- **App** is the composition root and injects narrow use cases.

The dependency direction is Presentation → Domain ← Data. Domain never imports
Data, and Views never receive the dependency container.

## 4. Dependency inversion

`LocationRepository` and `ForecastRepository` are Domain protocols. Data
implements them with Open-Meteo repositories. Use cases depend on the
protocols, while tests inject controllable actors/spies.

`AppDependencies.live()` creates one API client, repositories, the scoring
engine, and use cases. Views receive only ViewModels; ViewModels receive only
the use cases they need.

## 5. Request and state flow

### Search

1. Input is normalized in Presentation and debounced for 350 ms.
2. A new query cancels obsolete work and increments a request generation.
3. Existing results remain visible during a valid replacement debounce.
4. The use case delegates to the location repository.
5. Data maps DTOs into Domain locations or a Domain failure category.
6. Cancellation and stale completions are ignored.

### Forecast

1. Explicit selection navigates with a Domain `Location`.
2. First appearance starts one forecast request.
3. The use case asks the scoring engine for all seven days and four activities.
4. Domain rankings are authoritative.
5. Presentation joins ranked scores and weather by `CivilDate`.
6. Activity switching selects an existing ranking without networking,
   rescoring, or sorting.
7. Back navigation reveals the still-alive search state.

## 6. Scoring design

The engine is a pure deterministic rules system. Each activity starts from a
base, applies named positive/negative contributions and any safety veto/cap,
rounds, clamps to `0...100`, and records reasons. Rankings sort by score
descending and civil date ascending.

Reasons are Domain codes; Presentation exhaustively maps them to readable
copy. Thresholds and worked examples are in [SCORING.md](SCORING.md).

## 7. Concurrency and cancellation

Both ViewModels are `@MainActor @Observable`. They keep active tasks private,
cancel superseded work, and use monotonically increasing generations so an
obsolete success or failure cannot overwrite current state.

Weak task capture avoids a ViewModel → Task → ViewModel ownership cycle.
Cancellation remains control flow rather than an error screen. Search debounce
uses an injected sleeper, making timing tests deterministic and fast.

## 8. TDD and testing

Strict Red → Green → Refactor was used where genuine focused failure evidence
was captured: Domain invariants, networking/mapping, scoring, use cases,
ViewModel transitions, timezone validation, repository-failure translation,
and the search debounce regression.

Milestone 6 received comprehensive fixture-backed tests but is not described
as strictly test-first. SwiftUI layout was verified through a deterministic UI
smoke test and manual Simulator inspection rather than claiming visual TDD.

The suite uses no live API calls. Test clients, URLProtocol stubs, fixtures,
manual sleepers, and controllable repositories cover deterministic behavior.

## 9. Accessibility

The interface communicates rank, numeric score, named level, selection, and
errors with text rather than colour alone. It uses 48-point controls, adaptive
one/two-column activity selection, `ViewThatFits`, Dynamic Type, system
colours, button hints, selected traits, and combined forecast-card summaries.

The stable UI smoke covers launch and minimum-query behavior. Simulator checks
covered small/large layouts, light/dark appearance, and maximum Dynamic Type.
Spoken VoiceOver output still deserves physical-device verification.

## 10. Trade-offs

- A transparent heuristic is explainable and testable but not scientifically
  validated.
- One shared forecast supports consistent rankings but requires every scoring
  field to be valid.
- No cache keeps scope and freshness semantics simple but means offline users
  cannot see prior forecasts.
- One small UI smoke avoids production test hooks; deeper workflows remain
  covered below UI through deterministic tests.
- Flat feature folders are appropriate at this size; extra presentation/design
  abstractions would add ceremony without reuse.

## 11. Scalability

If the product grows:

- Split features into presentation subfolders only when file count warrants it.
- Add cached repositories behind existing Domain protocols.
- Version scoring specifications and add new engines behind `ActivityScoring`.
- Add marine and venue data as separate sources/use cases rather than leaking
  them into weather DTOs.
- Add dependency-controlled UI composition for stable end-to-end scenarios.
- Localize presentation mappings independently of Domain reason codes.

## 12. AI verification

AI output was treated as a proposal, not authority. Changes were compiled,
tested, reviewed against layer boundaries, and manually inspected. Incorrect
suggestions were rejected or corrected, including Feature-level
infrastructure error classification and inaccurate timezone wording.

The complete disclosure is in [AI_USAGE.md](AI_USAGE.md).

## 13. Future improvements

Priorities are physical-device VoiceOver verification, explicit cache/freshness
semantics, marine data for surfing, optional venue validation, localization,
and expanded dependency-controlled UI journeys. None should weaken the
existing Domain/Data/Features boundaries.
