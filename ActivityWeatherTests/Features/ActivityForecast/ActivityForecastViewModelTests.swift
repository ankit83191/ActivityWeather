import XCTest
@testable import ActivityWeather

@MainActor
final class ActivityForecastViewModelTests: XCTestCase {
    func testInitialLoadStartsExactlyOneRequest() async throws {
        let harness = try makeHarness()

        harness.viewModel.load()
        harness.viewModel.load()
        await waitUntil { await harness.repository.requestCount == 1 }

        XCTAssertEqual(harness.viewModel.status, .loading)
        let requests = await harness.repository.locations
        XCTAssertEqual(requests, [harness.location])
    }

    func testSuccessContainsFourSevenDayRankingsInDisplayOrder() async throws {
        let harness = try makeHarness()

        harness.viewModel.load()
        await waitUntil { await harness.repository.requestCount == 1 }
        await harness.repository.complete(0, with: .success(harness.week))
        await waitUntil { harness.viewModel.loadedForecast != nil }

        let result = try XCTUnwrap(harness.viewModel.loadedForecast)
        XCTAssertEqual(result.location, harness.location)
        XCTAssertEqual(result.forecast, harness.week)
        XCTAssertEqual(result.rankings.map(\.activity), Activity.allCases)
        XCTAssertEqual(result.rankings.count, 4)
        XCTAssertTrue(result.rankings.allSatisfy { $0.days.count == 7 })
        for ranking in result.rankings {
            XCTAssertTrue(ranking.days.allSatisfy { $0.activity == ranking.activity })
        }
    }

    func testRepeatedLoadAfterSuccessDoesNotRefetchOrRescore() async throws {
        let harness = try makeHarness()
        try await completeInitialLoad(harness)
        let scoreCallsBefore = harness.scoring.calls.count

        harness.viewModel.load()
        await drainTasks()

        let requestCount = await harness.repository.requestCount
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(harness.scoring.calls.count, scoreCallsBefore)
    }

    func testDefaultsToSkiingAndSwitchesWithoutRefetchOrRescore() async throws {
        let harness = try makeHarness()
        try await completeInitialLoad(harness)

        XCTAssertEqual(harness.viewModel.selectedActivity, .skiing)
        XCTAssertEqual(harness.viewModel.selectedRanking?.activity, .skiing)
        let scoreCallsBefore = harness.scoring.calls.count

        harness.viewModel.selectActivity(.surfing)

        XCTAssertEqual(harness.viewModel.selectedActivity, .surfing)
        XCTAssertEqual(harness.viewModel.selectedRanking?.activity, .surfing)
        let requestCount = await harness.repository.requestCount
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(harness.scoring.calls.count, scoreCallsBefore)
    }

    func testActivitySelectionSurvivesFailureRetryAndLoadedRendering() async throws {
        let harness = try makeHarness()
        harness.viewModel.selectActivity(.surfing)

        harness.viewModel.load()
        await waitUntil { await harness.repository.requestCount == 1 }
        await harness.repository.complete(0, with: .failure(TestForecastFailure.expected))
        await waitUntil { harness.viewModel.status == .failure }
        XCTAssertEqual(harness.viewModel.failure, .generic)

        harness.viewModel.retry()
        await waitUntil { await harness.repository.requestCount == 2 }
        await harness.repository.complete(1, with: .success(harness.week))
        await waitUntil { harness.viewModel.loadedForecast != nil }

        XCTAssertEqual(harness.viewModel.selectedActivity, .surfing)
        XCTAssertEqual(harness.viewModel.selectedRanking?.activity, .surfing)
    }

    func testBestDayIsFirstDomainRankedDayAndEqualScoresKeepDateOrder() async throws {
        let harness = try makeHarness()
        try await completeInitialLoad(harness)
        let ranking = try XCTUnwrap(harness.viewModel.selectedRanking)

        XCTAssertEqual(harness.viewModel.bestDay, ranking.days.first)
        XCTAssertEqual(ranking.days.map(\.date), harness.week.days.map(\.date))
    }

    func testFailureAndRetryEachMakeOneRequest() async throws {
        let harness = try makeHarness()

        harness.viewModel.load()
        await waitUntil { await harness.repository.requestCount == 1 }
        await harness.repository.complete(0, with: .failure(TestForecastFailure.expected))
        await waitUntil { harness.viewModel.status == .failure }

        harness.viewModel.retry()
        harness.viewModel.retry()
        await waitUntil { await harness.repository.requestCount == 2 }

        XCTAssertEqual(harness.viewModel.status, .loading)
        XCTAssertNil(harness.viewModel.failure)
        let requestCount = await harness.repository.requestCount
        XCTAssertEqual(requestCount, 2)
    }

    func testMapsEveryRepositoryFailureToPresentationCategory() async throws {
        let cases: [(RepositoryFailure, UserFacingFailure)] = [
            (.offline, .connection),
            (.serviceUnavailable, .service),
            (.invalidData, .invalidData),
            (.unknown, .generic)
        ]

        for (repositoryFailure, expected) in cases {
            let harness = try makeHarness()
            harness.viewModel.load()
            await waitUntil { await harness.repository.requestCount == 1 }
            await harness.repository.complete(
                0,
                with: .failure(repositoryFailure)
            )
            await waitUntil { harness.viewModel.status == .failure }

            XCTAssertEqual(harness.viewModel.failure, expected)
        }
    }

    func testCancellationIsNotFailureAndCancelledLoadCanReload() async throws {
        let harness = try makeHarness()

        harness.viewModel.load()
        await waitUntil { await harness.repository.requestCount == 1 }
        harness.viewModel.cancel()

        XCTAssertEqual(harness.viewModel.status, .idle)
        XCTAssertNil(harness.viewModel.failure)

        harness.viewModel.load()
        await waitUntil { await harness.repository.requestCount == 2 }
        await harness.repository.complete(0, with: .failure(TestForecastFailure.expected))
        await drainTasks()
        XCTAssertEqual(harness.viewModel.status, .loading)

        await harness.repository.complete(1, with: .success(harness.week))
        await waitUntil { harness.viewModel.loadedForecast != nil }
        XCTAssertNotNil(harness.viewModel.loadedForecast)
    }

    func testStaleSuccessCannotOverwriteNewerFailure() async throws {
        let harness = try makeHarness()

        harness.viewModel.load()
        await waitUntil { await harness.repository.requestCount == 1 }
        harness.viewModel.cancel()
        harness.viewModel.load()
        await waitUntil { await harness.repository.requestCount == 2 }

        await harness.repository.complete(1, with: .failure(TestForecastFailure.expected))
        await waitUntil { harness.viewModel.status == .failure }
        await harness.repository.complete(0, with: .success(harness.week))
        await drainTasks()

        XCTAssertEqual(harness.viewModel.status, .failure)
    }

    func testStaleFailureCannotOverwriteNewerSuccess() async throws {
        let harness = try makeHarness()

        harness.viewModel.load()
        await waitUntil { await harness.repository.requestCount == 1 }
        harness.viewModel.cancel()
        harness.viewModel.load()
        await waitUntil { await harness.repository.requestCount == 2 }

        await harness.repository.complete(1, with: .success(harness.week))
        await waitUntil { harness.viewModel.loadedForecast != nil }
        let loaded = harness.viewModel.loadedForecast
        await harness.repository.complete(0, with: .failure(TestForecastFailure.expected))
        await drainTasks()

        XCTAssertEqual(harness.viewModel.loadedForecast, loaded)
    }

    private func makeHarness() throws -> ForecastHarness {
        let location = try UseCaseFixture.location()
        let week = try ScoringFixture.week()
        let repository = ControlledForecastRepository()
        let scoring = ScoringSpy()
        let viewModel = ActivityForecastViewModel(
            location: location,
            getActivityForecast: GetActivityForecastUseCase(
                forecastRepository: repository,
                scoring: scoring
            )
        )
        return ForecastHarness(
            viewModel: viewModel,
            repository: repository,
            scoring: scoring,
            location: location,
            week: week
        )
    }

    private func completeInitialLoad(_ harness: ForecastHarness) async throws {
        harness.viewModel.load()
        await waitUntil { await harness.repository.requestCount == 1 }
        await harness.repository.complete(0, with: .success(harness.week))
        await waitUntil { harness.viewModel.loadedForecast != nil }
        _ = try XCTUnwrap(harness.viewModel.loadedForecast)
    }

    private func waitUntil(
        _ condition: @escaping @MainActor () async -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<1_000 {
            if await condition() {
                return
            }
            await Task.yield()
        }
        XCTFail("Condition was not reached", file: file, line: line)
    }

    private func drainTasks() async {
        for _ in 0..<10 {
            await Task.yield()
        }
    }
}

private struct ForecastHarness {
    let viewModel: ActivityForecastViewModel
    let repository: ControlledForecastRepository
    let scoring: ScoringSpy
    let location: Location
    let week: WeeklyForecast
}

private enum TestForecastFailure: Error {
    case expected
}

private actor ControlledForecastRepository: ForecastRepository {
    private var continuations: [
        Int: CheckedContinuation<WeeklyForecast, Error>
    ] = [:]
    private(set) var locations: [Location] = []

    var requestCount: Int {
        locations.count
    }

    func forecast(for location: Location) async throws -> WeeklyForecast {
        let request = locations.count
        locations.append(location)
        return try await withCheckedThrowingContinuation { continuation in
            continuations[request] = continuation
        }
    }

    func complete(
        _ request: Int,
        with result: Result<WeeklyForecast, Error>
    ) {
        continuations.removeValue(forKey: request)?.resume(with: result)
    }
}
