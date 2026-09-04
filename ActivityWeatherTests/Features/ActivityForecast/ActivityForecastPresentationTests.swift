import Foundation
import XCTest
@testable import ActivityWeather

final class ActivityForecastPresentationTests: XCTestCase {
    func testRankedDaysJoinByCivilDateInsteadOfArrayPosition() throws {
        let week = try ScoringFixture.week()
        let ranking = ActivityDayRanking(
            activity: .skiing,
            days: week.days.reversed().enumerated().map { offset, day in
                DailyActivitySuitability(
                    day: day,
                    activity: .skiing,
                    score: SuitabilityScore(clamping: 100 - offset),
                    reasons: []
                )
            }
        )
        let result = LocationActivityForecast(
            location: try UseCaseFixture.location(),
            forecast: week,
            rankings: [ranking]
        )

        let rows = try XCTUnwrap(
            ActivityForecastPresentation.rankedDays(
                in: result,
                for: .skiing
            )
        )

        XCTAssertEqual(rows.map(\.rank), Array(1...7))
        XCTAssertEqual(rows.map(\.suitability.date), ranking.days.map(\.date))
        XCTAssertEqual(rows.map(\.forecast.date), ranking.days.map(\.date))
    }

    func testMissingForecastDateAssociationFailsSafely() throws {
        let week = try ScoringFixture.week()
        let unknownDay = try ScoringFixture.day(
            year: 2026,
            month: 9,
            day: 20
        )
        var suitability = week.days.map {
            DailyActivitySuitability(
                day: $0,
                activity: .skiing,
                score: SuitabilityScore(clamping: 50),
                reasons: []
            )
        }
        suitability[6] = DailyActivitySuitability(
            day: unknownDay,
            activity: .skiing,
            score: SuitabilityScore(clamping: 50),
            reasons: []
        )
        let result = LocationActivityForecast(
            location: try UseCaseFixture.location(),
            forecast: week,
            rankings: [
                ActivityDayRanking(activity: .skiing, days: suitability)
            ]
        )

        XCTAssertNil(
            ActivityForecastPresentation.rankedDays(
                in: result,
                for: .skiing
            )
        )
    }

    func testDateFormattingUsesForecastTimezoneAroundDSTBoundary() throws {
        let deviceTimeZone = TimeZone.current.identifier
        let forecastTimeZone: String
        let civilDate: CivilDate
        let expected: String

        if deviceTimeZone == "Europe/London" {
            forecastTimeZone = "America/New_York"
            civilDate = try CivilDate(year: 2026, month: 3, day: 8)
            expected = "Sunday, March 8"
        } else {
            forecastTimeZone = "Europe/London"
            civilDate = try CivilDate(year: 2026, month: 3, day: 29)
            expected = "Sunday, March 29"
        }

        XCTAssertNotEqual(deviceTimeZone, forecastTimeZone)
        XCTAssertEqual(
            ForecastDateFormatting.string(
                for: civilDate,
                timeZoneIdentifier: forecastTimeZone,
                locale: Locale(identifier: "en_US")
            ),
            expected
        )
    }

    func testDateFormattingUsesAsiaKolkataWithoutShiftingTheCivilDay() throws {
        XCTAssertEqual(
            ForecastDateFormatting.string(
                for: try CivilDate(year: 2026, month: 9, day: 4),
                timeZoneIdentifier: "Asia/Kolkata",
                locale: Locale(identifier: "en_US")
            ),
            "Friday, September 4"
        )
        XCTAssertNil(
            ForecastDateFormatting.string(
                for: try CivilDate(year: 2026, month: 9, day: 4),
                timeZoneIdentifier: "Invalid/Timezone"
            )
        )
    }

    func testReasonCopyNeverUsesRawIdentifier() {
        XCTAssertEqual(
            SuitabilityReason.criticalThunderstorm.presentationText,
            "Thunderstorm makes outdoor activity unsafe"
        )
        XCTAssertNotEqual(
            SuitabilityReason.windProxy.presentationText,
            SuitabilityReason.windProxy.rawValue
        )
    }
}
