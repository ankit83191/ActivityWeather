import XCTest
@testable import ActivityWeather

final class APIEndpointTests: XCTestCase {
    func testBuildsHTTPSURLWithPathAndQueryItems() throws {
        let endpoint = APIEndpoint(
            scheme: "https",
            host: "example.test",
            path: "/v1/search",
            queryItems: [
                URLQueryItem(name: "count", value: "10"),
                URLQueryItem(name: "language", value: "en")
            ]
        )

        let components = try XCTUnwrap(URLComponents(url: try endpoint.url(), resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "example.test")
        XCTAssertEqual(components.path, "/v1/search")
        XCTAssertEqual(queryValue("count", in: components), "10")
        XCTAssertEqual(queryValue("language", in: components), "en")
    }

    func testPercentEncodesSpacesAndReservedQueryCharacters() throws {
        let endpoint = APIEndpoint(
            scheme: "https",
            host: "example.test",
            path: "/v1/search",
            queryItems: [
                URLQueryItem(name: "name", value: "Los Angeles"),
                URLQueryItem(name: "filter", value: "a&b=c")
            ]
        )

        let url = try endpoint.url()
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertEqual(queryValue("name", in: components), "Los Angeles")
        XCTAssertEqual(queryValue("filter", in: components), "a&b=c")
        XCTAssertTrue(url.absoluteString.contains("Los%20Angeles"))
        XCTAssertTrue(url.absoluteString.contains("a%26b%3Dc") || url.absoluteString.contains("filter=a%26b%3Dc"))
    }

    private func queryValue(_ name: String, in components: URLComponents) -> String? {
        components.queryItems?.first(where: { $0.name == name })?.value
    }
}
