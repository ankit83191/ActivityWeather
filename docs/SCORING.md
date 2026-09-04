# Scoring specification (v1)

Implementable, explainable **product heuristic**. It is **not** a scientifically validated biometeorological or oceanographic model. Surfing in particular is a **weather proxy**, not a reliable surfing forecast.

Field names and units are taken from the [Open-Meteo Forecast API daily parameter list](https://open-meteo.com/en/docs) (checked 2026-09-04). WMO codes are Open-Meteo’s published subset of WMO WW interpretation codes.

Related product rules: [ASSUMPTIONS.md](ASSUMPTIONS.md).

## Request

`GET https://api.open-meteo.com/v1/forecast`

| Parameter | Value |
|---|---|
| `latitude`, `longitude` | Selected geocoding result |
| `forecast_days` | `7` |
| `timezone` | `auto` (store the timezone **returned** in the JSON) |
| `temperature_unit` | `celsius` |
| `wind_speed_unit` | `kmh` |
| `precipitation_unit` | `mm` |
| `daily` | comma-separated list below |

### Daily fields (all required in v1)

| Field | Unit | Role |
|---|---|---|
| `time` | ISO-8601 date in the **Forecast response timezone** | Day identity |
| `weather_code` | WMO WW | Severity, snow vs rain, veto/cap/penalty |
| `temperature_2m_max` | °C | Skiing freeze band; surfing air-comfort proxy |
| `temperature_2m_min` | °C | Required for payload completeness; skiing extreme-cold uses max, min must still be present |
| `apparent_temperature_max` | °C | Outdoor/indoor comfort |
| `precipitation_sum` | mm | Total wetness (rain + showers + snow water equivalent) |
| `rain_sum` | mm | Rain on snow; surfing rain |
| `snowfall_sum` | cm | Skiing snow amount |
| `precipitation_hours` | hours | Indoor “all-day rain” |
| `wind_speed_10m_max` | km/h | Skiing/surfing wind; gale checks |
| `wind_gusts_10m_max` | km/h | Outdoor veto, indoor travel cap, walking penalty |
| `sunshine_duration` | seconds | Outdoor sun ratio; skiing visibility bonus |
| `daylight_duration` | seconds | Denominator for sun ratio |
| `uv_index_max` | UV index | Outdoor sightseeing only (still **required** on the shared payload) |

**No optional fields in v1.** If any of these keys is absent, any element is JSON null, or any array length ≠ `time.count`, scoring does **not** run for the affected day (or for the whole forecast if `time` itself is unusable).

## Result types

Each activity on each day is one of:

1. **Unavailable** — `missingCriticalData`. **Not a numeric score.** Must not be displayed or sorted as `0`.
2. **Scored** — integer `0...100` plus reason codes. `0` means assessed as unsuitable weather.

```
raw = base + Σ named contributions
raw' = apply activity caps (if any)
score = clamp(Int(raw'.rounded(.toNearestOrAwayFromZero)), 0, 100)
```

`clamp` is inclusive `0...100`. Rounding is half away from zero (Swift `FloatingPointRoundingRule.toNearestOrAwayFromZero`).

### Suitability levels

The user-facing level is derived from the bounded integer score; callers never
supply it independently.

| Score | Level |
|---|---|
| `0...24` | Poor |
| `25...49` | Fair |
| `50...74` | Good |
| `75...100` | Great |

## Ranking

Among **scored** days for one activity:

1. `score` descending
2. calendar `time` ascending (earlier date wins a tie)

Unavailable results are omitted from ranking (they are errors, not last-place scores).

Weekly ranking is derived by scoring each of the seven days independently and
sorting that list. The product does **not** rank activities against one another.
`Activity.allCases` defines display order only: skiing, surfing, outdoor
sightseeing, then indoor sightseeing.

## WMO handling

Open-Meteo daily `weather_code` is the **most severe** condition that day.

| Codes | Meaning | Outdoor veto (ski, surf, outdoor sightseeing → **score 0**) | Indoor travel-risk **cap 40** | Otherwise |
|---|---|---|---|---|
| `95`, `96`, `99` | Thunderstorm; `96`/`99` include hail (hail codes mainly Central Europe) | Yes — lightning / hail is a life-safety outdoor risk, including water | Yes — travel to a venue is unsafe | Indoor may add `stayInside` **before** the cap; cap still applies so the day cannot look “perfect indoors” |
| `66`, `67` | Freezing rain | Yes — ice accretion, extreme slip and exposure | Yes | Not a skiing positive (ice ≠ snow) |
| `56`, `57` | Freezing drizzle | No — serious but below freezing-rain / thunderstorm | Yes — iced roads/paths | Named penalties on outdoor sightseeing and surfing; skiing `freezingDrizzlePenalty` |
| `82` | Violent rain showers | No — severe discomfort, not the same as thunderstorm | Yes — hazardous travel | `violentRain` penalty for outdoor sightseeing and surfing; skiing uses `rain_sum` / rain-on-snow, not this code as a veto |
| `75`, `86` | Heavy snowfall / heavy snow showers | **No** for skiing (see below). **No** thunderstorm-style veto for surf/outdoor | Yes — travel and urban mobility | Skiing: snow **amount** can still score; **heavy active snowfall is not treated as “ideal powder.”** Outdoor sightseeing: `heavySnowWalk` |
| `71`, `73`, `77`, `85` | Slight/moderate snow, grains, slight snow showers | No | No | Skiing **positive** `snowWeather` (fresh snow without the heavy-fall penalty) |
| Other | Clear, cloud, drizzle, ordinary rain, fog, etc. | No | No | Activity-specific signals |

### Wind thresholds (not WMO)

| Threshold | Effect | Why |
|---|---|---|
| `wind_gusts_10m_max ≥ 90` km/h | Outdoor **veto** (score 0) | Storm-force gusts: trees, debris, water, lift/exposure risk |
| `wind_gusts_10m_max ≥ 80` km/h | Indoor **travel cap 40** (if not already) | Travel is hazardous; indoor activity is not “perfect” |
| `wind_gusts_10m_max ≥ 50` km/h | Outdoor sightseeing penalty | Unpleasant / tiring walking |
| Activity wind bands | Skiing / surfing named weights | Comfort and (for surf) a **proxy** for wind-driven chop only |

### Skiing: fresh snow vs dangerous active snowfall

- **Fresh snow** (`snowfall_sum`, and codes `71`, `73`, `77`, `85`) is a **positive** skiing-weather signal.
- **Heavy snowfall / heavy snow showers** (`75`, `86`) are **not** an outdoor skiing veto and **not** automatically equivalent to a great ski day. They add `heavySnowPenalty` (visibility, storm intensity; avalanche and resort status are **unknowable** from this API). `snowfall_sum` may still add points. Net score can remain high on a cold, snowy day; it must not ignore the heavy-fall penalty.
- Indoor still **caps** `75`/`86` because **getting there** is the travel risk, independent of skiing’s snow bonus.

## Shared outdoor veto

If a veto applies to skiing, surfing, or outdoor sightseeing:

`score = 0` with the matching reason (`criticalThunderstorm`, `criticalFreezingRain`, `criticalExtremeWind`). Further additive terms are skipped.

When several outdoor veto conditions are true on the same day, emit **one** reason
using this priority: thunderstorm (`95`/`96`/`99`) → freezing rain (`66`/`67`) →
extreme gust (`wind_gusts_10m_max ≥ 90`). Raw weather values remain available to
the UI; a selected veto reason must not hide the underlying conditions.

Indoor **never** uses this veto. Indoor uses the travel-risk cap instead.

## Shared indoor travel-risk cap

If any of the following is true, after additive indoor terms: `score = min(score, 40)`.
Emit `dangerousTravelCap` **only when the uncapped raw score exceeds 40**:

- `weather_code` ∈ {`56`, `57`, `66`, `67`, `75`, `82`, `86`, `95`, `96`, `99`}
- `wind_gusts_10m_max ≥ 80`

If travel-risk is true but the additive raw score is already `≤ 40`, the cap does
not change the score and `dangerousTravelCap` is **not** emitted.

## Reason codes

Emit a reason only when that rule **changed** the score (non-zero contribution,
or an applied veto/cap). Deduplicate by reason code.

Order:

1. Veto or indoor travel cap first, when it applied.
2. Remaining reasons by **absolute contribution** descending.
3. Equal absolute contributions by stable `SuitabilityReason.rawValue` ascending.

`missingCriticalData` appears only on unavailable results.

`missingCriticalData`, `criticalThunderstorm`, `criticalFreezingRain`, `criticalExtremeWind`, `dangerousTravelCap`, `stayInside`, `snowfallAmount`, `snowWeather`, `heavySnowPenalty`, `freezingDrizzlePenalty`, `rainOnSnow`, `freezeMax`, `skiWind`, `skiSunshine`, `windProxy`, `fairSky`, `surfRain`, `airTempComfort`, `snowAtCoast`, `comfortTemp`, `dry`, `sunRatio`, `uv`, `fog`, `outdoorWind`, `heavySnowWalk`, `violentRain`, `wetDay`, `longPrecip`, `rainCodes`, `tempExtreme`, `overcast`, `beautifulOutdoor`

## Skiing

**Base: 45**

Apply outdoor veto first.

| Signal | Condition | Contribution | Cap / notes |
|---|---|---|---|
| `snowfallAmount` | `snowfall_sum` cm | `+3` per cm | Max **+30** |
| `snowWeather` | `weather_code` ∈ {`71`, `73`, `77`, `85`} | **+12** | Light/moderate fresh snow, not heavy codes |
| `heavySnowPenalty` | `weather_code` ∈ {`75`, `86`} | **−12** | Active heavy snow ≠ automatic powder day |
| `freezingDrizzlePenalty` | `weather_code` ∈ {`56`, `57`} | **−16** | Ice, not ski snow |
| `rainOnSnow` | `rain_sum ≥ 2` mm | **−18** | Rain wrecks snow surface |
| `freezeMax` | `temperature_2m_max` °C | `[−12, 1]`: **+18**; `(1, 4]`: **+8**; `(4, 8]`: **−10**; `> 8`: **−22**; `< −20`: **−12** | First matching band only (evaluate from the list in this order: `< −20`, then `[−12, 1]`, then `(1, 4]`, `(4, 8]`, `> 8`; if in `(−20, −12)` contribution is **0**) |
| `skiWind` | `wind_speed_10m_max` | `> 60`: **−22**; else `> 45`: **−12** | First match |
| `skiSunshine` | `sunshine_duration ≥ 14400` s (4 h) | **+5** | Visibility / pleasantness |

`temperature_2m_min`, `apparent_temperature_max`, `precipitation_sum`, `precipitation_hours`, `uv_index_max`, `daylight_duration` are still **required** on the payload even when unused in this table.

### Worked example (skiing)

Inputs: `weather_code=71`, `snowfall_sum=4`, `rain_sum=0`, `temperature_2m_max=3`, `wind_speed_10m_max=30`, `wind_gusts_10m_max=40`, `sunshine_duration=7200`, plus all other required fields present and non-null.

No veto. `45 + 12 (snowfallAmount) + 12 (snowWeather) + 8 (freezeMax) = 77`. Score **77**.
Reasons: `snowWeather`, `snowfallAmount`, `freezeMax` (`snowfallAmount` and
`snowWeather` both contribute 12; `snowWeather` sorts first by `rawValue`).

## Surfing (weather proxy)

**Not a surf forecast.** No Marine API, no break quality, no tides.

**Base: 50**

Apply outdoor veto first.

| Signal | Condition | Contribution |
|---|---|---|
| `windProxy` | `wind_speed_10m_max` km/h | `[12, 28]`: **+16**; `[8, 12)` or `(28, 40]`: **+6**; `< 8`: **−6**; `> 55`: **−28**; else `> 40`: **−18** (first match in this order: `< 8`, `[12, 28]`, `[8, 12)`, `(28, 40]`, `> 55`, `> 40`) |
| `fairSky` | `weather_code` | `{0, 1, 2}`: **+10**; `3`: **+4** |
| `surfRain` | `rain_sum` mm | `≤ 2`: **0**; `(2, 10]`: **−6**; `(10, 25]`: **−14**; `> 25`: **−22** |
| `violentRain` | `weather_code = 82` | **−10** (in addition to `surfRain`) |
| `freezingDrizzlePenalty` | `weather_code` ∈ {`56`, `57`} | **−14** |
| `airTempComfort` | `temperature_2m_max` °C (air, **not** SST) | First match: `< 12` → **−12**; `[18, 28]` → **+14**; `[14, 18)` → **+6**; `[28, 32]` → **+4**; `> 32` → **−8**; otherwise **0** (includes `[12, 14)`) |
| `snowAtCoast` | `snowfall_sum > 0` | **−10** |

### Worked example (surfing)

Inputs: `weather_code=1`, `wind_speed_10m_max=20`, `rain_sum=1`, `temperature_2m_max=22`, `snowfall_sum=0`, `wind_gusts_10m_max=28`, all required fields present.

No veto. `50 + 16 (windProxy) + 10 (fairSky) + 14 (airTempComfort) = 90`. Score **90**. Reasons: `windProxy`, `fairSky`, `airTempComfort`.

## Outdoor sightseeing

**Base: 50**

Apply outdoor veto first.

Let `sunRatio = sunshine_duration / daylight_duration`. If `daylight_duration == 0`
(valid polar night, with `sunshine_duration == 0` because sunshine cannot exceed
daylight), `sunRatio = 0`. Do **not** divide by zero. A ratio of `0` is a real
value: it can still match the `< 0.12` sun-ratio penalty.

| Signal | Condition | Contribution |
|---|---|---|
| `comfortTemp` | `apparent_temperature_max` °C | `[12, 24]`: **+20**; `[8, 12)` or `(24, 28]`: **+8**; `[4, 8)` or `(28, 32]`: **−8**; `< 4` or `> 32`: **−20** |
| `dry` | `precipitation_sum` mm | `0`: **+14**; `(0, 2]`: **+4**; `(2, 8]`: **−12**; `(8, 20]`: **−24**; `> 20`: **−32** |
| `sunRatio` | ratio | `≥ 0.55`: **+14**; `≥ 0.30`: **+6**; `< 0.12`: **−8**; else **0** (first match: `≥ 0.55`, then `≥ 0.30`, then `< 0.12`) |
| `uv` | `uv_index_max` | `[3, 7]`: **+4**; `≥ 11`: **−10** (WMO “extreme”); else **0**. If both could apply they cannot (`11` is not in `[3, 7]`). |
| `fog` | `weather_code` ∈ {`45`, `48`} | **−14** |
| `outdoorWind` | `wind_gusts_10m_max` | `≥ 70`: **−20**; else `≥ 50`: **−10** |
| `heavySnowWalk` | `weather_code` ∈ {`75`, `86`} | **−18** |
| `violentRain` | `weather_code = 82` | **−16** |
| `freezingDrizzlePenalty` | `weather_code` ∈ {`56`, `57`} | **−14** |

### Worked example (outdoor sightseeing)

Inputs: `apparent_temperature_max=18`, `precipitation_sum=3`, `sunshine_duration=12000`, `daylight_duration=40000`, `uv_index_max=5`, `weather_code=61`, `wind_gusts_10m_max=20`, all required fields present.

`sunRatio = 0.30`. No veto. `50 + 20 (comfortTemp) − 12 (dry) + 6 (sunRatio) + 4 (uv) = 68`. Score **68**. Reasons: `comfortTemp`, `dry`, `sunRatio`, `uv`.

## Indoor sightseeing

**Base: 48**. Never derived from outdoor score.

**No outdoor veto.** Apply additives, then the travel-risk cap.

| Signal | Condition | Contribution |
|---|---|---|
| `wetDay` | `precipitation_sum` mm | `≥ 8`: **+18**; else `≥ 3`: **+8** |
| `longPrecip` | `precipitation_hours ≥ 6` | **+8** |
| `rainCodes` | `weather_code` ∈ {`51`, `53`, `55`, `61`, `63`, `65`, `80`, `81`} | **+8** |
| `tempExtreme` | `apparent_temperature_max < 5` or `> 32` | **+12** |
| `fog` | `weather_code` ∈ {`45`, `48`} | **+6** |
| `overcast` | `weather_code = 3` | **+4** |
| `stayInside` | `weather_code` ∈ {`95`, `96`, `99`} | **+6** (then cap) |
| `beautifulOutdoor` | `precipitation_sum == 0` **and** `apparent_temperature_max ∈ [16, 26]` **and** `sunRatio ≥ 0.50` | **−16** |

Then apply **indoor travel-risk cap 40** if the shared cap condition holds.

### Worked example (indoor, ordinary rain)

Inputs: `precipitation_sum=12`, `precipitation_hours=7`, `weather_code=63`, `apparent_temperature_max=12`, `sunshine_duration=2000`, `daylight_duration=40000`, `wind_gusts_10m_max=25`, all required fields present.

No travel cap (63 is not in the cap set). `48 + 18 (wetDay) + 8 (longPrecip) + 8 (rainCodes) = 82`. Score **82**. Reasons: `wetDay`, `longPrecip`, `rainCodes`.

### Worked example (indoor, thunderstorm — must not be perfect)

Inputs: `weather_code=95`, `precipitation_sum=15`, `precipitation_hours=4`, `apparent_temperature_max=20`, `wind_gusts_10m_max=40`, all required fields present.

`48 + 18 (wetDay) + 6 (stayInside) = 72`, then `min(72, 40) = 40`. Score **40**.
Reasons: `dangerousTravelCap`, `wetDay`, `stayInside` (cap first, then absolute
contribution).

## Bounds check (v1)

Theoretical raw sums before clamp stay within a few tens of points of `0...100` for normal meteorological ranges; clamp is still mandatory. Veto produces exactly `0`. Indoor cap produces at most `40` when travel-risk fires. Unavailable paths produce **no** integer.

## Implementation note

Milestone 7 implements this table in Domain scoring. This document is the
contract; later code must not invent extra weights without a spec change.
