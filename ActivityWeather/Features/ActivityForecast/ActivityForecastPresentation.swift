import Foundation

struct RankedForecastDay: Equatable, Identifiable {
    let rank: Int
    let suitability: DailyActivitySuitability
    let forecast: DailyForecast

    var id: CivilDate {
        suitability.date
    }
}

struct WeatherFact: Equatable, Identifiable {
    let label: String
    let value: String

    var id: String {
        label
    }
}

enum ActivityForecastPresentation {
    static func rankedDays(
        in result: LocationActivityForecast,
        for activity: Activity
    ) -> [RankedForecastDay]? {
        guard let ranking = result.rankings.first(where: {
            $0.activity == activity
        }) else {
            return nil
        }

        let forecastsByDate = result.forecast.days.reduce(
            into: [CivilDate: DailyForecast]()
        ) { lookup, forecast in
            lookup[forecast.date] = forecast
        }

        var rows: [RankedForecastDay] = []
        for (offset, suitability) in ranking.days.enumerated() {
            guard let forecast = forecastsByDate[suitability.date] else {
                return nil
            }
            rows.append(
                RankedForecastDay(
                    rank: offset + 1,
                    suitability: suitability,
                    forecast: forecast
                )
            )
        }
        return rows
    }

    static func weatherFacts(
        for forecast: DailyForecast,
        activity: Activity,
        locale: Locale = .current
    ) -> [WeatherFact] {
        switch activity {
        case .skiing:
            [
                WeatherFact(
                    label: "Temperature",
                    value: metric(forecast.maximumTemperatureCelsius, unit: "°C", locale: locale)
                ),
                WeatherFact(
                    label: "Snow",
                    value: metric(forecast.snowfallCentimetres, unit: "cm", locale: locale)
                ),
                WeatherFact(
                    label: "Wind gust",
                    value: metric(
                        forecast.maximumWindGustKilometresPerHour,
                        unit: "km/h",
                        locale: locale
                    )
                )
            ]
        case .surfing:
            [
                WeatherFact(
                    label: "Air temperature",
                    value: metric(forecast.maximumTemperatureCelsius, unit: "°C", locale: locale)
                ),
                WeatherFact(
                    label: "Rain",
                    value: metric(forecast.rainMillimetres, unit: "mm", locale: locale)
                ),
                WeatherFact(
                    label: "Wind",
                    value: metric(
                        forecast.maximumWindSpeedKilometresPerHour,
                        unit: "km/h",
                        locale: locale
                    )
                )
            ]
        case .outdoorSightseeing:
            [
                WeatherFact(
                    label: "Feels like",
                    value: metric(
                        forecast.maximumApparentTemperatureCelsius,
                        unit: "°C",
                        locale: locale
                    )
                ),
                WeatherFact(
                    label: "Precipitation",
                    value: metric(forecast.precipitationMillimetres, unit: "mm", locale: locale)
                ),
                WeatherFact(
                    label: "Wind gust",
                    value: metric(
                        forecast.maximumWindGustKilometresPerHour,
                        unit: "km/h",
                        locale: locale
                    )
                )
            ]
        case .indoorSightseeing:
            [
                WeatherFact(
                    label: "Feels like",
                    value: metric(
                        forecast.maximumApparentTemperatureCelsius,
                        unit: "°C",
                        locale: locale
                    )
                ),
                WeatherFact(
                    label: "Precipitation",
                    value: metric(forecast.precipitationMillimetres, unit: "mm", locale: locale)
                ),
                WeatherFact(
                    label: "Precipitation time",
                    value: metric(forecast.precipitationHours, unit: "h", locale: locale)
                )
            ]
        }
    }

    static func accessibilitySummary(
        for row: RankedForecastDay,
        timeZoneIdentifier: String,
        locale: Locale = .current
    ) -> String {
        let date = ForecastDateFormatting.string(
            for: row.suitability.date,
            timeZoneIdentifier: timeZoneIdentifier,
            locale: locale
        ) ?? "Date unavailable"
        let facts = weatherFacts(
            for: row.forecast,
            activity: row.suitability.activity,
            locale: locale
        )
        .map { "\($0.label) \($0.value)." }
        .joined(separator: " ")

        var summary = "Rank \(row.rank). \(date). "
            + "Score \(row.suitability.score.value) out of 100, "
            + "\(row.suitability.level.rawValue). \(facts)"

        if !row.suitability.reasons.isEmpty {
            let reasons = row.suitability.reasons
                .map(\.presentationText)
                .joined(separator: "; ")
            summary += " Reasons: \(reasons)."
        }
        return summary
    }

    private static func metric(
        _ value: Double,
        unit: String,
        locale: Locale
    ) -> String {
        let number = value.formatted(
            .number
                .precision(.fractionLength(0...1))
                .locale(locale)
        )
        return "\(number) \(unit)"
    }
}

enum ForecastDateFormatting {
    static func string(
        for date: CivilDate,
        timeZoneIdentifier: String,
        locale: Locale = .current
    ) -> String? {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = DateComponents(
            calendar: calendar,
            timeZone: timeZone,
            year: date.year,
            month: date.month,
            day: date.day,
            hour: 12
        )
        guard let value = calendar.date(from: components) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = timeZone
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEEEMMMMd")
        return formatter.string(from: value)
    }
}

extension Activity {
    var shortDisplayName: String {
        switch self {
        case .skiing: "Skiing"
        case .surfing: "Surfing"
        case .outdoorSightseeing: "Outdoor"
        case .indoorSightseeing: "Indoor"
        }
    }

    var accessibilityDisplayName: String {
        switch self {
        case .skiing: "Skiing"
        case .surfing: "Surfing"
        case .outdoorSightseeing: "Outdoor sightseeing"
        case .indoorSightseeing: "Indoor sightseeing"
        }
    }
}

extension SuitabilityReason {
    var presentationText: String {
        switch self {
        case .criticalThunderstorm: "Thunderstorm makes outdoor activity unsafe"
        case .criticalFreezingRain: "Freezing rain makes outdoor activity unsafe"
        case .criticalExtremeWind: "Extreme gusts make outdoor activity unsafe"
        case .dangerousTravelCap: "Dangerous travel conditions limit the score"
        case .stayInside: "Conditions favour staying inside"
        case .snowfallAmount: "Fresh snowfall improves conditions"
        case .snowWeather: "Snow-friendly weather"
        case .heavySnowPenalty: "Heavy active snowfall reduces visibility"
        case .freezingDrizzlePenalty: "Freezing drizzle creates icy conditions"
        case .rainOnSnow: "Rain may damage the snow surface"
        case .freezeMax: "Temperature supports snow conditions"
        case .skiWind: "Strong wind reduces ski comfort"
        case .skiSunshine: "Sunshine improves visibility"
        case .windProxy: "Wind is used as a surf-condition proxy"
        case .fairSky: "Fair skies improve comfort"
        case .surfRain: "Rain reduces surf comfort"
        case .airTempComfort: "Air temperature affects comfort"
        case .snowAtCoast: "Snow suggests poor coastal conditions"
        case .comfortTemp: "Feels-like temperature affects comfort"
        case .dry: "Precipitation level affects walking comfort"
        case .sunRatio: "Available sunshine affects outdoor comfort"
        case .uv: "UV level affects outdoor suitability"
        case .fog: "Fog reduces visibility"
        case .outdoorWind: "Gusts reduce walking comfort"
        case .heavySnowWalk: "Heavy snow makes walking difficult"
        case .violentRain: "Violent rain reduces suitability"
        case .wetDay: "Wet weather favours indoor plans"
        case .longPrecip: "Long-lasting precipitation favours indoor plans"
        case .rainCodes: "Rainy conditions favour indoor plans"
        case .tempExtreme: "Temperature extremes favour indoor plans"
        case .overcast: "Overcast skies favour indoor plans"
        case .beautifulOutdoor: "Pleasant outdoor weather lowers indoor preference"
        }
    }
}
