import XCTest
@testable import ActivityWeather

final class WeeklyForecastTests: XCTestCase {
    func testAcceptsSevenConsecutiveDaysInAValidIANATimezone() throws {
        let forecast = try WeeklyForecast(
            timeZoneIdentifier: "Europe/London",
            days: try consecutiveDays()
        )

        XCTAssertEqual(forecast.days.count, 7)
        XCTAssertEqual(forecast.timeZoneIdentifier, "Europe/London")
    }

    func testRejectsInvalidTimezoneAndWrongDayCount() throws {
        XCTAssertThrowsError(
            try WeeklyForecast(
                timeZoneIdentifier: "",
                days: try consecutiveDays()
            )
        )
        XCTAssertThrowsError(
            try WeeklyForecast(
                timeZoneIdentifier: "Not/A_Timezone",
                days: try consecutiveDays()
            )
        )
        XCTAssertThrowsError(
            try WeeklyForecast(
                timeZoneIdentifier: "Europe/London",
                days: Array(try consecutiveDays().dropLast())
            )
        )
    }

    func testRejectsDuplicateDates() throws {
        var days = try consecutiveDays()
        days[3] = days[2]

        XCTAssertThrowsError(
            try WeeklyForecast(timeZoneIdentifier: "Europe/London", days: days)
        )
    }

    func testRejectsOutOfOrderDates() throws {
        var days = try consecutiveDays()
        days.swapAt(2, 3)

        XCTAssertThrowsError(
            try WeeklyForecast(timeZoneIdentifier: "Europe/London", days: days)
        )
    }

    func testRejectsNonConsecutiveDates() throws {
        var days = try consecutiveDays()
        days[6] = try makeForecast(year: 2027, month: 1, day: 7)

        XCTAssertThrowsError(
            try WeeklyForecast(timeZoneIdentifier: "Europe/London", days: days)
        )
    }

    private func consecutiveDays() throws -> [DailyForecast] {
        [
            try makeForecast(year: 2026, month: 12, day: 29),
            try makeForecast(year: 2026, month: 12, day: 30),
            try makeForecast(year: 2026, month: 12, day: 31),
            try makeForecast(year: 2027, month: 1, day: 1),
            try makeForecast(year: 2027, month: 1, day: 2),
            try makeForecast(year: 2027, month: 1, day: 3),
            try makeForecast(year: 2027, month: 1, day: 4)
        ]
    }

    private func makeForecast(year: Int, month: Int, day: Int) throws -> DailyForecast {
        try DailyForecast(
            date: try CivilDate(year: year, month: month, day: day),
            weatherCode: 0,
            maximumTemperatureCelsius: 20,
            minimumTemperatureCelsius: 10,
            maximumApparentTemperatureCelsius: 20,
            precipitationMillimetres: 0,
            rainMillimetres: 0,
            snowfallCentimetres: 0,
            precipitationHours: 0,
            maximumWindSpeedKilometresPerHour: 10,
            maximumWindGustKilometresPerHour: 15,
            sunshineDurationSeconds: 28_800,
            daylightDurationSeconds: 43_200,
            maximumUVIndex: 4
        )
    }
}
