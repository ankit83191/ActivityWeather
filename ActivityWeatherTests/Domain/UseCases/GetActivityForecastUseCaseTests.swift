import XCTest
@testable import ActivityWeather

final class GetActivityForecastUseCaseTests: XCTestCase {
    func testFetchesOnceAndScoresEveryDayForEveryActivity() async throws {
        let location = try UseCaseFixture.location()
        let week = try ScoringFixture.week()
        let forecastSpy = ForecastRepositorySpy(result: .success(week))
        let scoring = ScoringSpy()
        let useCase = GetActivityForecastUseCase(
            forecastRepository: forecastSpy,
            scoring: scoring
        )

        let result = try await useCase.execute(location: location)
        let forecastCalls = await forecastSpy.locations

        XCTAssertEqual(forecastCalls, [location])
        XCTAssertEqual(scoring.calls.count, 28)
        XCTAssertEqual(result.forecast, week)
        XCTAssertEqual(result.location, location)
        XCTAssertEqual(result.rankings.map(\.activity), Activity.allCases)
        XCTAssertEqual(scoring.calls.map(\.activity), Self.expectedScoringActivities)
        XCTAssertEqual(Set(result.rankings.map(\.activity)).count, 4)

        for ranking in result.rankings {
            XCTAssertEqual(ranking.days.count, 7)
            XCTAssertTrue(ranking.days.allSatisfy { $0.activity == ranking.activity })
            XCTAssertEqual(Set(ranking.days.map(\.date)), Set(week.days.map(\.date)))
            XCTAssertEqual(ranking.days.map(\.date), week.days.map(\.date))
            XCTAssertEqual(ranking.days.map(\.score.value), Array(repeating: 50, count: 7))
        }
    }

    func testDoesNotScoreWhenForecastRetrievalFails() async throws {
        let location = try UseCaseFixture.location()
        let forecastSpy = ForecastRepositorySpy(result: .failure(DomainError.missingCriticalData))
        let scoring = ScoringSpy()
        let useCase = GetActivityForecastUseCase(
            forecastRepository: forecastSpy,
            scoring: scoring
        )

        do {
            _ = try await useCase.execute(location: location)
            XCTFail("Expected missingCriticalData")
        } catch DomainError.missingCriticalData {
            let forecastCalls = await forecastSpy.locations
            XCTAssertEqual(forecastCalls, [location])
            XCTAssertEqual(scoring.calls.count, 0)
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    private static var expectedScoringActivities: [Activity] {
        Activity.allCases.flatMap { activity in
            Array(repeating: activity, count: 7)
        }
    }
}
