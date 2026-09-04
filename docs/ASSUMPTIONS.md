# Product assumptions

Version-one product rules for Activity Weather. Scoring arithmetic lives in [SCORING.md](SCORING.md). These assumptions constrain later milestones; they do not implement them.

## What a score means

A score is **weather suitability** for an activity on a calendar day. It is **not** proof that a ski resort, beach, surf break, museum, or other infrastructure exists at the selected coordinates. A high skiing score on a city-centre grid cell means the **weather** resembles a ski-friendly day, not that lifts are nearby.

## Location selection

The user **explicitly selects** one Open-Meteo Geocoding result. The app never silently chooses the first hit when the query is ambiguous.

## Forecast window, timezone, and units

- Request **exactly seven** forecast days: `forecast_days=7` on [Open-Meteo Forecast API](https://open-meteo.com/en/docs) (`/v1/forecast`). That window is the selected location’s **current local calendar day plus the following six local days**. The client does not compare the first returned date with the device clock.
- Timezone is **deterministic**: always pass `timezone=auto`. Persist and validate the IANA `timezone` **returned by the Forecast API**. Do **not** persist or use `utc_offset_seconds` for date calculations, and do not mix geocoding-result timezone into the request or interpretation.
- Daily `time` values (`YYYY-MM-DD`) are interpreted as civil dates in the **IANA timezone returned by that Forecast response**.
- Metric units only: `temperature_unit=celsius`, `wind_speed_unit=kmh`, `precipitation_unit=mm`. Open-Meteo reports `snowfall_sum` in **centimetres**.

## Surfing is a weather proxy

Surfing v1 uses **Forecast API weather fields only** (wind, precipitation, air temperature, `weather_code`). It has **no** coastal validation, wave height, swell period/direction, sea-surface temperature, or tides. Those belong to the separate [Marine Weather API](https://open-meteo.com/en/docs/marine-weather-api), which is **out of v1**. The surfing number is a **weather proxy**, **not** a reliable or authoritative surfing forecast.

## Indoor sightseeing is independent

Indoor sightseeing has **its own** rules. It is **not** `100 - outdoorScore`. Weather that makes outdoor sightseeing poor can raise indoor suitability, but **dangerous travel weather must not produce a perfect indoor recommendation** (people still have to reach the venue). See [SCORING.md](SCORING.md) for the indoor travel-risk cap.

## Missing or misaligned data

If any **required** daily field is missing/null, or if daily arrays are not aligned with `time` (length mismatch or unordered dates), that day (or the whole forecast, when the payload is structurally unusable) is an **unavailable/error** result with reason `missingCriticalData`.

That result is **not** a score of `0`. Zero means “valid forecast, weather assessed as unsuitable.” Unavailable means “no assessment.”

v1 treats **every field listed in the scoring specification as required**. There are **no optional scoring fields** in v1.

## Open-Meteo usage and tests

The public Forecast and Geocoding endpoints do not require an API key for non-commercial use. Automated tests must **not** call the live network: they would be nondeterministic and would depend on an external service. From milestone 4 onward, repository tests use **fixtures** and an **injected mocked transport** (for example a `URLProtocol` stub). The app itself performs **one forecast request per explicit location selection**. No polling, no background refresh, no forecast cache.

## MVP exclusions

Not in version one:

- Accounts, authentication, user profiles
- App backend
- Persistence, search history, favourites
- Multiple-city comparison
- Maps
- Device location permission / current-location search
- Push notifications, widgets, Live Activities
- Resort, beach, or POI discovery
- Offline forecast caching
- Open-Meteo Marine API / wave-based surfing
- Additional activities beyond skiing, surfing, outdoor sightseeing, indoor sightseeing
