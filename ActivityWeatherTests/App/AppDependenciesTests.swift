import Foundation
import XCTest
@testable import ActivityWeather

final class AppDependenciesTests: XCTestCase {
    func testLiveSearchUsesOpenMeteoLocationRepositoryWithoutALiveRequest() async throws {
        let dto = try GeocodingFixture.decodeResponse(named: "geocoding_success_ambiguous")
        let client = StubAPIClient(behaviour: .success(dto))
        let dependencies = AppDependencies.live(client: client)

        let locations = try await dependencies.searchLocations.execute(query: "  Berlin  ")
        let endpoints = await client.endpoints
        let endpoint = try XCTUnwrap(endpoints.first)
        let components = try XCTUnwrap(URLComponents(url: try endpoint.url(), resolvingAgainstBaseURL: false))

        XCTAssertEqual(locations.map(\.id), [2950159, 5083330])
        XCTAssertEqual(endpoints.count, 1)
        XCTAssertEqual(endpoint.host, "geocoding-api.open-meteo.com")
        XCTAssertEqual(endpoint.path, "/v1/search")
        XCTAssertEqual(queryValue("name", in: components), "Berlin")
    }

    func testLiveSearchLeavesTheRepositoryShortCircuitInPlace() async throws {
        let client = StubAPIClient(behaviour: .api(.transport(URLError(.notConnectedToInternet))))
        let dependencies = AppDependencies.live(client: client)

        let locations = try await dependencies.searchLocations.execute(query: " \n ")
        let endpoints = await client.endpoints

        XCTAssertEqual(locations, [])
        XCTAssertTrue(endpoints.isEmpty)
    }

    private func queryValue(_ name: String, in components: URLComponents) -> String? {
        components.queryItems?.first(where: { $0.name == name })?.value
    }
}
