import XCTest
@testable import ActivityWeather

final class DailyForecastTests: XCTestCase {
    func testAcceptsFiniteValuesIncludingNegativeTemperatures() throws {
        let forecast = try DailyForecast(
            date: try CivilDate(year: 2026, month: 1, day: 1),
            weatherCode: 71,
            maximumTemperatureCelsius: -5,
            minimumTemperatureCelsius: -12,
            maximumApparentTemperatureCelsius: -8,
            precipitationMillimetres: 0,
            rainMillimetres: 0,
            snowfallCentimetres: 4,
            precipitationHours: 24,
            maximumWindSpeedKilometresPerHour: 0,
            maximumWindGustKilometresPerHour: 0,
            sunshineDurationSeconds: 0,
            daylightDurationSeconds: 0,
            maximumUVIndex: 0
        )

        XCTAssertEqual(forecast.snowfallCentimetres, 4)
        XCTAssertEqual(forecast.precipitationHours, 24)
    }

    func testRejectsNonFiniteNumericValues() {
        XCTAssertThrowsError(
            try makeForecast(maximumTemperatureCelsius: .nan)
        ) {
            XCTAssertEqual($0 as? DomainError, .invalidForecastValues)
        }
        XCTAssertThrowsError(
            try makeForecast(maximumWindSpeedKilometresPerHour: .infinity)
        ) {
            XCTAssertEqual($0 as? DomainError, .invalidForecastValues)
        }
    }

    func testRejectsNegativeAmountsDurationsWindAndUV() {
        XCTAssertThrowsError(try makeForecast(precipitationMillimetres: -0.1))
        XCTAssertThrowsError(try makeForecast(rainMillimetres: -0.1))
        XCTAssertThrowsError(try makeForecast(snowfallCentimetres: -0.1))
        XCTAssertThrowsError(try makeForecast(maximumWindSpeedKilometresPerHour: -1))
        XCTAssertThrowsError(try makeForecast(maximumWindGustKilometresPerHour: -1))
        XCTAssertThrowsError(try makeForecast(sunshineDurationSeconds: -1))
        XCTAssertThrowsError(try makeForecast(daylightDurationSeconds: -1))
        XCTAssertThrowsError(try makeForecast(maximumUVIndex: -0.1))
    }

    func testRejectsPrecipitationHoursOutsideADay() {
        XCTAssertThrowsError(try makeForecast(precipitationHours: -0.1))
        XCTAssertThrowsError(try makeForecast(precipitationHours: 24.1))
    }

    func testRejectsSunshineLongerThanDaylight() {
        XCTAssertThrowsError(
            try makeForecast(
                sunshineDurationSeconds: 10,
                daylightDurationSeconds: 9
            )
        ) {
            XCTAssertEqual($0 as? DomainError, .invalidForecastValues)
        }
    }

    private func makeForecast(
        maximumTemperatureCelsius: Double = 20,
        precipitationMillimetres: Double = 0,
        rainMillimetres: Double = 0,
        snowfallCentimetres: Double = 0,
        precipitationHours: Double = 0,
        maximumWindSpeedKilometresPerHour: Double = 10,
        maximumWindGustKilometresPerHour: Double = 15,
        sunshineDurationSeconds: Double = 1_000,
        daylightDurationSeconds: Double = 2_000,
        maximumUVIndex: Double = 4
    ) throws -> DailyForecast {
        try DailyForecast(
            date: try CivilDate(year: 2026, month: 1, day: 1),
            weatherCode: 0,
            maximumTemperatureCelsius: maximumTemperatureCelsius,
            minimumTemperatureCelsius: 10,
            maximumApparentTemperatureCelsius: 18,
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
}
