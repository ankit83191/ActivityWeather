import XCTest
@testable import ActivityWeather

final class SearchLocationsUseCaseTests: XCTestCase {
    func testTrimsQueryAndDelegatesToTheRepositoryOnce() async throws {
        let paris = try UseCaseFixture.location(id: 1, name: "Paris")
        let spy = LocationRepositorySpy(result: .success([paris]))
        let useCase = SearchLocationsUseCase(repository: spy)

        let locations = try await useCase.execute(query: "  Paris  \n")
        let queries = await spy.queries

        XCTAssertEqual(queries, ["Paris"])
        XCTAssertEqual(locations, [paris])
    }

    func testWhitespaceOnlyInputIsDelegatedAsEmptyString() async throws {
        let spy = LocationRepositorySpy(result: .success([]))
        let useCase = SearchLocationsUseCase(repository: spy)

        let locations = try await useCase.execute(query: " \n\t ")
        let queries = await spy.queries

        XCTAssertEqual(queries, [""])
        XCTAssertEqual(locations, [])
    }

    func testReturnsRepositoryResultsUnchanged() async throws {
        let first = try UseCaseFixture.location(id: 10, name: "Berlin")
        let second = try UseCaseFixture.location(id: 20, name: "Berlina")
        let spy = LocationRepositorySpy(result: .success([first, second]))
        let useCase = SearchLocationsUseCase(repository: spy)

        let locations = try await useCase.execute(query: "Berlin")

        XCTAssertEqual(locations.map(\.id), [10, 20])
        XCTAssertEqual(locations.map(\.displayName), ["Berlin", "Berlina"])
    }

    func testPropagatesRepositoryErrorsUnchanged() async {
        let spy = LocationRepositorySpy(result: .failure(APIError.decoding))
        let useCase = SearchLocationsUseCase(repository: spy)

        do {
            _ = try await useCase.execute(query: "  Berlin  ")
            XCTFail("Expected decoding")
        } catch let error as APIError {
            XCTAssertEqual(error, .decoding)
            let queries = await spy.queries
            XCTAssertEqual(queries, ["Berlin"])
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }
}
