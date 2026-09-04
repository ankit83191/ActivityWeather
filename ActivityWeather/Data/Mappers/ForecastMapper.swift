import Foundation

enum ForecastMapper {
    static func weeklyForecast(from dto: ForecastResponseDTO) throws -> WeeklyForecast {
        guard let timezone = dto.timezone?.trimmingCharacters(in: .whitespacesAndNewlines),
              !timezone.isEmpty else {
            throw DomainError.missingCriticalData
        }
        guard let daily = dto.daily else {
            throw DomainError.missingCriticalData
        }
        guard let units = dto.dailyUnits else {
            throw DomainError.missingCriticalData
        }

        try validateUnits(units)

        let times = try requireArray(daily.time, expectedCount: nil)
        let weatherCodes = try requireArray(daily.weatherCode, expectedCount: times.count)
        let temperatureMax = try requireArray(daily.temperature2mMax, expectedCount: times.count)
        let temperatureMin = try requireArray(daily.temperature2mMin, expectedCount: times.count)
        let apparentMax = try requireArray(daily.apparentTemperatureMax, expectedCount: times.count)
        let precipitation = try requireArray(daily.precipitationSum, expectedCount: times.count)
        let rain = try requireArray(daily.rainSum, expectedCount: times.count)
        let snowfall = try requireArray(daily.snowfallSum, expectedCount: times.count)
        let precipitationHours = try requireArray(daily.precipitationHours, expectedCount: times.count)
        let windSpeed = try requireArray(daily.windSpeed10mMax, expectedCount: times.count)
        let windGusts = try requireArray(daily.windGusts10mMax, expectedCount: times.count)
        let sunshine = try requireArray(daily.sunshineDuration, expectedCount: times.count)
        let daylight = try requireArray(daily.daylightDuration, expectedCount: times.count)
        let uvIndex = try requireArray(daily.uvIndexMax, expectedCount: times.count)

        let days = try times.indices.map { index in
            try DailyForecast(
                date: try civilDate(from: times[index]),
                weatherCode: weatherCodes[index],
                maximumTemperatureCelsius: temperatureMax[index],
                minimumTemperatureCelsius: temperatureMin[index],
                maximumApparentTemperatureCelsius: apparentMax[index],
                precipitationMillimetres: precipitation[index],
                rainMillimetres: rain[index],
                snowfallCentimetres: snowfall[index],
                precipitationHours: precipitationHours[index],
                maximumWindSpeedKilometresPerHour: windSpeed[index],
                maximumWindGustKilometresPerHour: windGusts[index],
                sunshineDurationSeconds: sunshine[index],
                daylightDurationSeconds: daylight[index],
                maximumUVIndex: uvIndex[index]
            )
        }

        return try WeeklyForecast(timeZoneIdentifier: timezone, days: days)
    }

    private static func requireArray<Value>(
        _ values: [Value?]?,
        expectedCount: Int?
    ) throws -> [Value] {
        guard let values else {
            throw DomainError.missingCriticalData
        }
        if let expectedCount, values.count != expectedCount {
            throw DomainError.missingCriticalData
        }
        return try values.map { value in
            guard let value else {
                throw DomainError.missingCriticalData
            }
            return value
        }
    }

    private static func civilDate(from raw: String) throws -> CivilDate {
        let parts = raw.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4,
              parts[1].count == 2,
              parts[2].count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            throw DomainError.invalidCivilDate
        }
        return try CivilDate(year: year, month: month, day: day)
    }

    private static func validateUnits(_ units: ForecastDailyUnitsDTO) throws {
        try expect(units.time, field: "time", expected: "iso8601")
        try expect(units.weatherCode, field: "weather_code", expected: "wmo code")
        try expect(units.temperature2mMax, field: "temperature_2m_max", expected: "°C")
        try expect(units.temperature2mMin, field: "temperature_2m_min", expected: "°C")
        try expect(units.apparentTemperatureMax, field: "apparent_temperature_max", expected: "°C")
        try expect(units.precipitationSum, field: "precipitation_sum", expected: "mm")
        try expect(units.rainSum, field: "rain_sum", expected: "mm")
        try expect(units.snowfallSum, field: "snowfall_sum", expected: "cm")
        try expect(units.precipitationHours, field: "precipitation_hours", expected: "h")
        try expect(units.windSpeed10mMax, field: "wind_speed_10m_max", expected: "km/h")
        try expect(units.windGusts10mMax, field: "wind_gusts_10m_max", expected: "km/h")
        try expect(units.sunshineDuration, field: "sunshine_duration", expected: "s")
        try expect(units.daylightDuration, field: "daylight_duration", expected: "s")
        try expectUV(units.uvIndexMax)
    }

    private static func expect(_ actual: String?, field: String, expected: String) throws {
        let value = actual ?? ""
        guard value == expected else {
            throw ForecastMappingError.unexpectedUnit(field: field, expected: expected, actual: value)
        }
    }

    private static func expectUV(_ actual: String?) throws {
        let value = actual ?? ""
        guard value == "" || value == "Index" else {
            throw ForecastMappingError.unexpectedUnit(field: "uv_index_max", expected: "", actual: value)
        }
    }
}
