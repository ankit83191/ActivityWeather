import XCTest
@testable import ActivityWeather

final class OpenMeteoLocationRepositoryTests: XCTestCase {
    func testShortOrBlankQueriesReturnEmptyWithoutCallingTheClient() async throws {
        let client = StubAPIClient(behaviour: .api(.transport(URLError(.notConnectedToInternet))))
        let repository = OpenMeteoLocationRepository(client: client)

        let empty = try await repository.locations(matching: "  ")
        let oneCharacter = try await repository.locations(matching: " B ")
        let invocations = await client.endpoints

        XCTAssertEqual(empty, [])
        XCTAssertEqual(oneCharacter, [])
        XCTAssertTrue(invocations.isEmpty)
    }

    func testTrimsQueryAndRequestsGeocodingEndpoint() async throws {
        let dto = try GeocodingFixture.decodeResponse(named: "geocoding_success_ambiguous")
        let client = StubAPIClient(behaviour: .success(dto))
        let repository = OpenMeteoLocationRepository(client: client)

        let locations = try await repository.locations(matching: "  Berlin  ")
        let endpoints = await client.endpoints
        let endpoint = try XCTUnwrap(endpoints.first)
        let components = try XCTUnwrap(URLComponents(url: try endpoint.url(), resolvingAgainstBaseURL: false))

        XCTAssertEqual(locations.map(\.id), [2950159, 5083330])
        XCTAssertEqual(queryValue("name", in: components), "Berlin")
        XCTAssertEqual(queryValue("count", in: components), "10")
        XCTAssertEqual(queryValue("language", in: components), "en")
        XCTAssertEqual(queryValue("format", in: components), "json")
    }

    func testMapsConnectivityTransportErrorToOffline() async {
        for code: URLError.Code in [
            .notConnectedToInternet,
            .networkConnectionLost,
            .backgroundSessionWasDisconnected
        ] {
            let client = StubAPIClient(
                behaviour: .api(.transport(URLError(code)))
            )
            let repository = OpenMeteoLocationRepository(client: client)

            do {
                _ = try await repository.locations(matching: "Berlin")
                XCTFail("Expected offline for \(code)")
            } catch let error as RepositoryFailure {
                XCTAssertEqual(error, .offline)
            } catch {
                XCTFail("Unexpected \(error)")
            }
        }
    }

    func testMapsServiceStatusesToServiceUnavailable() async {
        for status in [429, 500, 503] {
            let client = StubAPIClient(behaviour: .api(.httpStatus(status)))
            let repository = OpenMeteoLocationRepository(client: client)

            do {
                _ = try await repository.locations(matching: "Berlin")
                XCTFail("Expected service unavailable for \(status)")
            } catch let error as RepositoryFailure {
                XCTAssertEqual(error, .serviceUnavailable)
            } catch {
                XCTFail("Unexpected \(error)")
            }
        }
    }

    func testMapsInvalidInfrastructureResponsesToInvalidData() async {
        for apiError: APIError in [
            .decoding,
            .nonHTTPResponse,
            .invalidRequest
        ] {
            let client = StubAPIClient(behaviour: .api(apiError))
            let repository = OpenMeteoLocationRepository(client: client)

            do {
                _ = try await repository.locations(matching: "Berlin")
                XCTFail("Expected invalid data for \(apiError)")
            } catch let error as RepositoryFailure {
                XCTAssertEqual(error, .invalidData)
            } catch {
                XCTFail("Unexpected \(error)")
            }
        }
    }

    func testMapsUnrecognizedHTTPStatusToUnknown() async {
        let client = StubAPIClient(behaviour: .api(.httpStatus(400)))
        let repository = OpenMeteoLocationRepository(client: client)

        do {
            _ = try await repository.locations(matching: "Berlin")
            XCTFail("Expected unknown")
        } catch let error as RepositoryFailure {
            XCTAssertEqual(error, .unknown)
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testPropagatesCancellation() async {
        let client = StubAPIClient(behaviour: .cancellation)
        let repository = OpenMeteoLocationRepository(client: client)

        do {
            _ = try await repository.locations(matching: "Berlin")
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected.
        } catch let error as APIError {
            XCTFail("Cancellation became \(error)")
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testPropagatesCancelledURLError() async {
        let client = StubAPIClient(behaviour: .url(URLError(.cancelled)))
        let repository = OpenMeteoLocationRepository(client: client)

        do {
            _ = try await repository.locations(matching: "Berlin")
            XCTFail("Expected cancellation")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .cancelled)
        } catch is CancellationError {
            // Expected.
        } catch let error as APIError {
            XCTFail("Cancelled URLError became \(error)")
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testMissingResultsIsEmptySuccess() async throws {
        let dto = try GeocodingFixture.decodeResponse(named: "geocoding_missing_results")
        let client = StubAPIClient(behaviour: .success(dto))
        let repository = OpenMeteoLocationRepository(client: client)

        let locations = try await repository.locations(matching: "Berlin")
        XCTAssertEqual(locations, [])
    }

    func testAllInvalidRecordsMapToInvalidData() async throws {
        let dto = try GeocodingFixture.decodeResponse(named: "geocoding_all_invalid")
        let client = StubAPIClient(behaviour: .success(dto))
        let repository = OpenMeteoLocationRepository(client: client)

        do {
            _ = try await repository.locations(matching: "Berlin")
            XCTFail("Expected invalid data")
        } catch let error as RepositoryFailure {
            XCTAssertEqual(error, .invalidData)
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    private func queryValue(_ name: String, in components: URLComponents) -> String? {
        components.queryItems?.first(where: { $0.name == name })?.value
    }
}
