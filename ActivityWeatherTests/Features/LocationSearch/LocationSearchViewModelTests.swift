import XCTest
@testable import ActivityWeather

@MainActor
final class LocationSearchViewModelTests: XCTestCase {
    func testEmptyQueryStaysIdleWithoutSearching() async {
        let harness = makeHarness()

        harness.viewModel.updateQuery(" \n ")
        harness.viewModel.submit()
        await drainTasks()

        XCTAssertEqual(harness.viewModel.status, .idle)
        XCTAssertEqual(harness.viewModel.helperText, "Search for a city")
        let queries = await harness.repository.queries
        XCTAssertEqual(queries, [])
    }

    func testOneCharacterQueryStaysIdleWithHelperWithoutSearching() async {
        let harness = makeHarness()

        harness.viewModel.updateQuery(" A ")
        harness.viewModel.submit()
        await drainTasks()

        XCTAssertEqual(harness.viewModel.status, .idle)
        XCTAssertEqual(harness.viewModel.helperText, "Enter at least 2 characters")
        let queries = await harness.repository.queries
        XCTAssertEqual(queries, [])
    }

    func testShortQueryCancelsPendingDebounce() async {
        let harness = makeHarness()

        harness.viewModel.updateQuery("Paris")
        await waitUntil { await harness.sleeper.pendingCount == 1 }
        harness.viewModel.updateQuery("P")
        await waitUntil { await harness.sleeper.cancelledCount == 1 }

        XCTAssertEqual(harness.viewModel.status, .idle)
        let queries = await harness.repository.queries
        XCTAssertEqual(queries, [])
    }

    func testSearchStartsOnlyAfterDebounceRelease() async throws {
        let harness = makeHarness()

        harness.viewModel.updateQuery("  Paris  ")
        await waitUntil { await harness.sleeper.pendingCount == 1 }

        let queriesBeforeRelease = await harness.repository.queries
        XCTAssertEqual(queriesBeforeRelease, [])
        XCTAssertEqual(harness.viewModel.status, .idle)
        await harness.sleeper.releaseNext()
        await waitUntil { await harness.repository.queries == ["Paris"] }

        let queriesAfterRelease = await harness.repository.queries
        XCTAssertEqual(queriesAfterRelease, ["Paris"])
        XCTAssertEqual(harness.viewModel.status, .loading)
    }

    func testSubmitBypassesDebounce() async {
        let harness = makeHarness()

        harness.viewModel.updateQuery("Paris")
        await waitUntil { await harness.sleeper.pendingCount == 1 }
        harness.viewModel.submit()
        await waitUntil { await harness.repository.queries == ["Paris"] }

        XCTAssertEqual(harness.viewModel.status, .loading)
        let cancelledCount = await harness.sleeper.cancelledCount
        XCTAssertEqual(cancelledCount, 1)
    }

    func testSecondQueryCancelsFirstDebounce() async {
        let harness = makeHarness()

        harness.viewModel.updateQuery("Paris")
        await waitUntil { await harness.sleeper.pendingCount == 1 }
        harness.viewModel.updateQuery("London")
        await waitUntil {
            let cancelled = await harness.sleeper.cancelledCount
            let pending = await harness.sleeper.pendingCount
            return cancelled == 1 && pending == 1
        }
        await harness.sleeper.releaseNext()
        await waitUntil { await harness.repository.queries == ["London"] }

        let queries = await harness.repository.queries
        XCTAssertEqual(queries, ["London"])
    }

    func testEditingAfterResultsKeepsResultsDuringDebounce() async throws {
        let harness = makeHarness()
        let paris = try location(id: 1, name: "Paris")

        harness.viewModel.updateQuery("Paris")
        harness.viewModel.submit()
        await waitUntil { await harness.repository.queries == ["Paris"] }
        await harness.repository.complete(query: "Paris", with: .success([paris]))
        await waitUntil { harness.viewModel.status == .results([paris]) }

        harness.viewModel.updateQuery("London")

        XCTAssertEqual(harness.viewModel.status, .results([paris]))
        let queries = await harness.repository.queries
        XCTAssertEqual(queries, ["Paris"])

        await harness.sleeper.releaseNext()
        await waitUntil {
            await harness.repository.queries == ["Paris", "London"]
        }
        XCTAssertEqual(harness.viewModel.status, .loading)
    }

    func testCancellationDoesNotBecomeFailure() async {
        let harness = makeHarness()

        harness.viewModel.updateQuery("Paris")
        harness.viewModel.submit()
        await waitUntil { await harness.repository.queries == ["Paris"] }
        harness.viewModel.updateQuery("A")
        await harness.repository.complete(
            query: "Paris",
            with: .failure(TestFailure.expected)
        )
        await drainTasks()

        XCTAssertEqual(harness.viewModel.status, .idle)
        XCTAssertNil(harness.viewModel.failure)
    }

    func testStaleResultCannotReplaceNewerQuery() async throws {
        let harness = makeHarness()
        let paris = try location(id: 1, name: "Paris")
        let london = try location(id: 2, name: "London")

        harness.viewModel.updateQuery("Paris")
        harness.viewModel.submit()
        await waitUntil { await harness.repository.queries == ["Paris"] }
        harness.viewModel.updateQuery("London")
        harness.viewModel.submit()
        await waitUntil {
            await harness.repository.queries == ["Paris", "London"]
        }

        await harness.repository.complete(query: "Paris", with: .success([paris]))
        await drainTasks()
        XCTAssertEqual(harness.viewModel.status, .loading)

        await harness.repository.complete(query: "London", with: .success([london]))
        await waitUntil {
            harness.viewModel.status == .results([london])
        }
        XCTAssertEqual(harness.viewModel.status, .results([london]))
    }

    func testStaleErrorCannotReplaceNewerQuery() async throws {
        let harness = makeHarness()
        let london = try location(id: 2, name: "London")

        harness.viewModel.updateQuery("Paris")
        harness.viewModel.submit()
        await waitUntil { await harness.repository.queries == ["Paris"] }
        harness.viewModel.updateQuery("London")
        harness.viewModel.submit()
        await waitUntil {
            await harness.repository.queries == ["Paris", "London"]
        }

        await harness.repository.complete(
            query: "Paris",
            with: .failure(TestFailure.expected)
        )
        await drainTasks()
        XCTAssertEqual(harness.viewModel.status, .loading)

        await harness.repository.complete(query: "London", with: .success([london]))
        await waitUntil {
            harness.viewModel.status == .results([london])
        }
        XCTAssertEqual(harness.viewModel.status, .results([london]))
    }

    func testSettingSameQueryDoesNotDuplicateWork() async {
        let harness = makeHarness()

        harness.viewModel.updateQuery("Paris")
        await waitUntil { await harness.sleeper.pendingCount == 1 }
        harness.viewModel.updateQuery("Paris")
        await drainTasks()

        let sleepCount = await harness.sleeper.totalSleepCount
        XCTAssertEqual(sleepCount, 1)
        await harness.sleeper.releaseNext()
        await waitUntil { await harness.repository.queries == ["Paris"] }
        let queries = await harness.repository.queries
        XCTAssertEqual(queries, ["Paris"])
    }

    func testEmptyResponseBecomesEmptyState() async {
        let harness = makeHarness()

        harness.viewModel.updateQuery("Nowhere")
        harness.viewModel.submit()
        await waitUntil { await harness.repository.queries == ["Nowhere"] }
        await harness.repository.complete(query: "Nowhere", with: .success([]))
        await waitUntil { harness.viewModel.status == .empty }

        XCTAssertEqual(harness.viewModel.status, .empty)
    }

    func testErrorBecomesGenericFailure() async {
        let harness = makeHarness()

        harness.viewModel.updateQuery("Paris")
        harness.viewModel.submit()
        await waitUntil { await harness.repository.queries == ["Paris"] }
        await harness.repository.complete(
            query: "Paris",
            with: .failure(TestFailure.expected)
        )
        await waitUntil { harness.viewModel.status == .failure }

        XCTAssertEqual(harness.viewModel.status, .failure)
        XCTAssertEqual(harness.viewModel.failure, .generic)
    }

    func testMapsEveryRepositoryFailureToPresentationCategory() async {
        let cases: [(RepositoryFailure, UserFacingFailure)] = [
            (.offline, .connection),
            (.serviceUnavailable, .service),
            (.invalidData, .invalidData),
            (.unknown, .generic)
        ]

        for (repositoryFailure, expected) in cases {
            let harness = makeHarness()
            harness.viewModel.updateQuery("Paris")
            harness.viewModel.submit()
            await waitUntil { await harness.repository.queries == ["Paris"] }
            await harness.repository.complete(
                query: "Paris",
                with: .failure(repositoryFailure)
            )
            await waitUntil { harness.viewModel.status == .failure }

            XCTAssertEqual(harness.viewModel.failure, expected)
        }
    }

    func testRetryIsImmediateAndUsesFailedNormalizedQuery() async {
        let harness = makeHarness()

        harness.viewModel.updateQuery("  Paris \n")
        harness.viewModel.submit()
        await waitUntil { await harness.repository.queries == ["Paris"] }
        await harness.repository.complete(
            query: "Paris",
            with: .failure(TestFailure.expected)
        )
        await waitUntil { harness.viewModel.status == .failure }
        let sleepCountBeforeRetry = await harness.sleeper.totalSleepCount

        harness.viewModel.retry()
        await waitUntil {
            await harness.repository.queries == ["Paris", "Paris"]
        }

        let sleepCountAfterRetry = await harness.sleeper.totalSleepCount
        XCTAssertEqual(sleepCountAfterRetry, sleepCountBeforeRetry)
        XCTAssertEqual(harness.viewModel.status, .loading)
        XCTAssertNil(harness.viewModel.failure)
    }

    func testSelectingResultAndEditingQueryUpdatesSelection() async throws {
        let harness = makeHarness()
        let paris = try location(id: 1, name: "Paris")

        harness.viewModel.select(paris)
        XCTAssertEqual(harness.viewModel.selectedLocation, paris)

        harness.viewModel.updateQuery("London")
        XCTAssertNil(harness.viewModel.selectedLocation)
    }

    func testResultOrderingIsPreserved() async throws {
        let harness = makeHarness()
        let second = try location(id: 2, name: "Paris, Texas")
        let first = try location(id: 1, name: "Paris")

        harness.viewModel.updateQuery("Paris")
        harness.viewModel.submit()
        await waitUntil { await harness.repository.queries == ["Paris"] }
        await harness.repository.complete(
            query: "Paris",
            with: .success([second, first])
        )
        await waitUntil {
            harness.viewModel.status == .results([second, first])
        }

        XCTAssertEqual(harness.viewModel.status, .results([second, first]))
    }

    private func makeHarness() -> Harness {
        let repository = ControlledLocationRepository()
        let sleeper = ManualSearchSleeper()
        let viewModel = LocationSearchViewModel(
            searchLocations: SearchLocationsUseCase(repository: repository),
            sleeper: sleeper
        )
        return Harness(
            viewModel: viewModel,
            repository: repository,
            sleeper: sleeper
        )
    }

    private func location(id: Int, name: String) throws -> Location {
        Location(
            id: id,
            displayName: name,
            region: "Region",
            country: "Country",
            coordinate: try Coordinate(latitude: 48.8, longitude: 2.3),
            elevationMetres: nil,
            geocodingTimeZoneIdentifier: nil
        )
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

private struct Harness {
    let viewModel: LocationSearchViewModel
    let repository: ControlledLocationRepository
    let sleeper: ManualSearchSleeper
}

private enum TestFailure: Error {
    case expected
}

private actor ManualSearchSleeper: SearchSleeping {
    private struct Waiter {
        let id: Int
        let continuation: CheckedContinuation<Void, Error>
    }

    private var waiters: [Waiter] = []
    private var nextID = 0
    private(set) var cancelledCount = 0
    private(set) var totalSleepCount = 0

    var pendingCount: Int {
        waiters.count
    }

    func sleep() async throws {
        let id = nextID
        nextID += 1
        totalSleepCount += 1

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Void, Error>) in
                if Task.isCancelled {
                    continuation.resume(throwing: CancellationError())
                } else {
                    waiters.append(Waiter(id: id, continuation: continuation))
                }
            }
        } onCancel: {
            Task {
                await self.cancel(id: id)
            }
        }
    }

    func releaseNext() {
        guard !waiters.isEmpty else {
            return
        }
        waiters.removeFirst().continuation.resume()
    }

    private func cancel(id: Int) {
        guard let index = waiters.firstIndex(where: { $0.id == id }) else {
            return
        }
        cancelledCount += 1
        waiters.remove(at: index).continuation.resume(throwing: CancellationError())
    }
}

private actor ControlledLocationRepository: LocationRepository {
    private struct Request {
        let query: String
        let continuation: CheckedContinuation<[Location], Error>
    }

    private(set) var queries: [String] = []
    private var requests: [Request] = []

    func locations(matching query: String) async throws -> [Location] {
        queries.append(query)
        return try await withCheckedThrowingContinuation { continuation in
            requests.append(Request(query: query, continuation: continuation))
        }
    }

    func complete(query: String, with result: Result<[Location], Error>) {
        guard let index = requests.firstIndex(where: { $0.query == query }) else {
            return
        }
        requests.remove(at: index).continuation.resume(with: result)
    }
}
