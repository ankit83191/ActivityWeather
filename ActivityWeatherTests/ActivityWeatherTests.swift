import XCTest
@testable import ActivityWeather

final class CoordinateTests: XCTestCase {
    func testAcceptsBoundaryCoordinates() throws {
        XCTAssertEqual(try Coordinate(latitude: -90, longitude: -180).latitude, -90)
        XCTAssertEqual(try Coordinate(latitude: 90, longitude: 180).longitude, 180)
    }

    func testRejectsOutOfRangeAndNonFiniteCoordinates() {
        XCTAssertThrowsError(try Coordinate(latitude: -90.1, longitude: 0))
        XCTAssertThrowsError(try Coordinate(latitude: 0, longitude: 180.1))
        XCTAssertThrowsError(try Coordinate(latitude: .nan, longitude: 0))
        XCTAssertThrowsError(try Coordinate(latitude: 0, longitude: .infinity))
    }
}

final class SuitabilityScoreTests: XCTestCase {
    func testAcceptsInclusiveBoundsAndDerivesLevels() throws {
        XCTAssertEqual(try SuitabilityScore(0).level, .poor)
        XCTAssertEqual(try SuitabilityScore(24).level, .poor)
        XCTAssertEqual(try SuitabilityScore(25).level, .fair)
        XCTAssertEqual(try SuitabilityScore(49).level, .fair)
        XCTAssertEqual(try SuitabilityScore(50).level, .good)
        XCTAssertEqual(try SuitabilityScore(74).level, .good)
        XCTAssertEqual(try SuitabilityScore(75).level, .great)
        XCTAssertEqual(try SuitabilityScore(100).level, .great)
    }

    func testRejectsValuesOutsideBoundsWithDomainError() {
        XCTAssertThrowsError(try SuitabilityScore(-1)) {
            XCTAssertEqual($0 as? DomainError, .invalidScore(-1))
        }
        XCTAssertThrowsError(try SuitabilityScore(101)) {
            XCTAssertEqual($0 as? DomainError, .invalidScore(101))
        }
    }
}

final class CivilDateTests: XCTestCase {
    func testValidatesGregorianDatesIncludingLeapYears() throws {
        XCTAssertEqual(try CivilDate(year: 2028, month: 2, day: 29).day, 29)
        XCTAssertThrowsError(try CivilDate(year: 2027, month: 2, day: 29))
        XCTAssertThrowsError(try CivilDate(year: 2026, month: 13, day: 1))
    }

    func testComparesByCalendarComponents() throws {
        let earlier = try CivilDate(year: 2026, month: 12, day: 31)
        let later = try CivilDate(year: 2027, month: 1, day: 1)

        XCTAssertLessThan(earlier, later)
    }

    func testRecognizesOnlyTheNextConsecutiveCivilDay() throws {
        let februaryEnd = try CivilDate(year: 2028, month: 2, day: 29)
        let marchStart = try CivilDate(year: 2028, month: 3, day: 1)
        let marchSecond = try CivilDate(year: 2028, month: 3, day: 2)

        XCTAssertTrue(februaryEnd.isImmediatelyBefore(marchStart))
        XCTAssertFalse(februaryEnd.isImmediatelyBefore(marchSecond))
    }
}

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
        DailyForecast(
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

final class ActivityDomainTests: XCTestCase {
    func testAllActivitiesAreCompleteAndInStableDisplayOrder() {
        XCTAssertEqual(
            Activity.allCases,
            [.skiing, .surfing, .outdoorSightseeing, .indoorSightseeing]
        )
    }

    func testLocationIdentityDependsOnlyOnGeocodingIdentifier() throws {
        let coordinate = try Coordinate(latitude: 51.5, longitude: -0.1)
        let original = Location(
            id: 42,
            displayName: "London",
            region: "England",
            country: "United Kingdom",
            coordinate: coordinate,
            elevationMetres: 11,
            geocodingTimeZoneIdentifier: "Europe/London"
        )
        let renamed = Location(
            id: 42,
            displayName: "Greater London",
            region: nil,
            country: "UK",
            coordinate: coordinate,
            elevationMetres: nil,
            geocodingTimeZoneIdentifier: nil
        )

        XCTAssertEqual(original, renamed)
        XCTAssertEqual(Set([original, renamed]).count, 1)
    }

    func testDailySuitabilityDerivesLevelFromScoreAndZeroRemainsScored() throws {
        let result = DailyActivitySuitability(
            date: try CivilDate(year: 2026, month: 9, day: 4),
            activity: .skiing,
            score: try SuitabilityScore(0),
            reasons: [.rainOnSnow]
        )

        XCTAssertEqual(result.score.value, 0)
        XCTAssertEqual(result.level, .poor)
    }
}
