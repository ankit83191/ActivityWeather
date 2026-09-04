import XCTest
@testable import ActivityWeather

enum ScoringFixture {
    static func day(
        year: Int = 2026,
        month: Int = 9,
        day: Int = 4,
        weatherCode: Int = 0,
        maximumTemperatureCelsius: Double = 0,
        minimumTemperatureCelsius: Double = -5,
        maximumApparentTemperatureCelsius: Double = 0,
        precipitationMillimetres: Double = 0,
        rainMillimetres: Double = 0,
        snowfallCentimetres: Double = 0,
        precipitationHours: Double = 0,
        maximumWindSpeedKilometresPerHour: Double = 20,
        maximumWindGustKilometresPerHour: Double = 25,
        sunshineDurationSeconds: Double = 12_000,
        daylightDurationSeconds: Double = 40_000,
        maximumUVIndex: Double = 1
    ) throws -> DailyForecast {
        try DailyForecast(
            date: try CivilDate(year: year, month: month, day: day),
            weatherCode: weatherCode,
            maximumTemperatureCelsius: maximumTemperatureCelsius,
            minimumTemperatureCelsius: minimumTemperatureCelsius,
            maximumApparentTemperatureCelsius: maximumApparentTemperatureCelsius,
            precipitationMillimetres: precipitationMillimetres,
            rainMillimetres: rainMillimetres,
            snowfallCentimetres: snowfallCentimetres,
            precipitationHours: precipitationHours,
            maximumWindSpeedKilometresPerHour: maximumWindSpeedKilometresPerHour,
            maximumWindGustKilometresPerHour: maximumWindGustKilometresPerHour,
            sunshineDurationSeconds: sunshineDurationSeconds,
            daylightDurationSeconds: daylightDurationSeconds,
            maximumUVIndex: maximumUVIndex
        )
    }

    static func week() throws -> WeeklyForecast {
        let days = try (0..<7).map { offset in
            try day(year: 2026, month: 9, day: 4 + offset)
        }
        return try WeeklyForecast(timeZoneIdentifier: "Europe/London", days: days)
    }
}
