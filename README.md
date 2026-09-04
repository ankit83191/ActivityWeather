# Activity Weather

Native SwiftUI iOS app that ranks skiing, surfing, outdoor sightseeing and indoor sightseeing from Open-Meteo weather data.

The on-device display name is **Activity Weather**. The Xcode project, targets, shared scheme and Swift module are **ActivityWeather**.

## Requirements

- Xcode 26.2 (or compatible) with the iOS 17+ SDK
- Swift 6 language mode (`SWIFT_VERSION = 6.0`); local toolchain at scaffold time was Apple Swift 6.2.3
- iPhone and iPad

## Open in Xcode

Open `ActivityWeather.xcodeproj` and select the shared `ActivityWeather` scheme.

## Build and test (command line)

Use a project-local DerivedData directory so build output stays out of the source tree (already gitignored as `.derivedData/`):

```sh
xcodebuild -project ActivityWeather.xcodeproj \
  -scheme ActivityWeather \
  -destination 'platform=iOS Simulator,id=<SIMULATOR_UDID>' \
  -derivedDataPath .derivedData \
  build

xcodebuild -project ActivityWeather.xcodeproj \
  -scheme ActivityWeather \
  -destination 'platform=iOS Simulator,id=<SIMULATOR_UDID>' \
  -derivedDataPath .derivedData \
  test
```

Discover an available simulator with `xcodebuild -project ActivityWeather.xcodeproj -scheme ActivityWeather -showdestinations`.

## Architecture

Lightweight Clean Architecture (Domain, Data, Features) with MVVM-style presentation. See [docs/APPROACH.md](docs/APPROACH.md) and [docs/DECISIONS.md](docs/DECISIONS.md).

## Documentation

- [Approach](docs/APPROACH.md)
- [Assumptions](docs/ASSUMPTIONS.md)
- [Scoring](docs/SCORING.md)
- [Decisions](docs/DECISIONS.md)
- [Development log](docs/DEVELOPMENT_LOG.md)
- [AI usage](docs/AI_USAGE.md)
