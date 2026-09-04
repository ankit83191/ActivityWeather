import XCTest
@testable import ActivityWeather

final class ForecastMapperTests: XCTestCase {
    func testMapsSevenConsecutiveLocalDatesAndPreservesIANATimezone() throws {
        let forecast = try ForecastMapper.weeklyForecast(
            from: ForecastFixture.decodeResponse(named: "forecast_success_seven_days")
        )

        XCTAssertEqual(forecast.timeZoneIdentifier, "Europe/Berlin")
        XCTAssertEqual(forecast.days.count, 7)
        XCTAssertEqual(forecast.days[0].date, try CivilDate(year: 2026, month: 9, day: 4))
        XCTAssertEqual(forecast.days[6].date, try CivilDate(year: 2026, month: 9, day: 10))
        XCTAssertEqual(forecast.days[0].weatherCode, 80)
        XCTAssertEqual(forecast.days[0].maximumTemperatureCelsius, 25.4)
        XCTAssertTrue(
            zip(forecast.days, forecast.days.dropFirst()).allSatisfy { current, next in
                current.date.isImmediatelyBefore(next.date)
            }
        )
    }

    func testMissingDailyThrowsMissingCriticalData() throws {
        try assertMissing("forecast_missing_daily")
    }

    func testMissingDailyUnitsThrowsMissingCriticalData() throws {
        try assertMissing("forecast_missing_daily_units")
    }

    func testMissingTimezoneThrowsMissingCriticalData() throws {
        try assertMissing("forecast_missing_timezone")
    }

    func testMissingTimeArrayThrowsMissingCriticalData() throws {
        try assertMissing("forecast_missing_time")
    }

    func testMissingRequiredArrayThrowsMissingCriticalData() throws {
        try assertMissing("forecast_missing_weather_code")
    }

    func testNullRequiredElementThrowsMissingCriticalData() throws {
        try assertMissing("forecast_null_weather_code")
    }

    func testMismatchedArrayLengthsThrowMissingCriticalData() throws {
        try assertMissing("forecast_mismatched_lengths")
    }

    func testWrongJSONTypeFailsDecodingRatherThanMapping() {
        XCTAssertThrowsError(try ForecastFixture.decodeResponse(named: "forecast_wrong_types")) { error in
            XCTAssertNil(error as? DomainError)
            XCTAssertNil(error as? ForecastMappingError)
        }
    }

    func testUnexpectedUnitIsNotMissingCriticalData() throws {
        let dto = try ForecastFixture.decodeResponse(named: "forecast_unexpected_unit")
        XCTAssertThrowsError(try ForecastMapper.weeklyForecast(from: dto)) { error in
            XCTAssertEqual(
                error as? ForecastMappingError,
                .unexpectedUnit(field: "temperature_2m_max", expected: "°C", actual: "°F")
            )
            XCTAssertNotEqual(error as? DomainError, .missingCriticalData)
        }
    }

    func testInvalidTimezoneThrowsInvalidForecastTimezone() throws {
        let dto = try decodedSuccessReplacing("Europe/Berlin", with: "Not/A_Zone")
        XCTAssertThrowsError(try ForecastMapper.weeklyForecast(from: dto)) { error in
            XCTAssertEqual(error as? DomainError, .invalidForecastTimezone)
        }
    }

    func testMapsIndianTimezoneIdentifierReturnedByForecastAPI() throws {
        let dto = try decodedSuccessReplacing("Europe/Berlin", with: "Asia/Kolkata")
        let forecast = try ForecastMapper.weeklyForecast(from: dto)

        XCTAssertEqual(forecast.timeZoneIdentifier, "Asia/Kolkata")
        XCTAssertEqual(forecast.days.count, 7)
    }

    func testIllegalNumericValuesThrowInvalidForecastValues() throws {
        let dto = try decodedSuccessReplacing("\"snowfall_sum\": [0.0,", with: "\"snowfall_sum\": [-1.0,")
        XCTAssertThrowsError(try ForecastMapper.weeklyForecast(from: dto)) { error in
            XCTAssertEqual(error as? DomainError, .invalidForecastValues)
        }
    }

    func testFewerDaysThrowInvalidForecastWindow() throws {
        let dto = try ForecastFixture.decodeResponse(named: "forecast_fewer_days")
        XCTAssertThrowsError(try ForecastMapper.weeklyForecast(from: dto)) { error in
            XCTAssertEqual(error as? DomainError, .invalidForecastWindow)
        }
    }

    func testExtraDaysThrowInvalidForecastWindow() throws {
        let dto = try ForecastFixture.decodeResponse(named: "forecast_extra_days")
        XCTAssertThrowsError(try ForecastMapper.weeklyForecast(from: dto)) { error in
            XCTAssertEqual(error as? DomainError, .invalidForecastWindow)
        }
    }

    func testInvalidDateThrowsInvalidCivilDate() throws {
        let dto = try ForecastFixture.decodeResponse(named: "forecast_invalid_date")
        XCTAssertThrowsError(try ForecastMapper.weeklyForecast(from: dto)) { error in
            XCTAssertEqual(error as? DomainError, .invalidCivilDate)
        }
    }

    private func decodedSuccessReplacing(_ original: String, with replacement: String) throws -> ForecastResponseDTO {
        let json = try XCTUnwrap(String(data: ForecastFixture.data(named: "forecast_success_seven_days"), encoding: .utf8))
        return try JSONDecoder().decode(
            ForecastResponseDTO.self,
            from: Data(json.replacingOccurrences(of: original, with: replacement).utf8)
        )
    }

    private func assertMissing(_ fixture: String) throws {
        let dto = try ForecastFixture.decodeResponse(named: fixture)
        XCTAssertThrowsError(try ForecastMapper.weeklyForecast(from: dto)) { error in
            XCTAssertEqual(error as? DomainError, .missingCriticalData)
            XCTAssertNil(error as? ForecastMappingError)
        }
    }
}
