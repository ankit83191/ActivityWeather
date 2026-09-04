import XCTest
@testable import ActivityWeather

final class ActivitySuitabilityTests: XCTestCase {
    func testActivitiesAreCompleteAndStayInStableDisplayOrder() {
        XCTAssertEqual(
            Activity.allCases,
            [.skiing, .surfing, .outdoorSightseeing, .indoorSightseeing]
        )
    }

    func testDailyResultIsOneActivityOnOneDateAndDerivesLevelFromScore() throws {
        let date = try CivilDate(year: 2026, month: 9, day: 4)
        let day = try DailyForecast(
            date: date,
            weatherCode: 61,
            maximumTemperatureCelsius: 8,
            minimumTemperatureCelsius: 2,
            maximumApparentTemperatureCelsius: 6,
            precipitationMillimetres: 4,
            rainMillimetres: 4,
            snowfallCentimetres: 0,
            precipitationHours: 3,
            maximumWindSpeedKilometresPerHour: 12,
            maximumWindGustKilometresPerHour: 18,
            sunshineDurationSeconds: 1_000,
            daylightDurationSeconds: 40_000,
            maximumUVIndex: 2
        )
        let result = DailyActivitySuitability(
            day: day,
            activity: .skiing,
            score: try SuitabilityScore(0),
            reasons: [.rainOnSnow]
        )

        XCTAssertEqual(result.date, date)
        XCTAssertEqual(result.activity, .skiing)
        XCTAssertEqual(result.score.value, 0)
        XCTAssertEqual(result.level, .poor)
    }
}
