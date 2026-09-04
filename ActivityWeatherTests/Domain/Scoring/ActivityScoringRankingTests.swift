import XCTest
@testable import ActivityWeather

final class ActivityScoringRankingTests: XCTestCase {
    func testRanksSevenDaysForTheRequestedActivityOnly() throws {
        let week = try ScoringFixture.week()
        let scores = [40, 90, 40, 10, 90, 70, 55]
        let stub = FixedScoreScoring(
            scoresByDate: Dictionary(uniqueKeysWithValues: zip(week.days.map(\.date), scores))
        )

        let originalDays = week.days
        let ranked = stub.rankedSuitability(for: week, activity: .surfing)

        XCTAssertEqual(ranked.count, 7)
        XCTAssertTrue(ranked.allSatisfy { $0.activity == .surfing })
        XCTAssertEqual(ranked.map(\.score.value), [90, 90, 70, 55, 40, 40, 10])
        XCTAssertEqual(
            ranked.prefix(2).map(\.date),
            [week.days[1].date, week.days[4].date]
        )
        XCTAssertEqual(
            ranked.filter { $0.score.value == 40 }.map(\.date),
            [week.days[0].date, week.days[2].date]
        )
        XCTAssertEqual(week.days, originalDays)

        let skiing = stub.rankedSuitability(for: week, activity: .skiing)
        XCTAssertTrue(skiing.allSatisfy { $0.activity == .skiing })
        XCTAssertEqual(Set(skiing.map(\.activity)).count, 1)
    }

    func testEngineDoesNotRankActivitiesAgainstEachOther() throws {
        let week = try ScoringFixture.week()
        let engine = SuitabilityScoringEngine()

        let skiing = engine.rankedSuitability(for: week, activity: .skiing)
        let indoor = engine.rankedSuitability(for: week, activity: .indoorSightseeing)

        XCTAssertEqual(skiing.count, 7)
        XCTAssertEqual(indoor.count, 7)
        XCTAssertTrue(skiing.allSatisfy { $0.activity == .skiing })
        XCTAssertTrue(indoor.allSatisfy { $0.activity == .indoorSightseeing })
        XCTAssertNotEqual(skiing.map(\.score.value), indoor.map(\.score.value))
    }
}

private struct FixedScoreScoring: ActivityScoring {
    let scoresByDate: [CivilDate: Int]

    func suitability(for forecast: DailyForecast, activity: Activity) -> DailyActivitySuitability {
        DailyActivitySuitability(
            day: forecast,
            activity: activity,
            score: SuitabilityScore(clamping: scoresByDate[forecast.date] ?? 0),
            reasons: []
        )
    }
}
